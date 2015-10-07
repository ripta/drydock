
module Drydock
  module ObjectCaches
    class Base

      def clear
        fail NotImplementedError, '#clear must be overridden in the subclass'
      end

      def fetch(key, &blk)
        fail NotImplementedError, '#fetch must be overridden in the subclass'
      end

      def get(key, &blk)
        fail NotImplementedError, '#get must be overridden in the subclass'
      end

      def set(key, value = nil, &blk)
        fail NotImplementedError, '#set must be overridden in the subclass'
      end

    end
  end
end
