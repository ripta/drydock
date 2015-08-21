
module Drydock
  class FileManager

    def self.find(path, ignorefile, recursive: true)
      [].tap do |results|
        ::Find.find(path) do |subpath|
          subpath = subpath.sub(/^#{path}\//, '')

          Find.prune if ignorefile.match?(subpath)

          if File.directory?(subpath)
            Find.prune if path != subpath && !recursive
          else
            results << subpath
          end
        end
      end
    end

  end
end
