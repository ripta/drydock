
module Drydock
  class OperationError < StandardError; end

  class InvalidInstructionError < OperationError; end
end
