
module Drydock
  class IgnorefileDefinition

    def initialize(filename, dotfiles: false)
      @dotfiles = dotfiles

      patterns = File.exist?(filename) ? File.readlines(filename) : []
      @rules   = patterns.map do |pattern|
        pattern = pattern.chomp
        if pattern.start_with?('!')
          {pattern: pattern.slice(1..-1), exclude: true}
        else
          {pattern: pattern, exclude: false}
        end
      end
    end

    def match?(filename)
      @rules.any? do |rule|
        if @dotfiles && filename.start_with?('.') && filename.size > 1
          true
        else
          match = File.fnmatch?(rule[:pattern], filename)
          rule[:exclude] ? !match : match
        end
      end
    end

  end
end
