# frozen_string_literal: true

module Json
  module Merge
    # High-level merger for JSON/JSONC content.
    # Orchestrates parsing, analysis, and conflict resolution.
    #
    # @example Basic usage
    #   merger = SmartMerger.new(template_content, dest_content)
    #   result = merger.merge
    #   File.write("merged.json", result.output)
    #
    # @example With options
    #   merger = SmartMerger.new(template, dest,
    #     signature_match_preference: :template,
    #     add_template_only_nodes: true)
    #   result = merger.merge
    #
    # @example Enable fuzzy matching
    #   merger = SmartMerger.new(template, dest, match_refiner: ObjectMatchRefiner.new)
    #
    # @example With regions (embedded content)
    #   merger = SmartMerger.new(template, dest,
    #     regions: [{ detector: SomeDetector.new, merger_class: SomeMerger }])
    class SmartMerger < ::Ast::Merge::SmartMergerBase
      # Creates a new SmartMerger
      #
      # @param template_content [String] Template JSON content
      # @param dest_content [String] Destination JSON content
      # @param signature_match_preference [Symbol] :destination or :template
      # @param add_template_only_nodes [Boolean] Whether to add nodes only found in template
      # @param match_refiner [#call, nil] Match refiner for fuzzy matching
      # @param regions [Array<Hash>, nil] Region configurations for nested merging
      # @param region_placeholder [String, nil] Custom placeholder for regions
      def initialize(
        template_content,
        dest_content,
        signature_match_preference: :destination,
        add_template_only_nodes: false,
        match_refiner: nil,
        regions: nil,
        region_placeholder: nil
      )
        super(
          template_content,
          dest_content,
          signature_match_preference: signature_match_preference,
          add_template_only_nodes: add_template_only_nodes,
          match_refiner: match_refiner,
          regions: regions,
          region_placeholder: region_placeholder,
        )
      end

      # Backward-compatible options hash
      #
      # @return [Hash] The merge options
      def options
        {
          signature_match_preference: @signature_match_preference,
          add_template_only_nodes: @add_template_only_nodes,
          match_refiner: @match_refiner,
        }
      end

      protected

      # @return [Class] The analysis class for JSON files
      def analysis_class
        FileAnalysis
      end

      # @return [String] The default freeze token (not used for JSON)
      def default_freeze_token
        "json-merge"
      end

      # @return [Class] The resolver class for JSON files
      def resolver_class
        ConflictResolver
      end

      # @return [Class] The result class for JSON files
      def result_class
        MergeResult
      end

      # Perform the JSON-specific merge
      #
      # @return [MergeResult] The merge result
      def perform_merge
        @resolver.resolve(@result)

        DebugLogger.debug("Merge complete", {
          lines: @result.line_count,
          decisions: @result.statistics,
        })

        @result
      end

      # Build the resolver with JSON-specific signature
      def build_resolver
        ConflictResolver.new(
          @template_analysis,
          @dest_analysis,
          signature_match_preference: @signature_match_preference,
          add_template_only_nodes: @add_template_only_nodes,
          match_refiner: @match_refiner,
        )
      end

      # Build the result (no-arg constructor for JSON)
      def build_result
        MergeResult.new
      end

      # @return [Class] The template parse error class for JSON
      def template_parse_error_class
        TemplateParseError
      end

      # @return [Class] The destination parse error class for JSON
      def destination_parse_error_class
        DestinationParseError
      end

      private

      # JSON FileAnalysis only accepts signature_generator, not freeze_token
      def build_full_analysis_options
        {signature_generator: @signature_generator}
      end
    end
  end
end
