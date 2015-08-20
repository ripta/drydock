
module Drydock
  class StreamMonitor

    extend Forwardable

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
