
require_relative 'package_manager'

module Drydock
  module Plugins
    # Drydock plugin to the APK package manager included in Alpine Linux.
    # This plugin assumes that the command `apk` already exists.
    class APK < PackageManager

      # Install one or more packages in one go. An optional options hash may
      # be provided, although the hash is passed on to the RUN instruction
      # instead of to the `apk` command.
      def add(*pkgs)
        opts = pkgs.last.is_a?(Hash) ? pkgs.pop : {}
        project.run "apk add #{pkgs.join(' ')}", opts
      end

      # Clean the APK cache. This should be called after packages are installed.
      # If you need to install more packages after calling this, you'll need to
      # call `#update` first.
      def clean
        project.run 'rm -rf /var/cache/apk/*'
      end

      # Uninstall one or more packages in one go. An optional options hash may
      # be provided, although the hash is passed on to the RUN instruction
      # instead of to the `apk` command.
      def remove(*pkgs)
        opts = pkgs.last.is_a?(Hash) ? pkgs.pop : {}
        project.run "apk del #{pkgs.join(' ')}", opts
      end

      # Updates the apk index.
      def update
        project.run "apk update"
      end

      # Upgrades all outdated packages currently installed.
      def upgrade
        project.run "apk upgrade"
      end

    end
  end
end
