
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
      extra_keys = h.keys - members
      raise ArgumentError, "unknown options: #{extra_keys.join(', ')}" unless extra_keys.empty?
      new(*h.values_at(*members))
    end

    def built?
      !cached?
    end

    def cached?
      build_container.nil?
    end

    def finalize!
      return unless built?
      build_container.remove
    end

  end
end
