
module Drydock
  class PhaseChain
    extend Forwardable
    include Enumerable

    def_delegators :@chain, :<<, :at, :empty?, :last, :length, :push, :size

    def self.build_commit_opts(opts = {})
      {}.tap do |commit|
        if opts.key?(:command)
          commit['run'] = {
            Cmd: opts[:command]
          }
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
      end
    end

    def self.build_pull_opts(repo, tag = nil)
      if tag
        {fromImage: repo, tag: tag}
      else
        {fromImage: repo}
      end
    end

    def self.create_container(cfg, timeout: nil)
      timeout ||= Excon.defaults[:read_timeout]

      Docker::Container.create(cfg).tap do |c|
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

        c.start
        c.wait(timeout)
        t.join
      end
    end

    def self.from_repo(repo, tag = 'latest')
      new(Docker::Image.create(build_pull_opts(repo, tag)))
    end

    def initialize(from, parent = nil)
      @chain  = []
      @from   = from
      @parent = parent
      @children = []

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

    def destroy!
      return self if frozen?
      children.map(&:destroy!) if children
      ephemeral_containers.map(&:remove)

      map(&:destroy!)
      freeze
    end

    def each(&blk)
      @chain.each(&blk)
    end

    def ephemeral_containers
      @ephemeral_containers
    end

    def finalize!
      return self if frozen?

      children.map(&:finalize!) if children
      ephemeral_containers.map(&:remove)

      Drydock.logger.info("##{serial}: Final image ID is #{last_image.id}") unless empty?
      map(&:finalize!)
      freeze
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

      build_config = self.class.build_container_opts(src_image.id, cmd, opts)
      Drydock.logger.info(build_config.inspect)
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
          Drydock.logger.info(message: "Found cached image ID #{cached_image.id.slice(0, 12)}, but skipping due to :no_commit")
        elsif cached_image && no_cache
          Drydock.logger.info(message: "Found cached image ID #{cached_image.id.slice(0, 12)}, but skipping due to :no_cache")
        end

        container = self.class.create_container(build_config)
        yield container if block_given?

        if no_commit
          Drydock.logger.info(message: "Skipping commit phase")
          ephemeral_containers << container
        else
          if opts.key?(:command)
            Drydock.logger.info("Command override: #{opts[:command].inspect}")
          else
            src_image.refresh!
            if src_image.info && src_image.info.key?('Config')
              src_image_config = src_image.info['Config']
              opts[:command]   = src_image_config['Cmd'] if src_image_config.key?('Cmd')
            end

            Drydock.logger.info("Command retrieval: #{opts[:command].inspect}")
            Drydock.logger.info("Source image info: #{src_image.info.class} #{src_image.info.inspect}")
            Drydock.logger.info("Source image config: #{src_image.info['Config'].inspect}")
          end

          commit_config = self.class.build_commit_opts(opts)
          Drydock.logger.info(opts.inspect)
          Drydock.logger.info(commit_config.inspect)

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
