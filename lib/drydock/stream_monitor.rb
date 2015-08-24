
module Drydock
  class StreamMonitor

    extend Forwardable

    SHORT_FORMAT = Proc.new do |event, is_new, serial|
      timestamp = Time.at(event.time)
      time_string = timestamp.strftime('%H:%M:%S')
      long_id = event.id.to_s
      short_id = if long_id.include?(':') || long_id.include?('/')
        long_id
      else 
        long_id.slice(0, 12)
      end

      if is_new
        Drydock.logger.info(message: "#{short_id} #{event.status}")
      else
        Drydock.logger.debug(message: "#{short_id} #{event.status}")
      end
    end

    def_delegators :@thread, :join, :kill, :run

    def initialize(event_handler)
      @thread = Thread.new do
        previous_id = nil
        serial      = 0

        Docker::Event.stream do |event|
          if previous_id.nil?
            serial += 1
            event_handler.call event, true, serial
          else
            is_new = previous_id != event.id
            serial += 1 if is_new
            event_handler.call event, is_new, serial
          end

          previous_id = event.id
        end
      end
    end

  end
end
