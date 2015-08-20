
require_relative 'base'

module Drydock
  module Plugins
    class Rubygems < Base

      def add_source(uri)
        project.run("gem sources --add #{uri}")
      end

      def install(pkg, opts = {})
        flags = CliFlags.new(opts)
        project.run("gem install #{pkg} #{flags}")
      end

      def remove_source(uri)
        project.run("gem sources --remove #{uri}")
      end

      def update_system(opts = {})
        flags = CliFlags.new(opts)
        project.run("gem update --system #{flags}")
      end

    end
  end
end
