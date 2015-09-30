#!/usr/bin/env ruby

require 'oj'

STDOUT.sync = true

Oj.load(STDIN, Oj.default_options.merge(indent: -1)) do |json|
  puts json.inspect
end


