
module Drydock
  # A `StreamMonitor` instantiates a new thread on creation that listens to
  # Docker events incoming from the default Docker server.
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

    # @param [#call] An event handler that is called once for every received event.
    # @yieldparam event [Docker::Event] The event object
    # @yieldparam is_old [Boolean] Whether the event is part of a series of events
    #   that were previously seen before, based on its event ID. If the event ID
    #   had been seen before, `is_old` will be true; false otherwise.
    # @yieldparam serial_no [Integer] The serial number (ever incrementing) of the
    #   event, since the monitor was created. The first event is given serial 1.
    # @yieldparam event_type [:container, :image, :object] The type of the event,
    #   whether is relates to a container, an image, or other objects not currently
    #   known by `Drydock`.
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
