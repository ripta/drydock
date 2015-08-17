#!/usr/bin/env drydock

set :event_handler do |event|
  puts event
end

from 'gliderlabs/alpine', '3.2'
run 'apk update'
puts latest_image.id
