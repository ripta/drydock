# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: drydock 0.0.3 ruby lib

Gem::Specification.new do |s|
  s.name = "drydock"
  s.version = "0.0.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Ripta Pasay"]
  s.date = "2015-08-22"
  s.description = "A Dockerfile-replacement DSL for building complex images"
  s.email = "github@r8y.org"
  s.executables = ["drydock", "json-test-consumer.rb", "json-test-producer.rb", "test-tar-writer-digest.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".dockerignore",
    ".pryrc",
    ".rspec",
    "Dockerfile",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/drydock",
    "bin/json-test-consumer.rb",
    "bin/json-test-producer.rb",
    "bin/test-tar-writer-digest.rb",
    "drydock.gemspec",
    "examples/ruby-dsl.rb",
    "examples/ruby-node-app-dsl.rb",
    "examples/test-dsl.rb",
    "examples/test.rb",
    "lib/drydock.rb",
    "lib/drydock/caches/base.rb",
    "lib/drydock/caches/filesystem_cache.rb",
    "lib/drydock/caches/no_cache.rb",
    "lib/drydock/cli_flags.rb",
    "lib/drydock/container_config.rb",
    "lib/drydock/docker_api_patch.rb",
    "lib/drydock/drydock.rb",
    "lib/drydock/errors.rb",
    "lib/drydock/file_manager.rb",
    "lib/drydock/ignorefile_definition.rb",
    "lib/drydock/image_repository.rb",
    "lib/drydock/logger.rb",
    "lib/drydock/phase.rb",
    "lib/drydock/phase_chain.rb",
    "lib/drydock/plugins/apk.rb",
    "lib/drydock/plugins/base.rb",
    "lib/drydock/plugins/npm.rb",
    "lib/drydock/plugins/package_manager.rb",
    "lib/drydock/plugins/rubygems.rb",
    "lib/drydock/project.rb",
    "lib/drydock/stream_monitor.rb",
    "lib/drydock/tar_writer.rb",
    "spec/drydock/drydock_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/shared_examples/drydockfile.rb"
  ]
  s.homepage = "http://github.com/ripta/drydock"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "Docker Image Pipeline DSL"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<docker-api>, ["~> 1.22"])
      s.add_runtime_dependency(%q<excon>, ["~> 0.45"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_development_dependency(%q<pry>, ["~> 0.10"])
    else
      s.add_dependency(%q<docker-api>, ["~> 1.22"])
      s.add_dependency(%q<excon>, ["~> 0.45"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_dependency(%q<pry>, ["~> 0.10"])
    end
  else
    s.add_dependency(%q<docker-api>, ["~> 1.22"])
    s.add_dependency(%q<excon>, ["~> 0.45"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<jeweler>, ["~> 2.0"])
    s.add_dependency(%q<pry>, ["~> 0.10"])
  end
end

