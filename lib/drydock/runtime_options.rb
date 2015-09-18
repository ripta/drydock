
require 'optparse'

module Drydock
  class RuntimeOptions

    attr_accessor :cache, :includes, :log_level, :read_timeout

    def self.parse!(args)
      opts = new

      parser = OptionParser.new do |cfg|
        cfg.banner = "Usage: #{$0} [options...] [drydock-filename]"

        cfg.separator ''
        cfg.separator 'Runtime / build options:'

        cfg.on('-C', '--no-cache', 'Disable the build cache') do
          opts.cache = false
        end

        cfg.on('-i', '--include PATH', 'Load custom plugins from PATH') do |path|
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

        cfg.on('-t SECONDS', '--timeout SECONDS',
            "Set transaction timeout to SECONDS (default = #{opts.read_timeout})") do |value|
          opts.read_timeout = value.to_i || 60
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
      opts.set!
      opts
    end

    def initialize
      @cache        = true
      @includes     = []
      @log_level    = Logger::INFO

      @read_timeout = Excon.defaults[:read_timeout]
      @read_timeout = 120 if @read_timeout < 120
    end

    def set!
      Excon.defaults[:read_timeout] = self.read_timeout
    end

  end
end
