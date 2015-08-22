
module Drydock
  class RuntimeOptions

    attr_accessor :includes, :log_level

    def initialize
      @includes  = []
      @log_level = Logger::INFO
    end

  end
end
