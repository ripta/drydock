
module Drydock
  module Instructions
    # Base class for instruction implementation.
    # **Do not use this class directly.**
    #
    # @see Project
    class Base
      extend AttrExtras.mixin
      extend Memoist
    end
  end
end
