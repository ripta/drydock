
module Drydock
  class Project

    DEFAULT_OPTIONS = {
      auto_remove: true,
      cache: nil,
      event_handler: false,
      logs: false
    }

    def initialize(opts = {})
      @chain   = opts.key?(:chain) && opts.delete(:chain).derive
      @plugins = {}

      @serial = 0

      @opts = DEFAULT_OPTIONS.clone
      opts.each_pair { |key, value| set(key, value) }

      @stream_monitor = opts[:event_handler] ? StreamMonitor.new(opts[:event_handler]) : nil
    end

    def copy(source_path, target_path, chmod: false, recursive: true)
      raise InvalidInstructionError, '`copy` cannot be called before `from`' unless chain

      Drydock.logger.info(
          "##{chain.serial}: copy(#{source_path.inspect}, " +
          "#{target_path.inspect}, chmod: #{chmod ? sprintf('%o', chmod) : false})"
      )

      if source_path.starts_with?('/')
        Drydock.logger.warn("#{source_path.inspect} is an absolute path; we recommend relative paths")
      end

      raise InvalidInstructionError, "#{source_path} does not exist" unless File.exist?(source_path)

      recurse_glob = recursive ? "**/*" : "*"
      source_files = File.dir?(source_path) ? Dir.glob("#{source_path}/#{recurse_glob}") : [source_path]
      raise InvalidInstructionError, "#{source_path} is empty or does not match a path" if source_files.empty?

      target_stat = container.archive_head(target_path)
      raise InvalidInstructionError, "#{target_path} must be a directory in the container" unless target_stat.directory?

      chain.run("# COPY #{source_path} #{target_path}") do |container|
        container.archive_put(target_path) do |output|

          Gem::Package::TarWriter.new(output) do |tar|
            source_files.each do |source_file|
              File.open(source_file, 'r') do |input|
                mode = chmod || input.stat.mode
                tar.add_file(source_file, mode) do |tar_file|
                  tar_file.write(input.read)
                end
              end
            end
          end

        end
      end

      self
    end

    def done!
      throw :done
    end

    def download_once(source_url, target_path, chmod: 0644)
      raise InvalidInstructionError, '`run` cannot be called before `from`' unless chain

      unless cache.key?(source_url)
        cache.set(source_url) do |obj|
          chunked = Proc.new do |chunk, remaining_bytes, total_bytes|
            obj.write(chunk)
          end
          Excon.get(source_url, response_block: chunked)
        end
      end

      # TODO(rpasay): invalidate cache when the downloaded file changes,
      # and then force rebuild
      Drydock.logger.info(
          "##{chain.serial}: download_once(#{source_url.inspect}, " +
          "#{target_path.inspect}, chmod: #{sprintf('%o', chmod)})"
      )
      chain.run("# DOWNLOAD #{source_url}") do |container|
        container.archive_put do |output|
          Gem::Package::TarWriter.new(output) do |tar|
            cache.get(source_url) do |input|
              tar.add_file(target_path, chmod) do |tar_file|
                tar_file.write(input.read)
              end
            end
          end
        end
      end

      self
    end

    def env(name, value)
      raise InvalidInstructionError, '`env` cannot be called before `from`' unless chain
      Drydock.logger.info("##{chain.serial}: env(#{name.inspect}, #{value.inspect})")
      chain.run("# SET ENV #{name}", env: ["#{name}=#{value}"])
      self
    end

    def from(repo, tag = 'latest')
      raise InvalidInstructionError, '`from` must only be called once per project' if chain
      Drydock.logger.info("#0: from(#{repo.inspect}, #{tag.inspect})")
      @chain = PhaseChain.from_repo(repo, tag)
      self
    end

    def finalize!
      if chain
        chain.finalize!
      end

      if stream_monitor
        stream_monitor.kill
        stream_monitor.join
      end

      self
    end

    def derive(&blk)
      Drydock.build_on_chain(chain, &blk)
    end

    def mkdir(path)
      run "mkdir -p #{path}"
    end

    def run(cmd, opts = {}, &blk)
      raise InvalidInstructionError, '`run` cannot be called before `from`' unless chain

      Drydock.logger.info("##{chain.serial}: run #{cmd.inspect}")
      Drydock.logger.info("  opts = #{opts.inspect}") unless opts.empty?
      chain.run(cmd, opts, &blk)
      self
    end

    def set(key, value = nil, &blk)
      key = key.to_sym
      raise ArgumentError, "unknown option #{key.inspect}" unless opts.key?(key)
      raise ArgumentError, "one of value or block is required" if value.nil? && blk.nil?
      raise ArgumentError, "only one of value or block may be provided" if value && blk

      opts[key] = value || blk
    end

    def with(plugin, &blk)
      (@plugins[plugin] ||= plugin.new(self)).tap do |instance|
        yield instance
      end
    end

    private
    attr_reader :chain, :opts, :stream_monitor

    def cache
      opts[:cache] ||= Caches::NoCache.new
    end

  end
end
