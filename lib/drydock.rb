
require 'docker'

module Drydock

  def self.build(opts = {}, &blk)
    Project.new(opts).tap do |project|
      dryfile, dryfilename = yield
      project.instance_eval(dryfile, dryfilename)
      project.finalize!
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

  module Caches

    class Base

      def fetch(key, &blk)
        raise NotImplementedError, '#fetch must be overridden in the subclass'
      end

      def get(key, &blk)
        raise NotImplementedError, '#get must be overridden in the subclass'
      end

      def set(key, value = nil, &blk)
        raise NotImplementedError, '#set must be overridden in the subclass'
      end

    end

    class FilesystemCache < Base

      def initialize(dir = "~/.drydock")
        @dir = File.expand_path(dir)
      end

      def fetch(key, &blk)
        filename = build_path(key)

        if File.exist?(filename)
          File.read(filename)
        else
          blk.call.tap do |contents|
            File.open(filename, 'w') do |file|
              file.write contents
            end
          end
        end
      end

      def get(key, &blk)
        filename = build_path(key)
        if File.exist?(filename)
          if blk.nil?
            File.read(filename)
          else
            File.open(filename) do |file|
              blk.call file
            end
          end
        else
          nil
        end
      end

      def key?(key)
        File.exist?(build_path(key))
      end

      def set(key, value = nil, &blk)
        File.open(build_path(key), 'w') do |file|
          if blk.nil?
            file.write value
          else
            blk.call file
          end
        end

        nil
      end

      private
      attr_reader :dir

      def build_path(key)
        digest   = Digest::SHA2.hexdigest(key)
        subdir1  = digest.slice(0, 2)
        subdir2  = digest.slice(2, 2)
        filename = digest.slice(4, digest.length - 4)
        File.join(dir, subdir1, subdir2, filename)
      end

    end

    class NoCache < Base

      def fetch(key, &blk)
        blk.call
      end

      def get(key, &blk)
        nil
      end

      def key?(key)
        false
      end

      def set(key, value = nil, &blk)
        if blk
          File.open('/dev/null', 'w') do |file|
            blk.call file
          end
        end

        nil
      end

    end

  end

  module Plugins

    class Base
      attr_reader :project
      def initialize(project)
        @project = project
      end
    end

    class PackageManager < Base; end

    class APK < PackageManager

      def add(*pkgs)
        project.run "apk add #{pkgs.join(' ')}"
      end

      def clean
        project.run "rm -rf /var/cache/apk/*"
      end

      def remove(*pkgs)
        project.run "apk del #{pkgs.join(' ')}"
      end

      def update
        project.run "apk update"
      end

    end

  end

  class Project

    DEFAULT_OPTIONS = {
      auto_remove: true,
      cache: nil,
      event_handler: false,
      logs: false
    }

    def initialize(opts = {})
      @containers = []
      @images     = []
      @plugins    = {}

      @opts = DEFAULT_OPTIONS.clone
      opts.each_pair { |key, value| set(key, value) }
    end

    # def download(source_url, target_path, chmod: nil, chown: nil)
    # end

    # def download_once(source_url, target_path, chmod: nil, chown: nil)
    # end

    def from(repo, tag = 'latest')
      with_stream_monitor do
        images << Docker::Image.create(pull_opts(repo, tag))
      end
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
      with_stream_monitor do
        Docker::Container.create(build_run_opts(cmd, opts)).tap do |c|
          c.start
          c.wait
          containers << c
          images << c.commit
        end
      end
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
    attr_reader :containers, :images, :opts

    def build_run_opts(cmd, opts = {})
      {
        Cmd: ['/bin/sh', '-c', cmd],
        Tty: opts.fetch(:tty, false),
        Image: latest_image.id
      }
    end

    def cache
      opts.fetch(:cache) { Caches::NoCache.new }
    end

    def event_handler
      opts.fetch(:event_handler, nil)
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
      return nil if event_handler.nil?

      @stream_monitor = Thread.new do
        Docker::Event.stream(&event_handler)
      end
    end

    def with_stream_monitor(&blk)
      mon = stream_monitor
      mon.run if mon
      yield
    ensure
      if mon
        mon.kill
        mon.join
      end
    end

  end

end
