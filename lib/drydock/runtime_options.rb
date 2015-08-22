
require 'optparse'

module Drydock
  class RuntimeOptions

    attr_accessor :includes, :log_level

    def self.parse!(args)
      opts = new

      parser = OptionParser.new do |cfg|
        cfg.banner = "Usage: #{$0} [options...] [drydock-filename]"

        cfg.separator ''
        cfg.separator 'Runtime / build options:'

        cfg.on('-I', '--include PATH', 'Load custom plugins from PATH') do |path|
          opts.includes << path
        end
        
        cfg.separator ''
        cfg.separator 'General options:'

        cfg.on('-h', '--help', 'Show this help message') do
          puts cfg
          exit
        end

        cfg.on('-q', '--quiet', 'Run silently, except for errors') do |value|
          opts.log_level = Logger::ERROR
        end

        cfg.on('-v', '--verbose', 'Run verbosely') do |value|
          opts.log_level = Logger::DEBUG
        end

        cfg.on('-V', '--version', 'Show version') do
          puts Drydock.banner
          exit
        end
      end

      parser.parse!(args)
      opts
    end

    def initialize
      @includes  = []
      @log_level = Logger::INFO
    end

  end
end
