
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

    def self.find_by_config(config)
      self.find { |image| config == ContainerConfig.from(image.info['ContainerConfig']) }
    end

    def self.select_by_config(config)
      self.select { |image| config == ContainerConfig.from(image.info['ContainerConfig']) }
    end

  end
end
