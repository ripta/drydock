
require_relative 'base'

module Drydock
  module ObjectCaches
    class NoCache < Base

      def clear
        true
      end

      def fetch(key, &blk)
        blk.call
      end

      def get(key, &blk)
        nil
      end

      def key?(key)
        false
      end

      def set(key, value = nil, &blk)
        if blk
          File.open('/dev/null', 'w') do |file|
            blk.call file
          end
        else
          # :noop:
        end

        nil
      end

    end
  end
end
