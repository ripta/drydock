
module Drydock
  class PhaseChain
    extend Forwardable
    include Enumerable

    def_delegators :@chain, :<<, :at, :last, :length, :push, :size

    def self.build_container_opts(image_id, cmd, opts = {})
      ContainerConfig.from(
        Cmd: ['/bin/sh', '-c', cmd],
        Tty: opts.fetch(:tty, false),
        Image: image_id
      )
    end

    def self.build_pull_opts(repo, tag = nil)
      if tag
        {fromImage: repo, tag: tag}
      else
        {fromImage: repo}
      end
    end

    def self.create_container(cfg)
      Docker::Container.create(cfg).tap do |c|
        c.start
        c.wait
        c.streaming_logs(stdout: true, stderr: true) do |stream, chunk|
          case stream
          when :stdout
            Drydock.logger.info "  (O) #{chunk.chomp}"
          when :stderr
            Drydock.logger.info "  (E) #{chunk.chomp}"
          else
            Drydock.logger.info "  (?/#{stream.inspect}) #{chunk.chomp}"
          end
        end
      end
    end

    def initialize(repo, tag = 'latest')
      @chain = []
      @from  = Docker::Image.create(self.class.build_pull_opts(repo, tag))
    end

    def containers
      map(&:build_container)
    end

    def finalize!
      return self if frozen?

      map(&:finalize!)
      freeze
    end

    def each(&blk)
      @chain.each(&blk)
    end

    def images
      return [] if empty?
      [root_image] + map(&:result_image)
    end

    def root_image
      @from
    end

    def run(cmd, opts = {}, &blk)
      src_image = last ? last.result_image : @from

      build_config = self.class.build_container_opts(src_image.id, cmd, opts)
      cached_image = ImageRepository.find_by_config(build_config)

      if cached_image
        Drydock.logger.info "    { Using cached image ID #{cached_image.id.slice(0, 12)} }"
        self << Phase.from(
          source_image: src_image,
          result_image: cached_image
        )
      else
        container = self.class.create_container(build_config)
        yield container if block_given?
        self << Phase.from(
          source_image:    src_image,
          build_container: container,
          result_image:    container.commit
        )
      end

      self
    end

  end
end
