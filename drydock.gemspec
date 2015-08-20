# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run 'rake gemspec'
# -*- encoding: utf-8 -*-
# stub: drydock 0.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "drydock"
  s.version = "0.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib"]
  s.authors = ["Ripta Pasay"]
  s.date = "2015-08-17"
  s.description = "TODO: longer description of your gem"
  s.email = "github@r8y.org"
  s.executables = ["json-test-consumer.rb", "json-test-producer.rb"]
  s.extra_rdoc_files = [
    "LICENSE",
    "README.md"
  ]
  s.files = [
    "Dockerfile",
    "Gemfile",
    "Gemfile.lock",
    "LICENSE",
    "README.md",
    "Rakefile",
    "VERSION",
    "bin/json-test-consumer.rb",
    "bin/json-test-producer.rb",
    "drydock.gemspec",
    "examples/ruby-node-app-dsl.rb",
    "examples/test-dsl.rb",
    "examples/test.rb"
  ]
  s.homepage = "http://github.com/ripta/drydock"
  s.licenses = ["MIT"]
  s.rubygems_version = "2.2.2"
  s.summary = "TODO: one-line summary of your gem"

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<docker-api>, ["~> 1.22.0"])
      s.add_development_dependency(%q<rake>, [">= 0"])
      s.add_development_dependency(%q<jeweler>, ["~> 2.0"])
    else
      s.add_dependency(%q<docker-api>, ["~> 1.22.0"])
      s.add_dependency(%q<rake>, [">= 0"])
      s.add_dependency(%q<jeweler>, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<docker-api>, ["~> 1.22.0"])
    s.add_dependency(%q<rake>, [">= 0"])
    s.add_dependency(%q<jeweler>, ["~> 2.0"])
  end
end
