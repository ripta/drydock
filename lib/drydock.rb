
require 'docker'

module Drydock

  def self.build(opts = {}, &blk)
    Project.new(opts).tap do |project|
      if blk
        yield project
        project.finalize!
      end
    end
  end

  def self.from(repo, opts = {}, &blk)
    opts = opts.clone
    tag  = opts.delete(:tag, 'latest')

    build(opts).tap do |project|
      project.from(repo, tag)
      yield project
    end
  end

  def self.using(project)
    raise NotImplementedError, "TODO(rpasay)"
  end

  class Project

    attr_reader :repo, :tag

    DEFAULT_OPTIONS = {
      auto_remove: true,
      event_stream: false,
      logs: false
    }

    def initialize(opts = {})
      @containers = []
      @images     = []

      @opts = DEFAULT_OPTIONS.clone
      opts.each_pair { |key, value| set(key, value) }
    end

    def from(repo, tag = 'latest')
      images << Docker::Image.create(pull_opts(repo, tag))
      self
    end

    def finalize!
      containers.each(&:remove)
      containers.clear
      self
    end

    def latest_image
      images.last
    end

    def root_image
      images.first
    end

    def run(cmd, opts = {})
      stream_monitor.run
      Docker::Container.create(build_run_opts(cmd, opts)).tap do |c|
        c.start
        c.wait
        containers << c
        images << c.commit
      end
    ensure
      stream_monitor.kill
    end

    def set(key, value = nil, &blk)
      key = key.to_sym
      raise ArgumentError, "unknown option #{key.inspect}" unless opts.key?(key)
      raise ArgumentError, "one of value or block is required" if value.nil? && blk.nil?
      raise ArgumentError, "only one of value or block may be provided" if value && blk

      opts[key] = value || blk
    end

    private
    attr_reader :containers, :images, :opts

    def build_run_opts(cmd, opts = {})
      {
        Cmd: ['/bin/sh', '-c', cmd],
        Tty: opts.fetch(:tty, false),
        Image: latest_image.id
      }
    end

    def pull_opts(repo, tag = nil)
      if tag
        {fromImage: repo, tag: tag}
      else
        {fromImage: repo}
      end
    end

    def stream_monitor
      return @stream_monitor if @stream_monitor && @stream_monitor.alive?

      @stream_monitor = Thread.new do
        Docker::Event.stream do |event|
          puts event
        end
      end
    end

  end

end
