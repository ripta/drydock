
require_relative 'base'

module Drydock
  module Plugins
    class PackageManager < Base

      def add(*pkgs)
        raise NotImplementedError, '#add must be overridde in the subclass'
      end

      def clean
        raise NotImplementedError, '#clean must be overridde in the subclass'
      end

      def remove(*pkgs)
        raise NotImplementedError, '#remove must be overridde in the subclass'
      end

      def update
        raise NotImplementedError, '#update must be overridde in the subclass'
      end

    end
  end
end
