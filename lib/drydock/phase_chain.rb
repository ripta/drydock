
module Drydock
  class PhaseChain
    extend Forwardable
    include Enumerable

    def_delegators :@chain, :<<, :at, :empty?, :last, :length, :push, :size

    def self.build_commit_opts(opts = {})
      {}.tap do |commit|
        if opts.key?(:command)
          commit['run'] ||= {}
          commit['run'][:Cmd] = opts[:command]
        end

        if opts.key?(:entrypoint)
          commit['run'] ||= {}
          commit['run'][:Entrypoint] = opts[:entrypoint]
        end

        commit[:author]  = opts.fetch(:author, '')  if opts.key?(:author)
        commit[:comment] = opts.fetch(:comment, '') if opts.key?(:comment)
      end
    end

    def self.build_container_opts(image_id, cmd, opts = {})
      cmd = ['/bin/sh', '-c', cmd.to_s] unless cmd.is_a?(Array)

      ContainerConfig.from(
        Cmd: cmd,
        Tty: opts.fetch(:tty, false),
        Image: image_id
      ).tap do |cc|
        env = Array(opts[:env])
        cc[:Env].push(*env) unless env.empty?

        if opts.key?(:expose)
          cc[:ExposedPorts] ||= {}
          opts[:expose].each do |port|
            cc[:ExposedPorts][port] = {}
          end
        end

        (cc[:OnBuild] ||= []).push(opts[:on_build]) if opts.key?(:on_build)

        cc[:MetaOptions] ||= {}
        [:connect_timeout, :read_timeout].each do |key|
          cc[:MetaOptions][key] = opts[key] if opts.key?(key)
          cc[:MetaOptions][key] = opts[:timeout] if opts.key?(:timeout)
        end
      end
    end

    def self.build_pull_opts(repo, tag = nil)
      if tag
        {fromImage: "#{repo}:#{tag}"}
      else
        {fromImage: "#{repo}:latest"}
      end
    end

    # TODO(rpasay): Break this large method apart.
    def self.create_container(cfg, &blk)
      meta_options = cfg[:MetaOptions] || {}
      timeout = meta_options.fetch(:read_timeout, Excon.defaults[:read_timeout]) || 60

      Drydock.logger.debug(message: "Create container configuration: #{cfg.inspect}")
      Docker::Container.create(cfg).tap do |c|
        # The call to Container.create merely creates a container, to be
        # scheduled to run. Start a separate thread that attaches to the
        # container's streams and mirror them to the logger.
        t = Thread.new do
          begin
            c.attach(stream: true, stdout: true, stderr: true) do |stream, chunk|
              case stream
              when :stdout
                Drydock.logger.info(message: chunk, annotation: '(O)')
              when :stderr
                Drydock.logger.info(message: chunk, annotation: '(E)')
              else
                Drydock.logger.info(message: chunk, annotation: '(?)')
              end
            end
          rescue Docker::Error::TimeoutError
            Drydock.logger.warn(message: "Lost connection to stream; retrying")
            retry
          end
        end

        # TODO(rpasay): RACE CONDITION POSSIBLE - the thread above may be
        # scheduled but not run before this block gets executed, which can
        # cause a loss of log output. However, forcing `t` to be run once
        # before this point seems to cause an endless wait (ruby 2.1.5).
        # Need to dig deeper in the future.
        #
        # TODO(rpasay): More useful `blk` handling here. This method only
        # returns after the container terminates, which isn't useful when
        # you want to do stuff to it, e.g., spawn a new exec container.
        #
        # The following block starts the container, and waits for it to finish.
        # An error is raised if no exit code is returned or if the exit code
        # is non-zero.
        begin
          c.start
          blk.call(c) if blk

          results = c.wait(timeout)

          unless results
            fail InvalidCommandExecutionError,
              container: c.id,
              message: "Container did not return anything (API BUG?)"
          end

          unless results.key?('StatusCode')
            fail InvalidCommandExecutionError,
              container: c.id,
              message: "Container did not return a status code (API BUG?)"
          end

          unless results['StatusCode'] == 0
            fail InvalidCommandExecutionError,
              container: c.id,
              message: "Container exited with code #{results['StatusCode']}"
          end
        rescue
          # on error, kill the streaming logs and reraise the exception
          t.kill
          raise
        ensure
          # always rejoin the thread
          t.join
        end
      end
    end

    def self.from_repo(repo, tag = 'latest')
      new(Docker::Image.create(build_pull_opts(repo, tag)))
    end

    def self.propagate_config!(src_image, config_name, opts, opt_key)
      if opts.key?(opt_key)
        Drydock.logger.info("Command override: #{opts[opt_key].inspect}")
      else
        src_image.refresh!
        if src_image.info && src_image.info.key?('Config')
          src_image_config = src_image.info['Config']
          opts[opt_key]    = src_image_config[config_name] if src_image_config.key?(config_name)
        end

        Drydock.logger.debug(message: "Command retrieval: #{opts[opt_key].inspect}")
        Drydock.logger.debug(message: "Source image info: #{src_image.info.class} #{src_image.info.inspect}")
        Drydock.logger.debug(message: "Source image config: #{src_image.info['Config'].inspect}")
      end
    end

    def initialize(from, parent = nil)
      @chain  = []
      @from   = from
      @parent = parent
      @children = []

      @finalized = false

      @ephemeral_containers = []

      if parent
        parent.children << self
      end
    end

    def children
      @children
    end

    def containers
      map(&:build_container)
    end

    def depth
      @parent ? @parent.depth + 1 : 1
    end

    def derive
      self.class.new(last_image, self)
    end

    def destroy!(force: false)
      return self if frozen?

      finalize!
      children.reverse_each { |c| c.destroy!(force: force) } if children
      reverse_each { |p| p.destroy!(force: force) }

      freeze
    end

    def each(&blk)
      @chain.each(&blk)
    end

    def ephemeral_containers
      @ephemeral_containers
    end

    def finalize!(force: false)
      return self if finalized?

      children.reverse_each { |c| c.finalize!(force: force) } if children
      ephemeral_containers.reverse_each { |c| c.remove(force: force) }

      Drydock.logger.info("##{serial}: Final image ID is #{last_image.id}") unless empty?
      reverse_each { |p| p.finalize!(force: force) }

      @finalized = true
      self
    end

    def finalized?
      @finalized
    end

    def images
      [root_image] + map(&:result_image)
    end

    def last_image
      @chain.last ? @chain.last.result_image : nil
    end

    def root_image
      @from
    end

    def run(cmd, opts = {}, &blk)
      src_image = last ? last.result_image : @from
      no_commit = opts.fetch(:no_commit, false)

      no_cache = opts.fetch(:no_cache, false)
      no_cache = true if no_commit

      Drydock.logger.debug(message: "Source image: #{src_image.inspect}")
      build_config = self.class.build_container_opts(src_image.id, cmd, opts)
      cached_image = ImageRepository.find_by_config(build_config)

      if cached_image && !no_cache
        Drydock.logger.info(message: "Using cached image ID #{cached_image.id.slice(0, 12)}")

        if no_commit
          Drydock.logger.info(message: "Skipping commit phase")
        else
          self << Phase.from(
            source_image: src_image,
            result_image: cached_image
          )
        end
      else
        if cached_image && no_commit
          Drydock.logger.info(
            message: "Found cached image ID #{cached_image.id.slice(0, 12)}, but skipping due to :no_commit"
          )
        elsif cached_image && no_cache
          Drydock.logger.info(
            message: "Found cached image ID #{cached_image.id.slice(0, 12)}, but skipping due to :no_cache"
          )
        end

        container = self.class.create_container(build_config)
        yield container if block_given?

        if no_commit
          Drydock.logger.info(message: "Skipping commit phase")
          ephemeral_containers << container
        else
          self.class.propagate_config!(src_image, 'Cmd',        opts, :command)
          self.class.propagate_config!(src_image, 'Entrypoint', opts, :entrypoint)
          commit_config = self.class.build_commit_opts(opts)

          result = container.commit(commit_config)
          Drydock.logger.info(message: "Committed image ID #{result.id.slice(0, 12)}")

          self << Phase.from(
            source_image:    src_image,
            build_container: container,
            result_image:    result
          )
        end
      end

      self
    end

    def serial
      @parent ? "#{@parent.serial}.#{@parent.children.index(self) + 1}.#{size + 1}" : "#{size + 1}"
    end

    def tag(repo, tag = 'latest', force: false)
      last_image.tag(repo: repo, tag: tag, force: force)
    end

  end
end
