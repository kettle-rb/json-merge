# frozen_string_literal: true

# std libs
require "set"

# External gems
# TreeHaver provides a unified cross-Ruby interface to tree-sitter.
# Json::Merge registers its TreeHaver grammar bootstrap when loaded so
# parser_for(:json) can resolve a registered grammar consistently.
require "tree_haver"
require "version_gem"

# Shared merge infrastructure
require "ast/merge"

# This gem
require_relative "merge/version"

# Json::Merge provides a JSON / JSONC smart merge system using tree-sitter AST
# analysis. It intelligently merges template and destination files by
# identifying matching keys and resolving differences using structural
# signatures while preserving comments when present.
#
# @example Basic usage
#   template = File.read("template.json")
#   destination = File.read("destination.json")
#   merger = Json::Merge::SmartMerger.new(template, destination)
#   result = merger.merge
#
# @example With debug information
#   merger = Json::Merge::SmartMerger.new(template, destination)
#   debug_result = merger.merge_with_debug
#   puts debug_result[:content]
#   puts debug_result[:statistics]
module Json
  # Smart merge system for JSON and JSONC files using tree-sitter AST analysis.
  # Provides intelligent merging by understanding JSON structure
  # rather than treating files as plain text.
  #
  # @see SmartMerger Main entry point for merge operations
  # @see FileAnalysis Analyzes JSON structure
  # @see ConflictResolver Resolves content conflicts
  module Merge
    BACKEND_REGISTRY = Struct.new(:registered, :mutex).new(false, Mutex.new)

    # Base error class for Json::Merge
    # Inherits from Ast::Merge::Error for consistency across merge gems.
    class Error < Ast::Merge::Error; end

    # Raised when a JSON file has parsing errors.
    # Inherits from Ast::Merge::ParseError for consistency across merge gems.
    #
    # @example Handling parse errors
    #   begin
    #     analysis = FileAnalysis.new(json_content)
    #   rescue ParseError => e
    #     puts "JSON syntax error: #{e.message}"
    #     e.errors.each { |error| puts "  #{error}" }
    #   end
    class ParseError < Ast::Merge::ParseError
      # @param message [String, nil] Error message (auto-generated if nil)
      # @param content [String, nil] The JSON source that failed to parse
      # @param errors [Array] Parse errors from tree-sitter
      def initialize(message = nil, content: nil, errors: [])
        super(message, errors: errors, content: content)
      end
    end

    # Raised when the template file has syntax errors.
    #
    # @example Handling template parse errors
    #   begin
    #     merger = SmartMerger.new(template, destination)
    #     result = merger.merge
    #   rescue TemplateParseError => e
    #     puts "Template syntax error: #{e.message}"
    #     e.errors.each do |error|
    #       puts "  #{error.message}"
    #     end
    #   end
    class TemplateParseError < ParseError; end

    # Raised when the destination file has syntax errors.
    #
    # @example Handling destination parse errors
    #   begin
    #     merger = SmartMerger.new(template, destination)
    #     result = merger.merge
    #   rescue DestinationParseError => e
    #     puts "Destination syntax error: #{e.message}"
    #     e.errors.each do |error|
    #       puts "  #{error.message}"
    #     end
    #   end
    class DestinationParseError < ParseError; end

    class CorruptionDetectedError < Error; end

    autoload :CommentTracker, "json/merge/comment_tracker"
    autoload :DebugLogger, "json/merge/debug_logger"
    autoload :Emitter, "json/merge/emitter"
    autoload :FileAnalysis, "json/merge/file_analysis"
    autoload :FreezeNode, "json/merge/freeze_node"
    autoload :MergeResult, "json/merge/merge_result"
    autoload :NodeWrapper, "json/merge/node_wrapper"
    autoload :ConflictResolver, "json/merge/conflict_resolver"
    autoload :SmartMerger, "json/merge/smart_merger"
    autoload :ObjectMatchRefiner, "json/merge/object_match_refiner"

    class << self
      def register_backend!
        BACKEND_REGISTRY.mutex.synchronize do
          return if BACKEND_REGISTRY.registered

          grammar_finder = TreeHaver::GrammarFinder.new(:json)
          grammar_finder.register! if grammar_finder.available?

          BACKEND_REGISTRY.registered = true
        end
      end
    end
  end
end

Json::Merge.register_backend!

# Register with ast-merge's MergeGemRegistry for RSpec dependency tags
# Only register if MergeGemRegistry is loaded (i.e., in test environment)
if defined?(Ast::Merge::RSpec::MergeGemRegistry)
  Ast::Merge::RSpec::MergeGemRegistry.register(
    :json_merge,
    require_path: "json/merge",
    merger_class: "Json::Merge::SmartMerger",
    test_source: '{"key": "value"}',
    category: :data,
  )
end

Json::Merge::Version.class_eval do
  extend VersionGem::Basic
end
