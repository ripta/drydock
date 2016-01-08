# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: dry-dock 0.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "dry-dock"
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Ripta Pasay"]
  s.date = "2016-01-08"
  s.description = "A Dockerfile-replacement DSL for building complex images"
  s.email = "github@r8y.org"
  s.executables = ["drydock", "json-test-consumer.rb", "json-test-producer.rb", "test-tar-writer-digest.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    ".codeclimate.yml",
    ".dockerignore",
    ".pryrc",
    ".rspec",
    ".rubocop.yml",
    ".ruby-version",
    ".travis.yml",
    ".yardopts",
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
    "dry-dock.gemspec",
    "examples/ruby-dsl.rb",
    "examples/ruby-node-app-dsl.rb",
    "examples/test-dsl.rb",
    "examples/test.rb",
    "lib/drydock.rb",
    "lib/drydock/cli_flags.rb",
    "lib/drydock/container_config.rb",
    "lib/drydock/docker_api_patch.rb",
    "lib/drydock/drydock.rb",
    "lib/drydock/errors.rb",
    "lib/drydock/file_manager.rb",
    "lib/drydock/formatters.rb",
    "lib/drydock/ignorefile_definition.rb",
    "lib/drydock/image_repository.rb",
    "lib/drydock/instructions/base.rb",
    "lib/drydock/instructions/copy.rb",
    "lib/drydock/logger.rb",
    "lib/drydock/object_caches/base.rb",
    "lib/drydock/object_caches/filesystem_cache.rb",
    "lib/drydock/object_caches/in_memory_cache.rb",
    "lib/drydock/object_caches/no_cache.rb",
    "lib/drydock/phase.rb",
    "lib/drydock/phase_chain.rb",
    "lib/drydock/plugins/apk.rb",
    "lib/drydock/plugins/base.rb",
    "lib/drydock/plugins/npm.rb",
    "lib/drydock/plugins/package_manager.rb",
    "lib/drydock/plugins/rubygems.rb",
    "lib/drydock/project.rb",
    "lib/drydock/runtime_options.rb",
    "lib/drydock/stream_monitor.rb",
    "lib/drydock/tar_writer.rb",
    "spec/assets/MANIFEST",
    "spec/assets/hello-world.txt",
    "spec/assets/sample.tar",
    "spec/assets/test.sh",
    "spec/drydock/cli_flags_spec.rb",
    "spec/drydock/container_config_spec.rb",
    "spec/drydock/docker_api_patch_spec.rb",
    "spec/drydock/drydock_spec.rb",
    "spec/drydock/file_manager_spec.rb",
    "spec/drydock/formatters_spec.rb",
    "spec/drydock/ignorefile_definition_spec.rb",
    "spec/drydock/image_repository_spec.rb",
    "spec/drydock/object_caches/base_spec.rb",
    "spec/drydock/object_caches/filesystem_cache_spec.rb",
    "spec/drydock/object_caches/no_cache_spec.rb",
    "spec/drydock/phase_chain_spec.rb",
    "spec/drydock/phase_spec.rb",
    "spec/drydock/plugins/apk_spec.rb",
    "spec/drydock/plugins/base_spec.rb",
    "spec/drydock/plugins/npm_spec.rb",
    "spec/drydock/plugins/package_manager_spec.rb",
    "spec/drydock/plugins/rubygems_spec.rb",
    "spec/drydock/project_import_spec.rb",
    "spec/drydock/project_spec.rb",
    "spec/drydock/runtime_options_spec.rb",
    "spec/drydock/stream_monitor_spec.rb",
    "spec/drydock/tar_writer_spec.rb",
    "spec/spec_helper.rb",
    "spec/support/shared_examples/base_class.rb",
    "spec/support/shared_examples/container_config.rb",
    "spec/support/shared_examples/drydockfile.rb"
  ]
  s.homepage = "http://github.com/ripta/drydock"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.4.5.1"
  s.summary = "Docker Image Pipeline DSL"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<attr_extras>, ["~> 4.4"])
      s.add_runtime_dependency(%q<docker-api>, ["~> 1.24"])
      s.add_runtime_dependency(%q<excon>, ["~> 0.45"])
      s.add_runtime_dependency(%q<memoist>, ["~> 0.12"])
      s.add_development_dependency(%q<rake>, ["~> 10.0"])
      s.add_development_dependency(%q<rubocop>, ["~> 0.34"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_development_dependency(%q<pry>, ["~> 0.10"])
      s.add_development_dependency(%q<simplecov>, ["~> 0.9"])
      s.add_development_dependency(%q<simplecov-rcov>, ["~> 0.2"])
    else
      s.add_dependency(%q<attr_extras>, ["~> 4.4"])
      s.add_dependency(%q<docker-api>, ["~> 1.24"])
      s.add_dependency(%q<excon>, ["~> 0.45"])
      s.add_dependency(%q<memoist>, ["~> 0.12"])
      s.add_dependency(%q<rake>, ["~> 10.0"])
      s.add_dependency(%q<rubocop>, ["~> 0.34"])
      s.add_dependency(%q<jeweler>, ["~> 2.0"])
      s.add_dependency(%q<pry>, ["~> 0.10"])
      s.add_dependency(%q<simplecov>, ["~> 0.9"])
      s.add_dependency(%q<simplecov-rcov>, ["~> 0.2"])
    end
  else
    s.add_dependency(%q<attr_extras>, ["~> 4.4"])
    s.add_dependency(%q<docker-api>, ["~> 1.24"])
    s.add_dependency(%q<excon>, ["~> 0.45"])
    s.add_dependency(%q<memoist>, ["~> 0.12"])
    s.add_dependency(%q<rake>, ["~> 10.0"])
    s.add_dependency(%q<rubocop>, ["~> 0.34"])
    s.add_dependency(%q<jeweler>, ["~> 2.0"])
    s.add_dependency(%q<pry>, ["~> 0.10"])
    s.add_dependency(%q<simplecov>, ["~> 0.9"])
    s.add_dependency(%q<simplecov-rcov>, ["~> 0.2"])
  end
end

