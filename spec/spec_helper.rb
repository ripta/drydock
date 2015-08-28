
require 'bundler'
# require 'rspec/collection_matchers'
require 'rake'
require 'fakefs/safe'

Dir['./spec/support/**/*.rb'].each { |file| require file }

require_relative '../lib/drydock'

RSpec.configure do |config|
  if config.files_to_run.one?
    config.default_formatter = 'doc'
  end

  config.order = :random
  Kernel.srand config.seed

  config.expect_with :rspec do |expectations|
    # Enable only the newer, non-monkey-patching expect syntax.
    expectations.syntax = :expect
  end

  config.mock_with :rspec do |mocks|
    mocks.syntax = :expect
    mocks.verify_partial_doubles = true
  end
end
