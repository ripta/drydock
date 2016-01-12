
require_relative 'base'

module Drydock
  module Plugins
    # This is the interface to operating system-level package management systems,
    # e.g., APK, APT, YUM.
    class PackageManager < Base

      def add(*pkgs)
        fail NotImplementedError, '#add must be overridde in the subclass'
      end

      def clean
        fail NotImplementedError, '#clean must be overridde in the subclass'
      end

      def remove(*pkgs)
        fail NotImplementedError, '#remove must be overridde in the subclass'
      end

      def update
        fail NotImplementedError, '#update must be overridde in the subclass'
      end

      def upgrade
        fail NotImplementedError, '#upgrade must be overridde in the subclass'
      end

    end
  end
end
