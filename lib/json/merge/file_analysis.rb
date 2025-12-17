# frozen_string_literal: true

module Json
  module Merge
    # Analyzes JSON file structure, extracting statements for merging.
    # This is the main analysis class that prepares JSON content for merging.
    #
    # @example Basic usage
    #   analysis = FileAnalysis.new(json_source)
    #   analysis.valid? # => true
    #   analysis.statements # => [NodeWrapper, ...]
    class FileAnalysis
      include Ast::Merge::FileAnalyzable

      # @return [TreeHaver::Tree, nil] Parsed AST
      attr_reader :ast

      # @return [Array] Parse errors if any
      attr_reader :errors

      class << self
        # Find the parser library path
        #
        # Uses TreeHaver::GrammarFinder if available, otherwise
        # searches common paths directly.
        #
        # @return [String, nil] Path to the parser library or nil if not found
        def find_parser_path
          # Use TreeHaver's GrammarFinder if available
          if defined?(TreeHaver::GrammarFinder)
            TreeHaver::GrammarFinder.new(:json).find_library_path
          else
            # Fallback: check environment variable first
            env_path = ENV["TREE_SITTER_JSON_PATH"]
            return env_path if env_path && File.exist?(env_path)

            # Search common paths
            [
              "/usr/lib/libtree-sitter-json.so",
              "/usr/lib64/libtree-sitter-json.so",
              "/usr/local/lib/libtree-sitter-json.so",
              "/opt/homebrew/lib/libtree-sitter-json.dylib",
              "/usr/local/lib/libtree-sitter-json.dylib",
            ].find { |path| File.exist?(path) }
          end
        end
      end

      # Initialize file analysis
      #
      # @param source [String] JSON source code to analyze
      # @param signature_generator [Proc, nil] Custom signature generator
      # @param parser_path [String, nil] Path to tree-sitter-json parser library
      def initialize(source, signature_generator: nil, parser_path: nil)
        @source = source
        @lines = source.lines.map(&:chomp)
        @signature_generator = signature_generator
        @parser_path = parser_path || self.class.find_parser_path
        @errors = []

        # Parse the JSON
        DebugLogger.time("FileAnalysis#parse_json") { parse_json }

        @statements = integrate_nodes

        DebugLogger.debug("FileAnalysis initialized", {
          signature_generator: signature_generator ? "custom" : "default",
          statements_count: @statements.size,
          valid: valid?,
        })
      end

      # Check if parse was successful
      # @return [Boolean]
      def valid?
        @errors.empty? && !@ast.nil?
      end

      # Override to detect tree-sitter nodes for signature generator fallthrough
      # @param value [Object] The value to check
      # @return [Boolean] true if this is a fallthrough node
      def fallthrough_node?(value)
        value.is_a?(NodeWrapper) || super
      end

      # Get the root node of the parse tree
      # @return [NodeWrapper, nil]
      def root_node
        return unless valid?

        NodeWrapper.new(@ast.root_node, lines: @lines, source: @source)
      end

      # Get the root object if the JSON document is an object
      # @return [NodeWrapper, nil]
      def root_object
        return unless valid?

        root = @ast.root_node
        return unless root

        # JSON root should be a document containing an object or array
        root.each do |child|
          if child.type.to_s == "object"
            return NodeWrapper.new(child, lines: @lines, source: @source)
          end
        end
        nil
      end

      # Get the opening brace line of the root object (the line containing `{`)
      # @return [String, nil]
      def root_object_open_line
        obj = root_object
        return unless obj&.start_line

        line_at(obj.start_line)&.chomp
      end

      # Get the closing brace line of the root object (the line containing `}`)
      # @return [String, nil]
      def root_object_close_line
        obj = root_object
        return unless obj&.end_line

        line_at(obj.end_line)&.chomp
      end

      # Get key-value pairs from the root object
      # @return [Array<NodeWrapper>]
      def root_pairs
        obj = root_object
        return [] unless obj

        obj.pairs
      end

      private

      def parse_json
        # Check if TreeHaver is available
        unless defined?(TreeHaver)
          error_msg = "TreeHaver not available. Install tree_haver gem."
          @errors << error_msg
          @ast = nil
          return
        end

        begin
          # Use TreeHaver's unified interface
          parser = TreeHaver::Parser.new

          # Determine which language to use
          language = if @parser_path && File.exist?(@parser_path)
            # Custom parser path provided - use it
            TreeHaver::Language.from_library(@parser_path, symbol: "tree_sitter_json", name: "json")
          elsif TreeHaver::Language.respond_to?(:json)
            # Use registered json language (from GrammarFinder)
            TreeHaver::Language.json
          else
            # No language available
            error_msg = if defined?(TreeHaver::GrammarFinder)
              TreeHaver::GrammarFinder.new(:json).not_found_message
            else
              "tree-sitter json parser not found. Install tree-sitter-json or set TREE_SITTER_JSON_PATH."
            end
            @errors << error_msg
            @ast = nil
            return
          end

          parser.language = language
          @ast = parser.parse(@source)

          # Check for parse errors in the tree
          if @ast&.root_node&.has_error?
            collect_parse_errors(@ast.root_node)
          end
        rescue StandardError => e
          @errors << e
          @ast = nil
        end
      end

      def collect_parse_errors(node)
        # Collect ERROR and MISSING nodes from the tree
        if node.type.to_s == "ERROR" || node.missing?
          @errors << {
            type: node.type.to_s,
            start_point: node.start_point,
            end_point: node.end_point,
            text: node.to_s,
          }
        end

        node.each { |child| collect_parse_errors(child) }
      end

      def integrate_nodes
        return [] unless valid?

        result = []
        root = @ast.root_node
        return result unless root

        # Return all root-level nodes (document children)
        # For JSON, this is typically just the root object or array
        # The tree structure is preserved - children are accessed via NodeWrapper#children
        root.each do |child|
          # Skip whitespace-only or empty nodes
          next if child.type.to_s == "comment" # Comments handled separately in JSONC

          wrapper = NodeWrapper.new(child, lines: @lines, source: @source)
          next unless wrapper.start_line && wrapper.end_line

          result << wrapper
        end

        # Sort by start line
        result.sort_by { |node| node.start_line || 0 }
      end

      def compute_node_signature(node)
        return unless node.is_a?(NodeWrapper)

        node.signature
      end
    end
  end
end
