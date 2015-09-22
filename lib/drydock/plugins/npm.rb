
require_relative 'base'

module Drydock
  module Plugins
    class NPM < Base

      def install(*pkgs)
        opts = pkgs.last.is_a?(Hash) ? pkgs.pop : {}
        flags = CliFlags.new(opts)
        project.run("npm install #{flags}#{pkgs.join(' ')}")
      end

    end
  end
end
