
module Drydock
  class IgnorefileDefinition
    extend Forwardable

    def_delegators :@rules, :count, :length, :size

    def initialize(file_or_filename, dotfiles: false)
      @dotfiles = dotfiles

      if file_or_filename.respond_to?(:readlines)
        patterns = Array(file_or_filename.readlines)
      else
        patterns = File.exist?(file_or_filename) ? File.readlines(file_or_filename) : []
      end

      @rules = patterns.map do |pattern|
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
