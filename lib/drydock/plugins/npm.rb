
require_relative 'base'

module Drydock
  module Plugins
    # Drydock plugin to interface with `npm` inside a container. This plugin
    # assumes that the `npm` command already exists beforehand.
    class NPM < Base

      # Install one or more packages, each provided as a string.
      #
      # Flags may be provided as an options hash at the end.
      #
      # @example
      #   npm.install 'bower', 'gulp', global: true
      #   # equivalent to: npm install --global bower gulp
      def install(*pkgs)
        opts = pkgs.last.is_a?(Hash) ? pkgs.pop : {}
        flags = CliFlags.new(opts)
        project.run("npm install #{flags}#{pkgs.join(' ')}")
      end

    end
  end
end
