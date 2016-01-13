
require 'bundler'
require 'rspec/collection_matchers'
require 'rake'
require 'pp'
require 'fakefs/spec_helpers'
require 'simplecov'
require 'simplecov-rcov'

require 'codeclimate-test-reporter'
CodeClimate::TestReporter.start

unless ENV.key?('RCOV')
  SimpleCov.start {
    add_filter '/vendor/'
    add_filter '/spec/'
  }
end

Dir['./spec/support/**/*.rb'].each { |file| require file }

require_relative '../lib/drydock'

RSpec.configure do |config|
  SimpleCov.formatter = SimpleCov::Formatter::RcovFormatter

  if ENV.key?('RSPEC_DEBUG')
    Drydock.logger = Drydock::Logger.new(STDOUT).tap do |l|
      l.level = ::Logger::DEBUG
      l.formatter = Drydock::Formatter.new
    end
  end

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

  if ENV.key?('DOCKER_VERSION')
    docker_version = Gem::Version.new(ENV['DOCKER_VERSION'])

    if Gem::Requirement.new('< 1.8').satisfied_by?(docker_version)
      config.filter_run_excluding docker_archive: true
      config.filter_run_excluding broken_before_d18: true
    end
  end
end
