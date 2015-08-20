#!/usr/bin/env drydock

from 'gliderlabs/alpine', '3.2'

with Plugins::APK do |pkg|
  pkg.update
  pkg.upgrade
  pkg.add 'ruby', 'ruby-dev'
end

download_once 'https://github.com/tianon/gosu/releases/download/1.3/gosu-amd64', '/bin/gosu', chmod: 0755
