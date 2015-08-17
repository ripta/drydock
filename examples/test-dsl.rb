
require 'rubygems'
require 'bundler'

Bundler.setup

$LOAD_PATH.unshift(File.expand_path(File.join(File.dirname(__FILE__), '..', 'lib')))
require 'drydock'

base = Drydock.from('gliderlabs/alpine', tag: '3.2', logs: STDERR)
base.run('apk update')
puts base.to_image_id
