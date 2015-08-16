#!/usr/bin/env ruby

STDOUT.sync = true

puts '{"status":"Pulling repository docker.io/gliderlabs/alpine"}'
sleep 2

print '{"status":"Pulling image (latest) from docker.io/gliderlabs/alpine","progressDetail":{},"id":"5bd56d818842"}'
print '{"status":"Pulling image (latest) from docker.io/gliderlabs/alpine, endpoint: https://registry-1.docker.io/v1/","progressDetail":{},"id":"5bd56d818842"}'
sleep 2

puts '{"status":"Pulling dependent layers","progressDetail":{},"id":"5bd56d818842"}'
sleep 1

print '{"status":"Download complete","progressDetail":{},"id":"511136ea3c5a"}'
sleep 1

print '{"status":"Download complete","progressDetail":{},"id":"5bd56d818842"}'
sleep 1

print '{"status":"Download complete","progressDetail":{},"id":"5bd56d818842"}'
sleep 1

print '{"status":"Status: Image is up to date for gliderlabs/alpine:latest"}'

