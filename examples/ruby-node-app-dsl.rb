#!/usr/bin/env ruby

require 'rubygems'
require 'docker'

app_root   = '/app'
build_root = '/build'

dd = Drydock.from('gliderlabs/alpine:3.2', logs: STDERR, report_changes: true)

#dd.run('apk update')
#dd.run('apk add ruby ruby-dev')
#dd.run('apk add nodejs nodejs-dev')
#dd.run('apk add musl musl-dev')
#dd.run('apk add linux-headers')
#dd.run('apk add gcc g++')
#dd.run('apk add make')
#dd.run('apk add curl curl-dev')
#dd.run('apk add openssh')
#dd.run('apk add libffi-dev libxml2-dev libxslt-dev')
#dd.run('apk add git')
dd.with(:pkg) do |pkg|
  pkg.update
  pkg.add('ruby', 'ruby-dev')
  pkg.add('nodejs', 'nodejs-dev')
  pkg.add('musl', 'musl-dev')
  pkg.add('linux-headers')
  pkg.add('gcc', 'g++')
  pkg.add('make')
  pkg.add('curl', 'curl-dev')
  pkg.add('openssh')
  pkg.add('libffi-dev', 'libxml2-dev', 'libxslt-dev')
  pkg.add('git')
end

#dd.download('https://github.com/tianon/gosu/releases/download/1.3/gosu-amd64', '/bin/gosu', chmod: 0755)
dd.download_once('https://github.com/tianon/gosu/releases/download/1.3/gosu-amd64', '/bin/gosu', chmod: 0755)

dd.with(:rubygems) do |gem|
  gem.source.add 'https://s3.amazonaws.com/production.s3.rubygems.org/'
  gem.source.remove 'https://rubygems.org/'
  gem.update_system(no_document: true)
  gem.install('bundler', no_document: true)
  gem.install('unicorn', no_document: true)
end

dd.run('bundle config --global frozen 1')
dd.run('bundle config --global build.nokogiri --use-system-libraries')

dd.with(:npm) do |npm|
  npm.install('bower', 'gulp', global: true)
end

# Drydock.using(dd) { |base| ... }
#   or
# base = Drydock.from(dd.id)
#   ...
Drydock.using(dd) do |base|
  base.env('BUILD_ROOT', build_root)
  base.mkdir(build_root)

  # dd.snapshot('name') do |base|
  #   ...
  # end
  #   or
  # base = Drydock.from('name') || Drydock.from(dd.id)
  #   ...
  # base.tag('name')
  bundle_image = base.snapshot('rubygems', max_age: Date.beginning_of_week) do |build|
    build.copy('Gemfile', build_root)
    build.copy('Gemfile.lock', build_root)
    build.in(build_root).run('bundle --path vendor')
  end

  npm_image = base.snapshot('npm', max_age: Date.beginning_of_week) do |build|
    build.copy('package.json', build_root)
    build.in(build_root).npm.install
  end

  Drydock.using(dd) do |build|
    build.env('APPLICATION_ROOT', app_root)
    build.mkdir(app_root)
  
    build.copy('.', app_root)
    build.import(bundle_image.export(build_root), app_root)
    build.import(npm_image.export(build_root), app_root)

    build.tag('ripta/dumplings', 'v1.0')
  end
end


