
require 'logger'

module Drydock
  class Formatter < ::Logger::Formatter

    def call(severity, time, program, message)
      "%s [%s] %s\n" % [
        severity.slice(0, 1),
        time.strftime('%H:%M:%S'),
        msg2str(message)
      ]
    end

  end
end
