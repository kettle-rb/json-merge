#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug script to investigate FFI backend behavior with json-merge.
#
# Usage (from json-merge root directory):
#   ruby examples/debug_ffi_backend.rb

WORKSPACE_ROOT = File.expand_path("../..", __dir__)
ENV["KETTLE_RB_DEV"] = WORKSPACE_ROOT unless ENV.key?("KETTLE_RB_DEV")

require "bundler/inline"

gemfile do
  source "https://gem.coop"
  gem "benchmark"
  require File.expand_path("nomono/lib/nomono/bundler", WORKSPACE_ROOT)

  eval_nomono_gems(
    gems: %w[ast-merge json-merge tree_haver],
    prefix: "KETTLE_RB",
    path_env: "KETTLE_RB_DEV",
    vendored_gems_env: "VENDORED_GEMS",
    vendor_gem_dir_env: "VENDOR_GEM_DIR",
    debug_env: "KETTLE_DEV_DEBUG"
  )

  gem "ffi"
end

require "json"
require "json/merge"

puts "=" * 80
puts "FFI Backend Debug Script for json-merge"
puts "=" * 80
puts "Ruby Engine: #{RUBY_ENGINE}"
puts "Ruby Version: #{RUBY_VERSION}"
puts

puts "Environment Variables:"
puts "  TREE_SITTER_JSON_PATH: #{ENV["TREE_SITTER_JSON_PATH"].inspect}"
puts "  LD_LIBRARY_PATH: #{ENV["LD_LIBRARY_PATH"]}"
puts

puts "TreeHaver Backend Status:"
puts "  Current backend: #{begin
  TreeHaver.backend
rescue StandardError
  "N/A"
end}"
puts "  Effective backend: #{begin
  TreeHaver.effective_backend
rescue StandardError
  "N/A"
end}"
puts "  FFI backend available?: #{begin
  TreeHaver::Backends::FFI.available?
rescue StandardError
  false
end}"
puts

puts "=" * 80
puts "0. Grammar Loading Test"
puts "=" * 80

begin
  TreeHaver.with_backend(:ffi) do
    parser = TreeHaver.parser_for(:json)
    puts "✓ JSON grammar loaded successfully!"
    puts "  Parser class: #{parser.class}"
    puts "  Parser backend: #{begin
      parser.backend
    rescue StandardError
      "N/A"
    end}"
    puts "  JSONC comments flow through the unified JSON parser path."
  end
rescue StandardError => e
  puts "✗ Grammar loading failed!"
  puts "  Error class: #{e.class}"
  puts "  Error message: #{e.message}"
  exit(1)
end
puts

valid_jsonc = <<~JSONC
  {
    // ffi backend comment
    "name": "test",
    "version": "1.0.0"
  }
JSONC

invalid_json = '{ "unclosed": '

template_jsonc = '{"name": "template", "newField": "value"}'
dest_jsonc = <<~JSONC
  {
    // destination comment
    "name": "destination"
  }
JSONC

puts "=" * 80
puts "1. Testing FileAnalysis with Valid JSONC"
puts "=" * 80

TreeHaver.with_backend(:ffi) do
  analysis = Json::Merge::FileAnalysis.new(valid_jsonc)
  puts "Valid: #{analysis.valid?}"
  puts "Errors: #{analysis.errors.inspect}"
  puts "Root node: #{analysis.root_node.inspect}"
  puts "Comment count: #{analysis.comment_tracker.comments.size}"
end
puts

puts "=" * 80
puts "2. Testing FileAnalysis with Invalid JSON"
puts "=" * 80

TreeHaver.with_backend(:ffi) do
  analysis = Json::Merge::FileAnalysis.new(invalid_json)
  puts "Valid: #{analysis.valid?}"
  puts "Errors count: #{analysis.errors.size}"
end
puts

puts "=" * 80
puts "3. Testing SmartMerger with add_template_only_nodes"
puts "=" * 80

TreeHaver.with_backend(:ffi) do
  merger = Json::Merge::SmartMerger.new(template_jsonc, dest_jsonc, add_template_only_nodes: true)
  result = merger.merge

  puts "Merged output:"
  puts result
  puts
  puts "Contains destination value?: #{result.include?("destination")}"
  puts "Contains template-only field?: #{result.include?("newField")}"

  parsed = JSON.parse(result)
  puts "Parsed keys: #{parsed.keys.inspect}"
end

puts
puts "=" * 80
puts "SUMMARY"
puts "=" * 80
puts "FFI backend debug run complete. Compare output with other backend scripts if needed."
