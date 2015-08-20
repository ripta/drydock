
module Drydock
  class Project

    DEFAULT_OPTIONS = {
      auto_remove: true,
      cache: nil,
      event_handler: false,
      logs: false
    }

    def initialize(opts = {})
      @chain   = nil
      @plugins = {}

      @serial = 0

      @opts = DEFAULT_OPTIONS.clone
      opts.each_pair { |key, value| set(key, value) }

      event_handler = opts.fetch(:event_handler, nil)
      @stream_monitor = event_handler ? StreamMonitor.new(event_handler) : nil
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
          "##{chain.size + 1} - download_once(#{source_url.inspect}, " +
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

    def from(repo, tag = 'latest')
      raise InvalidInstructionError, '`from` must only be called once per project' if chain
      Drydock.logger.info("#0 - from(#{repo.inspect}, #{tag.inspect})")
      @chain = PhaseChain.new(repo, tag)
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

    def run(cmd, opts = {}, &blk)
      raise InvalidInstructionError, '`run` cannot be called before `from`' unless chain

      Drydock.logger.info("##{chain.size + 1} - run #{cmd.inspect}")
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
      opts.fetch(:cache) { Caches::NoCache.new }
    end

  end
end
