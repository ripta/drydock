
module Drydock
  # Convert a hash of flags to a POSIX-y string.
  #
  # @example
  #   1> CliFlags.new(v: true, size: 5).to_s
  #   => "-v --size 5"
  class CliFlags

    def initialize(flags = {})
      @flags = flags
    end

    def to_s
      return '' if flags.nil? || flags.empty?

      buffer = StringIO.new
      flags.each_pair do |k, v|
        buffer << process_flag(k, v)
      end

      buffer.string
    end

    private

    attr_reader :flags

    def process_flag(key, value)
      key = key.to_s
      if key.size == 1
        "-#{key} "
      else
        key = key.tr('_', '-')
        case value
        when TrueClass
          "--#{key} "
        when FalseClass
          "--no-#{key} "
        else
          "--#{key} #{process_value(value)}"
        end
      end
    end

    def process_value(value)
      value = value.to_s
      value.match(/\s/) ? value.inspect : value
    end

  end
end
