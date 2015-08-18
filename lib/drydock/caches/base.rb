
module Drydock
  module Caches
    class Base

      def fetch(key, &blk)
        raise NotImplementedError, '#fetch must be overridden in the subclass'
      end

      def get(key, &blk)
        raise NotImplementedError, '#get must be overridden in the subclass'
      end

      def set(key, value = nil, &blk)
        raise NotImplementedError, '#set must be overridden in the subclass'
      end

    end
  end
end
