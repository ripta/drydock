
require_relative 'package_manager'

module Drydock
  module Plugins
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
end
