
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

    def download(source_url, target_path, chmod: nil, chown: nil)
      response = Excon.get(source_url)
      if response.status != 200
        raise OperationError, "cannot download #{source_url}, status code #{response.status}"
      end

      response.body
    end

    def download_once(source_url, target_path, chmod: 0644)
      unless cache.key?(source_url)
        cache.set(source_url) do |obj|
          chunked = Proc.new do |chunk, remaining_bytes, total_bytes|
            obj.write(chunk)
          end
          Excon.get(source_url, response_block: chunked)
        end
      end

      chain.run('# Filesystem Change Only') do |container|
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

    def run(cmd, opts = {})
      raise InvalidInstructionError, '`run` cannot be called before `from`' unless chain
      chain.run(cmd, opts)
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
