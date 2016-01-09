
module Drydock
  class CommitOptions
    attr_reader :opts

    def initialize(opts = {})
      @opts = opts
    end

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
