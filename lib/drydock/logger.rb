
require 'logger'

module Drydock
  class Logger < ::Logger

    def add(severity, message = nil, progname = nil, &block)
      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = @progname
        end
      end

      if message.respond_to?(:key?) && message.key?(:message)
        indentation = '    ' * (message[:indent].to_i + 1)
        annotation = message.fetch(:annotation, '-->')
        message = "#{indentation}#{annotation} #{message[:message]}"
      end

      super(severity, message, progname)
    end

    alias log add

  end

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
