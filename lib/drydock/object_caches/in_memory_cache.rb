
require_relative 'base'

module Drydock
  module ObjectCaches
    class InMemoryCache < Base

      def initialize
        @mem = {}
      end

      def clear
        @mem.clear
        true
      end

      def fetch(key, &blk)
        @mem.fetch(key, &blk)
      end

      def get(key, &blk)
        if @mem.key?(key)
          if blk.nil?
            @mem[key]
          else
            blk.call(StringIO.new(@mem[key]))
          end
        else
          nil
        end
      end

      def key?(key)
        @mem.key?(key)
      end

      def set(key, value = nil, &blk)
        if blk
          buffer = StringIO.new
          blk.call buffer
          buffer.rewind
          @mem[key] = buffer.string
        else
          @mem[key] = value
        end

        nil
      end

    end
  end
end
