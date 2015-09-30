
require_relative 'package_manager'

module Drydock
  module Plugins
    class APK < PackageManager

      def add(*pkgs)
        opts = pkgs.last.is_a?(Hash) ? pkgs.pop : {}
        project.run "apk add #{pkgs.join(' ')}", opts
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

      def upgrade
        project.run "apk upgrade"
      end

    end
  end
end
