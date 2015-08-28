
require_relative 'base'

module Drydock
  module ObjectCaches
    class FilesystemCache < Base

      def initialize(dir = "~/.drydock")
        @dir = File.expand_path(File.join(dir.to_s, 'cache'))
        FileUtils.mkdir_p(@dir)
      end

      def fetch(key, &blk)
        filename = build_path(key)

        if File.exist?(filename)
          File.read(filename)
        else
          dirname = File.dirname(filename)
          FileUtils.mkdir_p(dirname)

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
        filename = build_path(key)
        dirname = File.dirname(filename)
        FileUtils.mkdir_p(dirname)

        File.open(filename, 'w') do |file|
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
  end
end
