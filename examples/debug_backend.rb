#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug script to investigate TreeHaver backend availability issues
#
# Run with: ruby examples/debug_backend.rb

require "bundler/inline"

gemfile do
  source "https://gem.coop"
  gem "benchmark"
  gem "ruby_tree_sitter"  # Required for MRI backend
  gem "tree_haver", path: File.expand_path(File.join("..", "..", "tree_haver"), __dir__)
  gem "ast-merge", path: File.expand_path(File.join("..", "..", "..", "..", "ast-merge"), __dir__)
  gem "json-merge", path: File.expand_path("..", __dir__)
end

puts "=" * 70
puts "Debug: TreeHaver Backend Availability in json-merge"
puts "=" * 70
puts

# Check what's required
puts "Loading tree_haver..."
require "tree_haver"
puts "✓ tree_haver loaded"
puts

# Check backend availability
puts "Checking backend availability:"
puts "-" * 70

backends = [:mri, :rust, :ffi, :java, :citrus, :prism, :psych, :commonmarker, :markly]
backends.each do |backend_name|
  mod = case backend_name
  when :mri then TreeHaver::Backends::MRI
  when :rust then TreeHaver::Backends::Rust
  when :ffi then TreeHaver::Backends::FFI
  when :java then TreeHaver::Backends::Java
  when :citrus then TreeHaver::Backends::Citrus
  when :prism then TreeHaver::Backends::Prism
  when :psych then TreeHaver::Backends::Psych
  when :commonmarker then TreeHaver::Backends::Commonmarker
  when :markly then TreeHaver::Backends::Markly
  end

  if mod
    available = mod.respond_to?(:available?) ? mod.available? : "no available? method"
    caps = mod.respond_to?(:capabilities) ? mod.capabilities : {}
    puts "  #{backend_name}: available=#{available}, capabilities=#{caps.inspect}"
  else
    puts "  #{backend_name}: module not defined"
  end
rescue => e
  puts "  #{backend_name}: ERROR - #{e.class}: #{e.message}"
end
puts

# Check effective backend
puts "Backend selection:"
puts "-" * 70
puts "  TreeHaver.backend: #{TreeHaver.backend.inspect}"
puts "  TreeHaver.effective_backend: #{TreeHaver.effective_backend.inspect}"
backend_mod = TreeHaver.backend_module
puts "  TreeHaver.backend_module: #{backend_mod.inspect}"
if backend_mod
  puts "  Backend capabilities: #{TreeHaver.capabilities.inspect}"
else
  puts "  ✗ No backend available!"
end
puts

# Check if we can create a parser
puts "Attempting to create parser:"
puts "-" * 70
begin
  parser = TreeHaver::Parser.new
  puts "  ✓ Parser created: #{parser.inspect}"
  puts "  Parser backend: #{parser.backend.inspect}"
rescue TreeHaver::NotAvailable => e
  puts "  ✗ NotAvailable: #{e.message}"
rescue => e
  puts "  ✗ ERROR: #{e.class}: #{e.message}"
  puts e.backtrace.first(5)
end
puts

# Check environment variables
puts "Environment variables:"
puts "-" * 70
env_vars = ENV.select { |k, _| k.start_with?("TREE_SITTER_") }
if env_vars.any?
  env_vars.each { |k, v| puts "  #{k}=#{v}" }
else
  puts "  (no TREE_SITTER_* variables set)"
end
puts

# Check JSON grammar registration
puts "Checking JSON grammar registration:"
puts "-" * 70
require "json/merge"

if TreeHaver::Language.respond_to?(:json)
  puts "  ✓ TreeHaver::Language.json is available"
  begin
    lang = TreeHaver::Language.json
    puts "  Language: #{lang.inspect}"
  rescue => e
    puts "  ✗ Error calling TreeHaver::Language.json: #{e.message}"
  end
else
  puts "  ✗ TreeHaver::Language.json is NOT available"
  puts "  This means the grammar was not registered."
end
puts

# Check GrammarFinder
puts "Checking GrammarFinder for JSON:"
puts "-" * 70
finder = TreeHaver::GrammarFinder.new(:json)
puts "  Finder available?: #{finder.available?}"
puts "  Library path: #{finder.find_library_path.inspect}"
if !finder.available?
  puts "  Not found message: #{finder.not_found_message}"
end
puts

# Try to parse JSON
puts "Attempting to parse JSON:"
puts "-" * 70
json_source = '{"test": "value"}'
begin
  analysis = Json::Merge::FileAnalysis.new(json_source)
  if analysis.valid?
    puts "  ✓ Parse successful!"
    puts "  Statements: #{analysis.statements.size}"
  else
    puts "  ✗ Parse failed"
    puts "  Errors: #{analysis.errors.inspect}"
  end
rescue => e
  puts "  ✗ ERROR: #{e.class}: #{e.message}"
  puts e.backtrace.first(10)
end
puts

puts "=" * 70
puts "Debug complete"
puts "=" * 70
