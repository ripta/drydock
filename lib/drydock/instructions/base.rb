
module Drydock
  module Instructions
    # Base class for instruction implementation.
    # **Do not use this class directly.**
    #
    # @see Project
    class Base
      extend AttrExtras.mixin
      extend Memoist

      protected

      def log_info(msg, indent: 0)
        Drydock.logger.info(indent: indent, message: msg)
      end
    end
  end
end
