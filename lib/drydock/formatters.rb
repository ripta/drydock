module Drydock
  module Formatters

    DELIMITER_PATTERN = /(\d)(?=(\d\d\d)+(?!\d))/

    def self.number(value, delimiter: ',', separator: '.')
      integers, decimals = value.to_s.split('.')
      integers.gsub!(DELIMITER_PATTERN) { |digits| "#{digits}#{delimiter}" }
      [integers, decimals].compact.join(separator)
    end

  end
end
