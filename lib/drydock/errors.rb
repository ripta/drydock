
module Drydock
  class OperationError < StandardError; end

  class InvalidInstructionError < OperationError; end

  class ExecutionError < OperationError; end

  class InvalidCommandExecutionError < ExecutionError

    def initialize(message: nil, container: nil, configuration: {})
      super(message)
      @data = {
        container: container,
        configuration: configuration
      }
    end

    def configuration
      @data[:configuration]
    end

    def container
      @data[:container]
    end

  end

  class InsufficientVersionError < OperationError; end
end
