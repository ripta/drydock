
require_relative 'base'

module Drydock
  module Plugins
    class Rubygems < Base

      def add_source(uri)
        project.run("gem sources --add #{uri}")
      end

      def install(pkg, opts = {})
        timeout = opts.delete(:timeout) || 120
        flags   = CliFlags.new(opts)
        project.run("gem install #{pkg} #{flags}", timeout: timeout)
      end

      def remove_source(uri)
        project.run("gem sources --remove #{uri}")
      end

      def update_system(opts = {})
        timeout = opts.delete(:timeout) || 300
        flags   = CliFlags.new(opts)
        project.run("gem update --system #{flags}", timeout: timeout)
      end

    end
  end
end
