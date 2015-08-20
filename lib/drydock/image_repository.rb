
module Drydock
  class ImageRepository

    class <<self
      include Enumerable
    end

    def self.all
      Docker::Image.all(all: 1).map do |image|
        Docker::Image.get(image.id)
      end
    end

    def self.dangling
      filters = {dangling: true}
      Docker::Image.all(filters: filters.to_json)
    end

    def self.each(&blk)
      self.all.each(&blk)
    end

  end
end
