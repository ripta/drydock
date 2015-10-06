
module Drydock
  class Project

    DEFAULT_OPTIONS = {
      auto_remove: true,
      author: nil,
      cache: nil,
      event_handler: false,
      ignorefile: '.dockerignore'
    }

    # Create a new project. **Do not use directly.**
    #
    # @api private
    # @param [Hash] build_opts Build-time options
    # @option build_opts [Boolean] :auto_remove Whether intermediate images
    #   created during the build of this project should be automatically removed.
    # @option build_opts [String] :author The default author field when an
    #   author is not provided explicitly with {#author}.
    # @option build_opts [ObjectCaches::Base] :cache An object cache manager.
    # @option build_opts [#call] :event_handler A handler that responds to a
    #   `#call` message with four arguments: `[event, is_new, serial_no, event_type]`
    #   most useful to override logging or 
    # @option build_opts [PhaseChain] :chain A phase chain manager.
    # @option build_opts [String] :ignorefile The name of the ignore-file to load.
    def initialize(build_opts = {})
      @chain   = build_opts.key?(:chain) && build_opts.delete(:chain).derive
      @plugins = {}

      @run_path = []
      @serial  = 0

      @build_opts = DEFAULT_OPTIONS.clone
      build_opts.each_pair { |key, value| set(key, value) }

      @stream_monitor = build_opts[:event_handler] ? StreamMonitor.new(build_opts[:event_handler]) : nil
    end

    # Set the author for commits. This is not an instruction, per se, and only
    # takes into effect after instructions that cause a commit.
    #
    # This instruction affects **all instructions after it**, but nothing before it.
    #
    # At least one of `name` or `email` must be given. If one is provided, the
    # other is optional.
    #
    # If no author instruction is provided, the author field is left blank by default.
    #
    # @param [String] name The name of the author or maintainer of the image.
    # @param [String] email The email of the author or maintainer.
    # @raise [InvalidInstructionArgumentError] when neither name nor email is provided
    def author(name: nil, email: nil)
      if (name.nil? || name.empty?) && (email.nil? || name.empty?)
        raise InvalidInstructionArgumentError, 'at least one of `name:` or `email:` must be provided'
      end

      value = email ? "#{name} <#{email}>" : name.to_s
      set :author, value
    end

    # Retrieve the current build ID for this project. If no image has been built,
    # returns the string '0'.
    def build_id
      chain ? chain.serial : '0'
    end

    # Change directories for operations that require a directory.
    #
    # @param [String] path The path to change directories to.
    # @yield block containing instructions to run inside the new directory
    def cd(path = '/', &blk)
      @run_path << path
      blk.call
    ensure
      @run_path.pop
    end

    # Set the command that is automatically executed by default when the image
    # is run through the `docker run` command.
    #
    # {#cmd} corresponds to the `CMD` Dockerfile instruction. This instruction
    # does **not** run the command, but rather provides the default command to
    # be run when the image is run without specifying a command.
    #
    # As with the `CMD` Dockerfile instruction, the {#cmd} instruction has three
    # forms:
    #
    # * `['executable', 'param1', 'param2', '...']`, which would run the
    #   executable directly when the image is run;
    # * `['param1', 'param2', '...']`, which would pass the parameters to the
    #   executable provided in the {#entrypoint} instruction; or
    # * `'executable param1 param2'`, which would run the executable inside
    #   a subshell.
    #
    # The first two forms are preferred over the last one.
    #
    # @param [String, Array<String>] command The command set to run. When a
    #   `String` is provided, the command is run inside a shell (`/bin/sh`).
    #   When an `Array` is given, the command is run as-is given.
    def cmd(command)
      requires_from!(:cmd)
      log_step('cmd', command)

      unless command.is_a?(Array)
        command = ['/bin/sh', '-c', command.to_s]
      end

      chain.run("# CMD #{command.inspect}", command: command)
      self
    end

    # Copies files from `source_path` on the the build machine, into `target_path`
    # in the container. This instruction automatically commits the result.
    #
    # The `copy` instruction always respects the `ignorefile`.
    #
    # When `no_cache` is `true` (also see parameter explanation below), then any
    # instruction after {#copy} will also be rebuilt *every time*.
    #
    # @param [String] source_path The source path on the build machine (where
    #   `drydock` is running) from which to copy files.
    # @param [String] target_path The target path inside the image to which to
    #   copy the files. This path **must already exist** before copying begins.
    # @param [Integer, Boolean] chmod When `false` (the default), the original file
    #   mode from its source file is kept when copying into the container. Otherwise,
    #   the mode provided (in integer octal form) will be used to override *all*
    #   file and directory modes.
    # @param [Boolean] no_cache When `false` (the default), the hash digest of the
    #   source path—taking into account all its files, directories, and contents—is
    #   used as the cache key. When `true`, the image is rebuilt *every* time.
    # @param [Boolean] recursive When `true`, then `source_path` is expected to be
    #   a directory, at which point all its contents would be recursively searched.
    #   When `false`, then `source_path` is expected to be a file.
    #
    # @raise [InvalidInstructionError] when the `source_path` does not exist
    # @raise [InvalidInstructionError] when the `source_path` is an empty directory
    #   with nothing to copy
    # @raise [InvalidInstructionError] when the `target_path` does not exist in the
    #   container
    # @raise [InvalidInstructionError] when the `target_path` exists in the container,
    #   but is not actually a directory
    def copy(source_path, target_path, chmod: false, no_cache: false, recursive: true)
      requires_from!(:copy)
      log_step('copy', source_path, target_path, chmod: (chmod ? sprintf('%o', chmod) : false))

      if source_path.start_with?('/')
        Drydock.logger.warn("#{source_path.inspect} is an absolute path; we recommend relative paths")
      end

      raise InvalidInstructionError, "#{source_path} does not exist" unless File.exist?(source_path)

      source_files = if File.directory?(source_path)
        FileManager.find(source_path, ignorefile, prepend_path: true, recursive: recursive)
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

        # TODO(rpasay): cannot autocreate the target, because `container` here is already dead
        unless target_stat
          raise InvalidInstructionError, "Target path #{target_path.inspect} does not exist"
        end

        unless target_stat.directory?
          Drydock.logger.debug(target_stat)
          raise InvalidInstructionError, "Target path #{target_path.inspect} exists, but is not a directory in the container"
        end

        container.archive_put(target_path) do |output|
          buffer.rewind
          output.write(buffer.read)
        end
      end

      self
    end

    # Destroy the images and containers created, and attempt to return the docker
    # state as it was before the project.
    #
    # @api private
    def destroy!(force: false)
      chain.destroy!(force: force) if chain
      finalize!(force: force)
    end

    # Meta instruction to signal to the builder that the build is done.
    #
    # @api private
    def done!
      throw :done
    end

    # Download (and cache) a file from `source_url`, and copy it into the
    # `target_path` in the container with a specific `chmod` (defaults to 0644).
    #
    # The cache currently cannot be disabled.
    def download_once(source_url, target_path, chmod: 0644)
      requires_from!(:download_once)

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
      chain.run("# DOWNLOAD #{source_url} #{target_path}") do |container|
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

    # **This instruction is *optional*, but if specified, must appear at the
    # beginning of the file.** 
    #
    # This instruction is used to restrict the version of `drydock` required to
    # run the `Drydockfile`. When not specified, any version of `drydock` is
    # allowed to run the file.
    #
    # The version specifier understands any bundler-compatible (and therefore
    # [gem-compatible](http://guides.rubygems.org/patterns/#semantic-versioning))
    # version specification; it even understands the twiddle-waka (`~>`) operator.
    #
    # @example
    #   drydock '~> 0.5'
    # @param [String] version The version specification to use.
    def drydock(version = '>= 0')
      raise InvalidInstructionError, '`drydock` must be called before `from`' if chain
      log_step('drydock', version)
      
      requirement = Gem::Requirement.create(version)
      current     = Gem::Version.create(Drydock.version)

      unless requirement.satisfied_by?(current)
        raise InsufficientVersionError, "build requires #{version.inspect}, but you're on #{Drydock.version.inspect}"
      end

      self
    end

    # Set an environment variable, which will be persisted in future images
    # (unless it is specifically overwritten) and derived projects.
    # 
    # Subsequent commands can refer to the environment variable by preceeding
    # the variable with a `$` sign, e.g.:
    #
    # ```
    #   env 'APP_ROOT', '/app'
    #   mkdir '$APP_ROOT'
    #   run ['some-command', '--install-into=$APP_ROOT']
    # ```
    #
    # Multiple calls to this instruction will build on top of one another.
    # That is, after the following two instructions:
    # 
    # ```
    #   env 'APP_ROOT',   '/app'
    #   env 'BUILD_ROOT', '/build'
    # ```
    #
    # the resulting image will have both `APP_ROOT` and `BUILD_ROOT` set. Later
    # instructions overwrites previous instructions of the same name:
    #
    # ```
    #   # 1
    #   env 'APP_ROOT', '/app'
    #   # 2
    #   env 'APP_ROOT', '/home/jdoe/app'
    #   # 3
    # ```
    #
    # At `#1`, `APP_ROOT` is not set (assuming no other instruction comes before
    # it). At `#2`, `APP_ROOT` is set to '/app'. At `#3`, `APP_ROOT` is set to
    # `/home/jdoe/app`, and its previous value is no longer available.
    #
    # Note that the environment variable is not evaluated in ruby; in fact, the
    # `$` sign should be passed as-is to the instruction. As with shell
    # programming, the variable name should **not** be preceeded by the `$`
    # sign when declared, but **must be** when referenced.
    #
    # @param [String] name The name of the environment variable. By convention,
    #   the name should be uppercased and underscored. The name should **not**
    #   be preceeded by a `$` sign in this context.
    # @param [String] value The value of the variable. No extra quoting should be
    #   necessary here.
    def env(name, value)
      requires_from!(:env)
      log_step('env', name, value)
      chain.run("# SET ENV #{name}", env: ["#{name}=#{value}"])
      self
    end

    # Set multiple environment variables at once. The values will be persisted in
    # future images and derived projects, unless specifically overwritten.
    #
    # The following instruction:
    #
    # ```
    #   envs APP_ROOT: '/app', BUILD_ROOT: '/tmp/build'
    # ```
    #
    # is equivalent to the more verbose:
    #
    # ```
    #   env 'APP_ROOT', '/app'
    #   env 'BUILD_ROOT', '/tmp/build'
    # ```
    #
    # When the same key appears more than once in the same {#envs} instruction,
    # the same rules for ruby hashes are used, which most likely (but not guaranteed
    # between ruby version) means the last value set is used.
    #
    # See also notes for {#env}.
    #
    # @param [Hash, #map] pairs A hash-like enumerable, where `#map` yields exactly
    #   two elements. See {#env} for any restrictions of the name (key) and value.
    def envs(pairs)
      requires_from!(:envs)
      log_step('envs', pairs)

      values = pairs.map { |name, value| "#{name}=#{value}" }
      chain.run("# SET ENVS #{pairs.inspect}", env: values)
      self
    end

    # Expose one or more ports. The values will be persisted in future images
    #
    # When `ports` is specified, the format must be: ##/type where ## is the port
    # number and type is either tcp or udp. For example, "80/tcp", "53/udp".
    #
    # Otherwise, when the `tcp` or `udp` options are specified, only the port
    # numbers are required.
    #
    # @example Different ways of exposing port 53 UDP and ports 80 and 443 TCP:
    #   expose '53/udp', '80/tcp', '443/tcp'
    #   expose udp: 53, tcp: [80, 443]
    # @param [Array<String>] ports An array of strings of port specifications.
    #   Each port specification must look like `#/type`, where `#` is the port
    #   number, and `type` is either `udp` or `tcp`.
    # @param [Integer, Array<Integer>] tcp A TCP port number to open, or an array
    #   of TCP port numbers to open.
    # @param [Integer, Array<Integer>] udp A UDP port number to open, or an array
    #   of UDP port numbers to open.
    def expose(*ports, tcp: [], udp: [])
      requires_from!(:expose)

      Array(tcp).flatten.each { |p| ports << "#{p}/tcp" }
      Array(udp).flatten.each { |p| ports << "#{p}/udp" }

      log_step('expose', *ports)

      chain.run("# SET PORTS #{ports.inspect}", expose: ports)
    end

    # Build on top of the `from` image. **This must be the first instruction of
    # the project,** although non-instructions may appear before this.
    #
    # If the `drydock` instruction is provided, `from` should come after it.
    # 
    # @param [#to_s] repo The name of the repository, which may be any valid docker
    #   repository name, and may optionally include the registry address, e.g.,
    #   `johndoe/thing` or `quay.io/jane/app`. The name *must not* contain the tag name.
    # @param [#to_s] tag The tag to use.
    def from(repo, tag = 'latest')
      raise InvalidInstructionError, '`from` must only be called once per project' if chain

      repo = repo.to_s
      tag  = tag.to_s

      log_step('from', repo, tag)
      @chain = PhaseChain.from_repo(repo, tag)
      self
    end

    # Finalize everything. This will be automatically invoked at the end of
    # the build, and should not be called manually.
    #
    # @api private
    def finalize!(force: false)
      if chain
        chain.finalize!(force: force)
      end

      if stream_monitor
        stream_monitor.kill
        stream_monitor.join
      end

      self
    end

    # Derive a new project based on the current state of the current project.
    # This instruction returns the new project that can be referred to elsewhere,
    # and most useful when combined with other inter-project instructions,
    # such as {#import}.
    #
    # For example:
    #
    # ```
    #   from 'some-base-image'
    #
    #   APP_ROOT = '/app'
    #   mkdir APP_ROOT
    #
    #   # 1:
    #   ruby_build = derive {
    #     copy 'Gemfile', APP_ROOT
    #     run 'bundle install --path vendor'
    #   }
    #
    #   # 2:
    #   js_build = derive {
    #     copy 'package.json', APP_ROOT
    #     run 'npm install'
    #   }
    #
    #   # 3:
    #   derive {
    #     import APP_ROOT, from: ruby_build
    #     import APP_ROOT, from: js_build
    #     tag 'jdoe/app', 'latest', force: true
    #   }
    # ```
    #
    # In the example above, an image is created with a new directory `/app`.
    # From there, the build branches out into three directions:
    #
    # 1. Create a new project referred to as `ruby_build`. The result of this
    #    project is an image with `/app`, a `Gemfile` in it, and a `vendor`
    #    directory containing vendored gems.
    # 2. Create a new project referred to as `js_build`. The result of this
    #    project is an image with `/app`, a `package.json` in it, and a
    #    `node_modules` directory containing vendored node.js modules.
    #    This project does **not** contain any of the contents of `ruby_build`.
    # 3. Create an anonymous project containing only the empty `/app` directory.
    #    Onto that, we'll import the contents of `/app` from `ruby_build` into
    #    this anonymous project. We'll do the same with the contents of `/app`
    #    from `js_build`. Finally, the resulting image is given the tag
    #    `jdoe/app:latest`.
    #
    # Because each derived project lives on its own and only depends on the
    # root project (whose end state is essentially the {#mkdir} instruction),
    # when `Gemfile` changes but `package.json` does not, only the first
    # derived project will be rebuilt (and following that, the third as well).
    #
    def derive(opts = {}, &blk)
      Drydock.build_on_chain(chain, opts, &blk)
    end

    # Access to the logger object.
    def logger
      Drydock.logger
    end

    # Import a `path` from a different project. The `from` option should be
    # project, usually the result of a `derive` instruction.
    #
    # @todo Add a #load method as an alternative to #import
    #   Doing so would allow importing a full container, including things from
    #   /etc, some of which may be mounted from the host.
    #
    # @todo Do not always append /. to the #archive_get calls
    #   We must check the type of `path` inside the container first.
    #
    # @todo Break this large method into smaller ones.
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

    # Retrieve the last image object built in this project.
    #
    # If no image has been built, returns `nil`.
    def last_image
      chain ? chain.last_image : nil
    end

    # Create a new directory specified by `path` in the image.
    #
    # @param [String] path The path to create inside the image.
    # @param [String] chmod The mode to which the new directory will be chmodded.
    #   If not specified, the default umask is used to determine the mode.
    def mkdir(path, chmod: nil)
      if chmod
        run "mkdir -p #{path} && chmod #{chmod} #{path}"
      else
        run "mkdir -p #{path}"
      end
    end

    # @todo on_build instructions should be deferred to the end.
    def on_build(instruction = nil, &blk)
      requires_from!(:on_build)
      log_step('on_build', instruction)
      chain.run("# ON_BUILD #{instruction}", on_build: instruction)
      self
    end

    # This instruction is used to run the command `cmd` against the current
    # project. The `opts` may be one of:
    #
    # * `no_commit`, when true, the container will not be committed to a
    #   new image. Most of the time, you want this to be false (default).
    # * `no_cache`, when true, the container will be rebuilt every time.
    #   Most of the time, you want this to be false (default). When
    #   `no_commit` is true, this option is automatically set to true.
    # * `env`, which can be used to specify a set of environment variables.
    #   For normal usage, you should use the `env` or `envs` instructions.
    # * `expose`, which can be used to specify a set of ports to expose. For
    #   normal usage, you should use the `expose` instruction instead.
    # * `on_build`, which can be used to specify low-level on-build options. For
    #   normal usage, you should use the `on_build` instruction instead.
    #
    # Additional `opts` are also recognized:
    #
    # * `author`, a string, preferably in the format of "Name <email@domain.com>".
    #   If provided, this overrides 
    # * `comment`, an arbitrary string used as a comment for the resulting image
    #
    # If `run` results in a container being created and `&blk` is provided, the
    # container will be yielded to the block.
    def run(cmd, opts = {}, &blk)
      requires_from!(:run)

      cmd = build_cmd(cmd)

      run_opts = opts.dup
      run_opts[:author]  = opts[:author]  || build_opts[:author]
      run_opts[:comment] = opts[:comment] || build_opts[:comment]

      log_step('run', cmd, run_opts)
      chain.run(cmd, run_opts, &blk)
      self
    end

    # Set project options.
    def set(key, value = nil, &blk)
      key = key.to_sym
      raise ArgumentError, "unknown option #{key.inspect}" unless build_opts.key?(key)
      raise ArgumentError, "one of value or block is required" if value.nil? && blk.nil?
      raise ArgumentError, "only one of value or block may be provided" if value && blk

      build_opts[key] = value || blk
    end

    # Tag the current state of the project with a repo and tag.
    #
    # When `force` is false (default), this instruction will raise an error if
    # the tag already exists. When true, the tag will be overwritten without
    # any warnings.
    def tag(repo, tag = 'latest', force: false)
      requires_from!(:tag)
      log_step('tag', repo, tag, force: force)

      chain.tag(repo, tag, force: force)
      self
    end

    # Use a `plugin` to issue other commands. The block form can be used to issue
    # multiple commands:
    #
    # ```
    #   with Plugins::APK do |apk|
    #     apk.update
    #   end
    # ```
    # 
    # In cases of single commands, the above is the same as:
    #
    # ```
    #   with(Plugins::APK).update
    # ```
    def with(plugin, &blk)
      (@plugins[plugin] ||= plugin.new(self)).tap do |instance|
        yield instance if block_given?
      end
    end

    private
    attr_reader :chain, :build_opts, :stream_monitor

    def build_cmd(cmd)
      if @run_path.empty?
        cmd.to_s.strip
      else
        "cd #{@run_path.join('/')} && #{cmd}".strip
      end
    end

    def cache
      build_opts[:cache] ||= ObjectCaches::NoCache.new
    end

    def ignorefile
      @ignorefile ||= IgnorefileDefinition.new(build_opts[:ignorefile])
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
