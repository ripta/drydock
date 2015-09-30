#!/usr/bin/env ruby

require 'docker'
require_relative '../lib/drydock'

def build_tar(*source_files)
  buffer = StringIO.new
  # Gem::Package::TarWriter
  Drydock::TarWriter.new(buffer) do |tar|
    source_files.each do |source_file|
      File.open(source_file, 'r') do |input|
        tar.add_entry(source_file, mode: input.stat.mode, mtime: input.stat.mtime) do |tar_file|
          tar_file.write(input.read)
        end
      end
    end
  end

  buffer.rewind
  Digest::MD5.hexdigest(buffer.read)
end

files = Dir.glob('./*').reject { |path| File.directory?(path) }

puts build_tar(*files)
sleep 2
puts build_tar(*files)
