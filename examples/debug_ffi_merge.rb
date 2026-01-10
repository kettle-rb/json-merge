#!/usr/bin/env ruby
# frozen_string_literal: true

# Debug script to investigate FFI backend behavior with json-merge
#
# Usage (from json-merge root directory):
#   ruby examples/debug_ffi_merge.rb

require "bundler/inline"

gemfile do
  source "https://gem.coop"
  gem "ast-merge", path: File.expand_path("../../../../", __dir__)
  gem "json-merge", path: File.expand_path("..", __dir__)
  gem "tree_haver", path: File.expand_path("../../tree_haver", __dir__)
  gem "ffi" # FFI backend requires this
end

require "json/merge"

puts "=" * 80
puts "FFI Backend Debug Script for json-merge"
puts "=" * 80
puts "Ruby Engine: #{RUBY_ENGINE}"
puts "Ruby Version: #{RUBY_VERSION}"
puts

# Verify MRI backend is NOT loaded
if defined?(::TreeSitter::Parser)
  puts "ERROR: MRI backend is already loaded. Cannot test FFI."
  exit 1
end
puts "✓ MRI backend is NOT loaded"
puts

puts "Environment Variables:"
puts "  TREE_SITTER_JSON_PATH: #{ENV["TREE_SITTER_JSON_PATH"].inspect}"
puts "  LD_LIBRARY_PATH: #{ENV["LD_LIBRARY_PATH"]}"
puts

# Force FFI backend
ENV["TREE_HAVER_BACKEND"] = "ffi"
TreeHaver.reset_backend!

puts "TreeHaver Backend Status:"
puts "  Current backend: #{TreeHaver.backend}"
puts "  Effective backend: #{TreeHaver.effective_backend}"
puts "  FFI backend available?: #{TreeHaver::Backends::FFI.available?}"
puts

# Test grammar loading
puts "=" * 80
puts "0. Grammar Loading Test"
puts "=" * 80

begin
  TreeHaver.with_backend(:ffi) do
    parser = TreeHaver.parser_for(:json)
    puts "✓ JSON grammar loaded successfully!"
    puts "  Parser class: #{parser.class}"
    puts "  Parser backend: #{parser.backend}"
  end
rescue => e
  puts "✗ Grammar loading failed!"
  puts "  Error class: #{e.class}"
  puts "  Error message: #{e.message}"
  puts
  puts "This script cannot continue without a working JSON grammar."
  exit(1)
end
puts

# Test parsing
puts "=" * 80
puts "1. Testing FileAnalysis with Valid JSON"
puts "=" * 80

valid_json = '{"name": "test", "version": "1.0.0"}'

TreeHaver.with_backend(:ffi) do
  analysis = Json::Merge::FileAnalysis.new(valid_json)
  puts "Valid: #{analysis.valid?}"
  puts "Errors: #{analysis.errors}"
  puts "AST nil?: #{analysis.ast.nil?}"
  puts "Root node: #{analysis.root_node&.class}"
  puts "Statements count: #{analysis.statements.size}"

  if analysis.valid? && analysis.root_node
    puts "Root node type: #{analysis.root_node.type}"
    puts "Root node children: #{analysis.root_node.children.size}"

    analysis.root_node.children.each_with_index do |child, i|
      puts "  [#{i}] type=#{child.type}"
    end
  end
end
puts

# Test merge with add_template_only_nodes
puts "=" * 80
puts "2. Testing SmartMerger with add_template_only_nodes"
puts "=" * 80

template_json = <<~JSON
  {
    "name": "template",
    "newField": "value"
  }
JSON

dest_json = <<~JSON
  {
    "name": "destination"
  }
JSON

TreeHaver.with_backend(:ffi) do
  puts "Template analysis:"
  template_analysis = Json::Merge::FileAnalysis.new(template_json)
  puts "  valid?: #{template_analysis.valid?}"
  puts "  statements: #{template_analysis.statements.size}"
  template_analysis.statements.each_with_index do |stmt, i|
    puts "    [#{i}] type=#{stmt.type}, sig=#{stmt.signature.inspect}"
    puts "        root_level_container?=#{stmt.root_level_container?}" if stmt.respond_to?(:root_level_container?)
  end
  puts

  puts "Destination analysis:"
  dest_analysis = Json::Merge::FileAnalysis.new(dest_json)
  puts "  valid?: #{dest_analysis.valid?}"
  puts "  statements: #{dest_analysis.statements.size}"
  dest_analysis.statements.each_with_index do |stmt, i|
    puts "    [#{i}] type=#{stmt.type}, sig=#{stmt.signature.inspect}"
    puts "        root_level_container?=#{stmt.root_level_container?}" if stmt.respond_to?(:root_level_container?)
  end
  puts

  puts "Performing merge with add_template_only_nodes: true..."
  merger = Json::Merge::SmartMerger.new(
    template_json,
    dest_json,
    add_template_only_nodes: true,
  )
  result = merger.merge_result

  puts "Result class: #{result.class}"
  puts "Result lines: #{result.lines.size}"
  result.lines.each_with_index do |line, i|
    puts "  [#{i}] #{line.inspect}"
  end
  puts
  puts "Final merged output:"
  puts result.to_json
  puts
  puts "Checking expectations:"
  output = result.to_json
  puts "  Contains 'newField'?: #{output.include?("newField")}"
  puts "  Contains 'destination'?: #{output.include?("destination")}"

  # Validate it's valid JSON
  begin
    require 'json'
    parsed = JSON.parse(output)
    puts "  Valid JSON?: true"
    puts "  Parsed keys: #{parsed.keys.inspect}"
  rescue JSON::ParserError => e
    puts "  Valid JSON?: false - #{e.message}"
  end
end

puts
puts "=" * 80
puts "Done"
puts "=" * 80

