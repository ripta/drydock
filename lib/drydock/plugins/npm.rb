
require_relative 'base'

module Drydock
  module Plugins
    class NPM < Base

      def install(*pkgs, opts = {})
        flags = project.cli_flags(opts)
        project.run("npm install #{flags} #{pkgs.join(' ')}")
      end

    end
  end
end
