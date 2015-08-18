
require 'docker'
require 'excon'
require 'fileutils'

require_relative 'drydock/docker_api_patch'

module Drydock # :nodoc:
end

require_relative 'drydock/drydock'
require_relative 'drydock/errors'
require_relative 'drydock/project'

require_relative 'drydock/caches/filesystem_cache'
require_relative 'drydock/caches/no_cache'

require_relative 'drydock/plugins/apk'
require_relative 'drydock/plugins/npm'
require_relative 'drydock/plugins/rubygems'
