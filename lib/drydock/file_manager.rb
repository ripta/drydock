
module Drydock
  class FileManager

    def self.find(path, ignorefile, prepend_path: false, recursive: true)
      path = path.sub(%r{/$}, '')

      [].tap do |results|
        ::Find.find(path) do |subpath|
          subpath = subpath.sub(%r{^#{path}/}, '')

          Find.prune if ignorefile.match?(subpath)

          if File.directory?(subpath)
            Find.prune if path != subpath && !recursive
          elsif prepend_path
            results << File.join(path, subpath)
          else
            results << subpath
          end
        end
      end
    end

  end
end
