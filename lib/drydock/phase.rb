
module Drydock
  class Phase < Struct.new(:source_image, :build_container, :result_image)

    alias_method :build,   :build_container
    alias_method :build=,  :build_container=

    alias_method :result,  :result_image
    alias_method :result=, :result_image=

    alias_method :source,  :source_image
    alias_method :source=, :source_image=

    def self.from(hsh)
      h = hsh.to_h
      new(*h.values_at(*members))
    end

    def build?
      !build_container.nil?
    end

    def finalize!
      return unless build?
      build_container.remove
    end

  end
end
