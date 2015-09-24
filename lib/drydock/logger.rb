
require 'logger'

module Drydock
  class Logger < ::Logger

    def add(severity, message = nil, progname = nil, &block)
      annotation = nil
      indent     = 0

      if message.nil?
        if block_given?
          message = yield
        else
          message = progname
          progname = @progname
        end
      end

      if message.respond_to?(:key?) && message.key?(:message)
        indent     = message[:indent].to_i + 1
        annotation = message.fetch(:annotation, '-->')
        message = message[:message]
      end

      annotation << " " if annotation
      indentation = '    ' * indent

      message.to_s.split(/\n/).each do |line|
        if annotation
          super(severity, "#{indentation}#{annotation} #{line}", progname)
        else
          super(severity, line, progname)
        end
      end
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
