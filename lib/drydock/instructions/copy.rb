
require_relative 'base'

module Drydock
  module Instructions
    # The concrete implementation of the COPY instruction.
    # **Do not use this class directly.**
    #
    # @see Project#copy
    class Copy < Base
      attr_accessor :chmod, :ignorefile, :no_cache, :recursive

      attr_reader :chain, :source_path, :target_path
      attr_initialize :chain, :source_path, :target_path do
        @chmod      = false
        @ignorefile = '.dockerignore'
        @no_cache   = false
        @recursive  = true
      end

      # @raise [InvalidInstructionError] when the `source_path` does not exist
      # @raise [InvalidInstructionError] when the `source_path` is an empty directory
      #   with nothing to copy
      # @raise [InvalidInstructionError] when the `target_path` does not exist in the
      #   container
      # @raise [InvalidInstructionError] when the `target_path` exists in the container,
      #   but is not actually a directory
      def run!
        if source_path.start_with?('/')
          Drydock.logger.warn("#{source_path.inspect} is an absolute path; we recommend relative paths")
        end

        fail InvalidInstructionError, "#{source_path} does not exist" unless File.exist?(source_path)

        buffer = build_tar_from_source!
        digest = calculate_digest(buffer)
        write_to_container(buffer, digest)

        self
      end

      private

      def build_tar_from_source!
        buffer = StringIO.new
        log_info("Processing #{source_files.size} files in tree")

        TarWriter.new(buffer) do |tar|
          source_files.each do |source_file|
            File.open(source_file, 'r') do |input|
              stat = input.stat
              mode = chmod || stat.mode
              tar.add_entry(source_file, mode: mode, mtime: stat.mtime) do |tar_file|
                tar_file.write(input.read)
              end
            end
          end
        end

        buffer.rewind
        buffer
      end

      def calculate_digest(buffer)
        Digest::MD5.hexdigest(buffer.read).tap do |digest|
          log_info("Tree digest is md5:#{digest}")
          buffer.rewind
        end
      end

      # Retrieve all files inside {#source_path} not matching the {#ignorefile} rules.
      def source_files
        files =
          if File.directory?(source_path)
            FileManager.find(source_path, ignorefile, prepend_path: true, recursive: recursive).sort
          else
            [source_path]
          end

        fail InvalidInstructionError, "#{source_path} is empty or does not match a path" if files.empty?

        files
      end
      memoize :source_files

      # Create a new container on the `chain`, and then write the contents of
      # `buffer`, whose digest is `digest`.
      def write_to_container(buffer, digest)
        label = "# COPY #{recursive ? 'dir' : 'file'}:md5:#{digest} TO #{target_path}"

        chain.run(label, no_cache: no_cache) do |container|
          target_stat = container.archive_head(target_path)

          # TODO(rpasay): cannot autocreate the target, because `container` here is already dead
          unless target_stat
            fail InvalidInstructionError, "Target path #{target_path.inspect} does not exist"
          end

          unless target_stat.directory?
            Drydock.logger.debug(target_stat)
            fail InvalidInstructionError,
                "Target path #{target_path.inspect} exists, " +
                "but is not a directory in the container"
          end

          container.archive_put(target_path) do |output|
            output.write(buffer.read)
          end
        end
      end

    end
  end
end
