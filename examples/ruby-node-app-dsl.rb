#!/usr/bin/env drydock

APP_ROOT   = '/app'
BUILD_ROOT = '/build'
REPO_NAME  = 'ripta/test'
TAG_NAME   = 'v1.0'

from 'gliderlabs/alpine', '3.2'

with Plugins::APK do |pkg|
  pkg.update
  pkg.upgrade
  pkg.add 'ruby', 'ruby-dev'
  pkg.add 'nodejs', 'nodejs-dev'
  pkg.add 'musl', 'musl-dev'
  pkg.add 'linux-headers'
  pkg.add 'gcc', 'g++'
  pkg.add 'make'
  pkg.add 'curl', 'curl-dev'
  pkg.add 'openssh'
  pkg.add 'libffi-dev', 'libxml2-dev', 'libxslt-dev'
  pkg.add 'git'
end

download_once 'https://github.com/tianon/gosu/releases/download/1.3/gosu-amd64', '/bin/gosu', chmod: 0755

with Plugins::Rubygems do |g|
  # g.source.add 'https://s3.amazonaws.com/production.s3.rubygems.org/'
  # g.source.remove 'https://rubygems.org/'
  g.update_system(document: false)
  g.install('bundler', document: false)
  g.install('unicorn', document: false)
end

run 'bundle config --global frozen 1'
run 'bundle config --global build.nokogiri --use-system-libraries'

with Plugins::NPM do |npm|
  npm.install('bower', 'gulp', global: true)
end

one_week_old = CachingStrategies::TimeLimited.new(
  max_age:   1.week,
  max_depth: 1
)

derive do
  env 'BUILD_ROOT', BUILD_ROOT
  mkdir BUILD_ROOT

  env 'APP_ROOT', APP_ROOT
  mkdir APP_ROOT

  gem_image = derive(label: 'rubygems', strategy: one_week_old) do
    copy 'Gemfile', BUILD_ROOT
    copy 'Gemfile.lock', BUILD_ROOT

    cd BUILD_ROOT do
      run 'bundle --path vendor'
    end
  end

  npm_image = if File.exist?('package.json')
    derive(label: 'npm', strategy: one_week_old) do
      copy 'package.json', BUILD_ROOT
      cd BUILD_ROOT do
        with(Plugins::NPM).install
      end
    end
  end

  import 'vendor',       from: BUILD_ROOT, in: gem_image, to: APP_ROOT
  import 'node_modules', from: BUILD_ROOT, in: npm_image, to: APP_ROOT
  # import_stream gem_image.export_stream(BUILD_ROOT / 'vendor'), APP_ROOT / 'vendor'
  # import_stream npm_image.export_stream(BUILD_ROOT / 'node_modules'), APP_ROOT / 'node_modules'
  copy '.', BUILD_ROOT

  # import_stream BUILD_ROOT do |writer|
  #   gem_image.export_stream(BUILD_ROOT + '/vendor') do |reader|
  #     while chunk = reader.read(32 * 1024)
  #       writer.write(chunk)
  #     end
  #   end
  # end

  # tag REPO_NAME, TAG_NAME
end

# # Drydock.using(dd) { |base| ... }
# #   or
# # base = Drydock.from(dd.id)
# #   ...
# Drydock.using(dd) do |base|
#   base.env('BUILD_ROOT', build_root)
#   base.mkdir(build_root)

#   # dd.snapshot('name') do |base|
#   #   ...
#   # end
#   #   or
#   # base = Drydock.from('name') || Drydock.from(dd.id)
#   #   ...
#   # base.tag('name')
#   bundle_image = base.snapshot('rubygems', max_age: Date.beginning_of_week) do |build|
#     build.copy('Gemfile', build_root)
#     build.copy('Gemfile.lock', build_root)
#     build.in(build_root).run('bundle --path vendor')
#   end

#   npm_image = base.snapshot('npm', max_age: Date.beginning_of_week) do |build|
#     build.copy('package.json', build_root)
#     build.in(build_root).npm.install
#   end

#   Drydock.using(dd) do |build|
#     build.env('APPLICATION_ROOT', app_root)
#     build.mkdir(app_root)
  
#     build.copy('.', app_root)
#     build.import(bundle_image.export(build_root), app_root)
#     build.import(npm_image.export(build_root), app_root)

#     build.tag('ripta/dumplings', 'v1.0')
#   end
# end


