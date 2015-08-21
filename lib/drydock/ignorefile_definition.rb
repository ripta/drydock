
module Drydock
  class IgnorefileDefinition

    def initialize(filename)
      patterns = File.exist?(filename) ? File.readlines(filename) : []
      @rules   = patterns.map do |pattern|
        if pattern.start_with?('!')
          {pattern: pattern.slice(1..-1), exclude: true}
        else
          {pattern: pattern, exclude: false}
        end
      end
    end

    def match?(filename)
      @rules.any? do |rule|
        match = File.fnmatch?(rule[:pattern], filename)
        rule[:exclude] ? !match : match
      end
    end

  end
end
