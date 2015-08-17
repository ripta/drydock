#!/usr/bin/env drydock

set :event_stream do |event|
  puts event.inspect
end

from 'gliderlabs/alpine', '3.2'
run 'apk update'
puts latest_image.id
