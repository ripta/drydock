
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

    def destroy!(force: false)
      if result_image
        begin
          result_image.remove(force: force)
        rescue Docker::Error::NotFoundError => e
          # Ignore, because the image could have been deleted by another phase in
          # another derived chain.
        end
      end

      build_container.remove(force: force) if built?
      self
    end

    def finalize!(force: false)
      return self unless built?
      build_container.remove(force: force)
      self
    end

  end
end
