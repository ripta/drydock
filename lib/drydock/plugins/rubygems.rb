
require_relative 'base'

module Drydock
  module Plugins
    # Drydock plugin to interface with rubygems inside a container. This plugin
    # assumes that the `gem` command already exists beforehand.
    #
    # @example
    #   with Plugins::Rubygems do |gem|
    #     gem.add_source 'https://gem.someplace.corp'
    #     gem.update_system(document: false)
    #   end
    class Rubygems < Base

      # Add the `uri` as a rubygems source.
      def add_source(uri)
        project.run("gem sources --add #{uri}")
      end

      # Install one `pkg`. Options may be provided as a hash (see `CliFlags`).
      #
      # The `:timeout` option (defaults to 120) can be specified in number of
      # seconds if the package takes a long time to install.
      #
      # To install multiple packages at once, you may wish to try the `bundler` gem.
      def install(pkg, opts = {})
        timeout = opts.delete(:timeout) || 120
        flags   = CliFlags.new(opts)
        project.run("gem install #{pkg} #{flags}", timeout: timeout)
      end

      # Remove the `uri` as a rubygems source. This command succeeds even when
      # the source did not exist in the rubygems cache.
      def remove_source(uri)
        project.run("gem sources --remove #{uri}")
      end

      # Update rubygems using rubygems itself.
      #
      # The `:timeout` option (defaults to 300) can be specified in number of
      # seconds. The default should be sane enough for most purposes.
      #
      # All other options are passed as command line flags to the `update`
      # subcommand of the `gem` command.
      #
      # @example
      #   gem.update_system(rdoc: false, ri: true)
      #   # equivalent to: gem update --system --no-rdoc --ri
      def update_system(opts = {})
        timeout = opts.delete(:timeout) || 300
        flags   = CliFlags.new(opts)
        project.run("gem update --system #{flags}", timeout: timeout)
      end

    end
  end
end
