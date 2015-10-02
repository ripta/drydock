
module Drydock
  class OperationError < StandardError; end

  class InvalidInstructionError < OperationError; end

  class ExecutionError < OperationError; end
  class InvalidCommandExecutionError < ExecutionError; end

  class InsufficientVersionError < OperationError; end
end
