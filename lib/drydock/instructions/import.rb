
require_relative 'base'

module Drydock
  module Instructions
    # The concrete implementation of the IMPORT instruction.
    # **Do not use this class directly.**
    #
    # @see Project#import
    class Import < Base
      attr_accessor :force, :spool, :total_size

      attr_reader :source_chain, :target_chain, :path
      attr_initialize :source_chain, :target_chain, :path do
        @force      = false
        @spool      = false
        @total_size = 0
      end

      def run!
        spool ? run_with_spool! : run_without_spool!
        self
      end

      private

      def run_with_spool!
        spool_file = Tempfile.new('drydock')
        log_info("Spooling to #{spool_file.path}")

        source_chain.run("# EXPORT #{path}", no_commit: true) do |source_container|
          source_container.archive_get(path + '/.') do |chunk|
            spool_file.write(chunk.to_s).tap { |b| @total_size += b }
          end
        end

        spool_file.rewind
        target_chain.run("# IMPORT #{path}", no_cache: true) do |target_container|
          target_container.archive_put(path) do |output|
            output.write(spool_file.read)
          end
        end

        spool_file.close
      end

      def run_without_spool!
        target_chain.run("# IMPORT #{path}", no_cache: true) do |target_container|
          target_container.archive_put(path) do |output|
            source_chain.run("# EXPORT #{path}", no_commit: true) do |source_container|
              source_container.archive_get(path + '/.') do |chunk|
                output.write(chunk.to_s).tap { |b| @total_size += b }
              end
            end
          end
        end
      end

    end
  end
end
