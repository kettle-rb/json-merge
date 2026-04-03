#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug script to investigate JRuby / Java backend behavior with json-merge.
#
# Usage (from json-merge root directory):
#   jruby examples/debug_java_backend.rb

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
end

require "json"
require "json/merge"

puts "=" * 80
puts "JRuby/Java Backend Debug Script for json-merge"
puts "=" * 80
puts "Ruby Engine: #{RUBY_ENGINE}"
puts "Ruby Version: #{RUBY_VERSION}"
puts

unless RUBY_ENGINE == "jruby"
  puts "ERROR: This script must be run with JRuby."
  puts "Usage: jruby examples/debug_java_backend.rb"
  exit 1
end

puts "Environment Variables:"
puts "  TREE_SITTER_JAVA_JARS_DIR: #{ENV["TREE_SITTER_JAVA_JARS_DIR"].inspect}"
puts "  TREE_SITTER_RUNTIME_LIB:   #{ENV["TREE_SITTER_RUNTIME_LIB"].inspect}"
puts "  TREE_SITTER_JSON_PATH:     #{ENV["TREE_SITTER_JSON_PATH"].inspect}"
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
puts "  Java backend available?: #{begin
  TreeHaver::Backends::Java.available?
rescue StandardError
  false
end}"
puts

puts "=" * 80
puts "0. Grammar Loading Test"
puts "=" * 80

json_path = ENV["TREE_SITTER_JSON_PATH"]
if json_path && File.exist?(json_path)
  puts "JSON grammar path: #{json_path}"
  puts "File size: #{File.size(json_path)} bytes"
  puts

  begin
    TreeHaver.with_backend(:java) do
      parser = TreeHaver.parser_for(:json)
      puts "✓ JSON grammar loaded successfully!"
      puts "  Parser class: #{parser.class}"
      puts "  Parser language: #{begin
        parser.language
      rescue StandardError
        "N/A"
      end}"
    end
  rescue StandardError => e
    puts "✗ Grammar loading failed!"
    puts "  Error class: #{e.class}"
    puts "  Error message: #{e.message}"
    exit(1)
  end
else
  puts "✗ TREE_SITTER_JSON_PATH not set or file does not exist"
  puts "  Value: #{json_path.inspect}"
  exit 1
end
puts

valid_jsonc = <<~JSONC
  {
    // java backend comment
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

analysis = Json::Merge::FileAnalysis.new(valid_jsonc)
puts "Valid: #{analysis.valid?}"
puts "Errors: #{analysis.errors.inspect}"
puts "Root node: #{analysis.root_node.inspect}"
puts "Comment count: #{analysis.comment_tracker.comments.size}"
puts

puts "=" * 80
puts "2. Testing FileAnalysis with Invalid JSON"
puts "=" * 80

analysis = Json::Merge::FileAnalysis.new(invalid_json)
puts "Valid: #{analysis.valid?}"
puts "Errors: #{analysis.errors.inspect}"
puts

puts "=" * 80
puts "3. Testing SmartMerger with add_template_only_nodes"
puts "=" * 80

merger = Json::Merge::SmartMerger.new(template_jsonc, dest_jsonc, add_template_only_nodes: true)
result = merger.merge

puts "Merged output:"
puts result
puts
puts "Contains destination value?: #{result.include?("destination")}"
puts "Contains template-only field?: #{result.include?("newField")}"
puts "Contains destination comment?: #{result.include?("// destination comment")}"

parsed = JSON.parse(result)
puts "Parsed keys: #{parsed.keys.inspect}"
puts

puts "=" * 80
puts "SUMMARY"
puts "=" * 80
puts "If this script passes, JRuby / Java backend support for json-merge JSON/JSONC parsing looks healthy."
