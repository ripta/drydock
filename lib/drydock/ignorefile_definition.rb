
module Drydock
  class IgnorefileDefinition
    class Rule < Struct.new(:pattern, :exclude)
      alias_method :exclude?, :exclude

      def match?(test)
        File.fnmatch?(pattern, test)
      end
    end

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
          Rule.new(pattern.slice(1..-1), true)
        else
          Rule.new(pattern, false)
        end
      end
    end

    def match?(filename)
      return false if excludes?(filename)
      return true if includes?(filename)
      return true if is_dotfile?(filename)
      return false
    end

    private

    def excludes?(filename)
      @rules.select { |rule| rule.exclude? }.any? do |rule|
        rule.match?(filename)
      end
    end

    def includes?(filename)
      @rules.select { |rule| !rule.exclude? }.any? do |rule|
        rule.match?(filename)
      end
    end

    def is_dotfile?(filename)
      @dotfiles && filename.start_with?('.') && filename.size > 1
    end

  end
end
