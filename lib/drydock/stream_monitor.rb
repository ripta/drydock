
module Drydock
  class StreamMonitor

    extend Forwardable

    CONTAINER_EVENTS = %i(
      attach
      commit copy create
      destroy die
      exec_create exec_start export
      kill
      oom
      pause
      rename resize restart
      start stop
      top
      unpause
    )

    IMAGE_EVENTS = %i(delete import pull push tag untag)

    def_delegators :@thread, :alive?, :join, :kill, :run

    def self.event_type_for(type)
      case type.to_sym
      when *CONTAINER_EVENTS
        :container
      when *IMAGE_EVENTS
        :image
      else
        :object
      end
    end

    def initialize(event_handler)
      @thread = Thread.new do
        previous_ids = {}
        serial_no    = 0

        Docker::Event.stream do |event|
          serial_no += 1

          is_old = previous_ids.key?(event.id)
          event_type = self.class.event_type_for(event.status)
          event_handler.call(event, !is_old, serial_no, event_type)

          previous_ids[event.id] = true
        end
      end
    end

  end
end
