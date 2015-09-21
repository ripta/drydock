
module Drydock
  class Project

    DEFAULT_OPTIONS = {
      auto_remove: true,
      author: nil,
      cache: nil,
      event_handler: false,
      ignorefile: '.dockerignore',
      label: nil,
      logs: false
    }

    def initialize(opts = {})
      @chain   = opts.key?(:chain) && opts.delete(:chain).derive
      @plugins = {}

      @run_path = []
      @serial  = 0

      @opts = DEFAULT_OPTIONS.clone
      opts.each_pair { |key, value| set(key, value) }

      @stream_monitor = opts[:event_handler] ? StreamMonitor.new(opts[:event_handler]) : nil
    end

    def author(name: nil, email: nil)
      value = email ? "#{name} <#{email}>" : name.to_s
      set :author, value
    end

    def build_id
      chain ? chain.serial : 0
    end

    def cd(path, &blk)
      @run_path << path
      blk.call
    ensure
      @run_path.pop
    end

    def copy(source_path, target_path, chmod: false, no_cache: false, recursive: true)
      raise InvalidInstructionError, '`copy` cannot be called before `from`' unless chain
      log_step('copy', source_path, target_path, chmod: (chmod ? sprintf('%o', chmod) : false))

      if source_path.start_with?('/')
        Drydock.logger.warn("#{source_path.inspect} is an absolute path; we recommend relative paths")
      end

      raise InvalidInstructionError, "#{source_path} does not exist" unless File.exist?(source_path)

      source_files = if File.directory?(source_path)
        FileManager.find(source_path, ignorefile, recursive: recursive)
      else
        [source_path]
      end
      source_files.sort!

      raise InvalidInstructionError, "#{source_path} is empty or does not match a path" if source_files.empty?

      buffer = StringIO.new
      log_info("Processing #{source_files.size} files in tree")
      TarWriter.new(buffer) do |tar|
        source_files.each do |source_file|
          File.open(source_file, 'r') do |input|
            stat = input.stat
            mode = chmod || stat.mode
            tar.add_entry(source_file, mode: stat.mode, mtime: stat.mtime) do |tar_file|
              tar_file.write(input.read)
            end
          end
        end
      end

      buffer.rewind
      digest = Digest::MD5.hexdigest(buffer.read)

      log_info("Tree digest is md5:#{digest}")
      chain.run("# COPY #{source_path} #{target_path} DIGEST #{digest}", no_cache: no_cache) do |container|
        target_stat = container.archive_head(target_path)
        unless target_stat.directory?
          Drydock.logger.debug(target_stat)
          raise InvalidInstructionError, "#{target_path} exists, but is not a directory in the container"
        end

        container.archive_put(target_path) do |output|
          buffer.rewind
          output.write(buffer.read)
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

      log_step('download_once', source_url, target_path, chmod: sprintf('%o', chmod))

      # TODO(rpasay): invalidate cache when the downloaded file changes,
      # and then force rebuild
      chain.run("# DOWNLOAD #{source_url}") do |container|
        container.archive_put do |output|
          TarWriter.new(output) do |tar|
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
      log_step('env', name, value)
      chain.run("# SET ENV #{name}", env: ["#{name}=#{value}"])
      self
    end

    def expose(*ports, tcp: [], udp: [])
      requires_from!(:expose)

      Array(tcp).flatten.each { |p| ports << "#{p}/tcp" }
      Array(udp).flatten.each { |p| ports << "#{p}/udp" }

      log_step('expose', *ports)

      chain.run("# SET PORTS #{ports.inspect}", expose: ports)
    end

    def from(repo, tag = 'latest')
      raise InvalidInstructionError, '`from` must only be called once per project' if chain
      log_step('from', repo, tag)
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

    def derive(opts = {}, &blk)
      Drydock.build_on_chain(chain, opts, &blk)
    end

    def logger
      Drydock.logger
    end

    # TODO(rpasay): add a #load method as an alternative to #import, which allows
    # importing a full container, including things from /etc.
    # TODO(rpasay): do not always append /. to the #archive_get calls; must check
    # the type of `path` inside the container first.
    # TODO(rpasay): break this large method into smaller ones.
    def import(path, from: nil, force: false, spool: false)
      mkdir(path)

      requires_from!(:import)
      raise InvalidInstructionError, 'cannot `import` from `/`' if path == '/' && !force
      raise InvalidInstructionError, '`import` requires a `from:` option' if from.nil?
      log_step('import', path, from: from.last_image.id)

      total_size = 0

      if spool
        spool_file = Tempfile.new('drydock')
        log_info("Spooling to #{spool_file.path}")

        from.send(:chain).run("# EXPORT #{path}", no_commit: true) do |source_container|
          source_container.archive_get(path + "/.") do |chunk|
            spool_file.write(chunk.to_s).tap { |b| total_size += b }
          end
        end

        spool_file.rewind
        chain.run("# IMPORT #{path}", no_cache: true) do |target_container|
          target_container.archive_put(path) do |output|
            output.write(spool_file.read)
          end
        end

        spool_file.close
      else
        chain.run("# IMPORT #{path}", no_cache: true) do |target_container|
          target_container.archive_put(path) do |output|
            from.send(:chain).run("# EXPORT #{path}", no_commit: true) do |source_container|
              source_container.archive_get(path + "/.") do |chunk|
                output.write(chunk.to_s).tap { |b| total_size += b }
              end
            end
          end
        end
      end

      log_info("Imported #{Formatters.number(total_size)} bytes")
    end

    def last_image
      chain ? chain.last_image : nil
    end

    def mkdir(path)
      run "mkdir -p #{path}"
    end

    # TODO(rpasay): on_build instructions should be deferred to the end
    def on_build(instruction = nil, &blk)
      raise InvalidInstructionError, '`on_build` cannot be called before `from`' unless chain
      log_step('on_build', instruction)
      chain.run("# ON_BUILD #{instruction}", on_build: instruction)
      self
    end

    def run(cmd, opts = {}, &blk)
      raise InvalidInstructionError, '`run` cannot be called before `from`' unless chain

      cmd = build_cmd(cmd)

      log_step('run', cmd, opts)
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

    def tag(repo, tag = 'latest', force: false)
      requires_from!(:tag)
      log_step('tag', repo, tag, force: force)

      chain.tag(repo, tag, force: force)
      self
    end

    def with(plugin, &blk)
      (@plugins[plugin] ||= plugin.new(self)).tap do |instance|
        yield instance if block_given?
      end
    end

    private
    attr_reader :chain, :opts, :stream_monitor

    def build_cmd(cmd)
      if @run_path.empty?
        cmd.to_s.strip
      else
        "cd #{@run_path.join('/')} && #{cmd}".strip
      end
    end

    def cache
      opts[:cache] ||= ObjectCaches::NoCache.new
    end

    def ignorefile
      @ignorefile ||= IgnorefileDefinition.new(opts[:ignorefile])
    end

    def log_info(msg, indent: 0)
      Drydock.logger.info(indent: indent, message: msg)
    end

    def log_step(op, *args)
      opts   = args.last.is_a?(Hash) ? args.pop : {}
      optstr = opts.map { |k, v| "#{k}: #{v.inspect}" }.join(', ')

      argstr = args.map(&:inspect).join(', ')

      Drydock.logger.info("##{chain ? chain.serial : 0}: #{op}(#{argstr}#{optstr.empty? ? '' : ", #{optstr}"})")
    end

    def requires_from!(instruction)
      raise InvalidInstructionError, "`#{instruction}` cannot be called before `from`" unless chain
    end

  end
end
