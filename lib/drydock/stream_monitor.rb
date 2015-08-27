
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
        previous_ids = {}
        serial_no    = 0

        Docker::Event.stream do |event|
          serial_no += 1

          is_old = previous_ids.key?(event.id)
          event_handler.call event, !is_old, serial_no

          previous_ids[event.id] = true
        end
      end
    end

  end
end
