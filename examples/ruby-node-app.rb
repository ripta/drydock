#!/usr/bin/env ruby

require 'rubygems'
require 'bundler'

Bundler.setup
require 'docker'

stream_chunk_proc = proc do |stream, chunk|
  puts "#{stream} #{chunk}"
end

i1 = Docker::Image.create(fromImage: 'gliderlabs/alpine', tag: '3.2')
puts i1.id

c1 = Docker::Container.create(Image: i1.id, Cmd: ['/bin/sh', '-c', 'apk update'], Tty: true)
c1.tap(&:start).attach(&stream_chunk_proc)
c1.wait
puts "  #{c1.changes.size} changed files"

i2 = c1.commit
puts i2.id

c2 = Docker::Container.create(Image: i2.id, Cmd: ['/bin/sh', '-c', 'apk add ruby ruby-dev'], Tty: true)
c2.tap(&:start).attach(&stream_chunk_proc)
c2.wait
puts "  #{c2.changes.size} changed files"

i3 = c2.commit
puts i3.id


##image.run('apk update')
##image.run('apk add ruby ruby-dev')
##image.run('apk add nodejs nodejs-dev')

