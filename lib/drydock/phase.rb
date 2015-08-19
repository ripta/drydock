
module Drydock
  class Phase < Struct.new(:source_image, :build_container, :result_image)

    alias_method :build,   :build_container
    alias_method :build=,  :build_container=

    alias_method :result,  :result_image
    alias_method :result=, :result_image=

    alias_method :source,  :source_image
    alias_method :source=, :source_image=

  end
end
