
module Drydock
  # Generate commit options to be provided to `Docker::Image#commit`.
  class CommitOptions

    attr_reader :opts

    # @param [Hash] opts the options to transform to commit options; all options
    #   are optional
    # @option opts [String, Array] :command the command to list in the image
    # @option opts [String] :entrypoint the entrypoint to list in the image
    # @option opts [String] :author the name / email of the author of the image
    # @option opts [String] :comment the comment to include in the result image
    def initialize(opts = {})
      @opts = opts
    end

    # The hash to pass onto `Docker::Image#commit`.
    #
    # @return [Hash]
    def to_h
      {}.tap do |commit|
        if opts.key?(:command)
          commit['run'] ||= {}
          commit['run'][:Cmd] = opts[:command]
        end

        if opts.key?(:entrypoint)
          commit['run'] ||= {}
          commit['run'][:Entrypoint] = opts[:entrypoint]
        end

        commit[:author]  = opts.fetch(:author, '')  if opts.key?(:author)
        commit[:comment] = opts.fetch(:comment, '') if opts.key?(:comment)
      end
    end

  end
end
