#!/usr/bin/env ruby
# frozen_string_literal: true

# Minimal debug script to check TreeHaver backend

require "bundler/setup"

puts "Loading tree_haver..."
require "tree_haver"
puts "✓ Loaded"

puts "\nChecking backends:"
[:mri, :rust, :ffi, :java, :citrus].each do |name|
  mod = TreeHaver::Backends.const_get(name.to_s.capitalize)
  avail = mod.respond_to?(:available?) ? mod.available? : "?"
  puts "  #{name}: #{avail}"
rescue NameError
  puts "  #{name}: not defined"
rescue => e
  puts "  #{name}: #{e.class}"
end

puts "\nEffective backend:"
puts "  TreeHaver.backend_module: #{TreeHaver.backend_module.inspect}"

puts "\nTrying to create parser..."
begin
  parser = TreeHaver::Parser.new
  puts "  ✓ Success: #{parser.backend}"
rescue => e
  puts "  ✗ Failed: #{e.class}: #{e.message}"
end

puts "\nLoading json-merge..."
require "json/merge"

puts "\nJSON language registered?"
puts "  TreeHaver::Language.respond_to?(:json): #{TreeHaver::Language.respond_to?(:json)}"

puts "\nDone."
