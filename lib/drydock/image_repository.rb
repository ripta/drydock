
module Drydock
  class ImageRepository

    class <<self
      include Enumerable
    end

    @image_cache = {}

    def self.all
      Docker::Image.all(all: 1).map do |image|
        @image_cache[image.id] ||= Docker::Image.get(image.id)
      end
    end

    def self.dangling
      filters = {dangling: true}
      Docker::Image.all(filters: filters.to_json)
    end

    def self.each(&blk)
      self.all.each(&blk)
    end

    def self.find_by_config(config)
      base_image = config['Image']
      candidates = self.select_by_config(config)

      possibles = candidates.select do |image|
        image.info['Parent'] == base_image || image.info['ContainerConfig']['Image'] == base_image
      end

      possibles.sort_by { |image| image.info['Created'] }.last
    end

    def self.select_by_config(config)
      self.select { |image| config == ContainerConfig.from(image.info['ContainerConfig']) }
    end

  end
end
