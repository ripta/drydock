
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

      fail ArgumentError, "unknown options: #{extra_keys.join(', ')}" unless extra_keys.empty?

      new(*h.values_at(*members))
    end

    def initialize(*args)
      super
      @finalized = false
    end

    def built?
      !cached?
    end

    def cached?
      build_container.nil?
    end

    def destroy!(force: false)
      return self if frozen?

      finalize!(force: force)

      if result_image
        begin
          result_image.remove(force: force)
        rescue Docker::Error::NotFoundError => e
          # Ignore, because the image could have been deleted by another phase in
          # another derived chain.
        end
      end

      freeze
    end

    def finalize!(force: false)
      unless finalized?
        build_container.remove(force: force) if built?
        @finalized = true
      end

      self
    end

    def finalized?
      @finalized
    end

  end
end
