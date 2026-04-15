# frozen_string_literal: true

require "spec_helper"
require "ast/merge/rspec/shared_examples"

# SmartMerger specs with explicit backend testing
#
# This spec file tests SmartMerger behavior across all available tree-sitter backends:
# - :mri (via ruby_tree_sitter gem, tagged :mri_backend)
# - :ffi (via FFI bindings, tagged :ffi_backend)
# - :rust (via tree_stump gem, tagged :rust_backend)
# - :java (via jtreesitter, tagged :java_backend)
#
# We define shared examples that are parameterized, then include them in
# backend-specific contexts.

RSpec.describe Json::Merge::SmartMerger do
  # ============================================================
  # :auto backend tests (uses whatever is available)
  # ============================================================

  context "with :auto backend", :json_grammar do
    it_behaves_like "basic initialization"
    it_behaves_like "basic merge operation"
    it_behaves_like "template preference"
    it_behaves_like "add template-only nodes"
    it_behaves_like "destination-only nodes preservation"
    it_behaves_like "invalid template detection"
    it_behaves_like "invalid destination detection"
    it_behaves_like "multi-byte character (emoji) handling"
  end

  # ============================================================
  # Backend-aware tests - MRI/ruby_tree_sitter
  # ============================================================

  context "with MRI backend", :json_grammar, :mri_backend do
    around do |example|
      TreeHaver.with_backend(:mri) do
        example.run
      end
    end

    it_behaves_like "basic initialization"
    it_behaves_like "basic merge operation"
    it_behaves_like "template preference"
    it_behaves_like "add template-only nodes"
    it_behaves_like "destination-only nodes preservation"
    it_behaves_like "invalid template detection"
    it_behaves_like "invalid destination detection"
    it_behaves_like "multi-byte character (emoji) handling"
  end

  # ============================================================
  # Backend-aware tests - FFI
  # ============================================================

  context "with FFI backend", :ffi_backend, :json_grammar do
    around do |example|
      TreeHaver.with_backend(:ffi) do
        example.run
      end
    end

    it_behaves_like "basic initialization"
    it_behaves_like "basic merge operation"
    it_behaves_like "template preference"
    it_behaves_like "add template-only nodes"
    it_behaves_like "destination-only nodes preservation"
    it_behaves_like "invalid template detection"
    it_behaves_like "invalid destination detection"
    it_behaves_like "multi-byte character (emoji) handling"
  end

  # ============================================================
  # Backend-aware tests - Rust/tree_stump
  # ============================================================

  context "with Rust backend", :json_grammar, :rust_backend do
    around do |example|
      TreeHaver.with_backend(:rust) do
        example.run
      end
    end

    it_behaves_like "basic initialization"
    it_behaves_like "basic merge operation"
    it_behaves_like "template preference"
    it_behaves_like "add template-only nodes"
    it_behaves_like "destination-only nodes preservation"
    it_behaves_like "invalid template detection"
    it_behaves_like "invalid destination detection"
    it_behaves_like "multi-byte character (emoji) handling"
  end

  # ============================================================
  # Backend-aware tests - Java/jtreesitter
  # ============================================================

  context "with Java backend", :java_backend, :json_grammar do
    around do |example|
      TreeHaver.with_backend(:java) do
        example.run
      end
    end

    it_behaves_like "basic initialization"
    it_behaves_like "basic merge operation"
    it_behaves_like "template preference"
    it_behaves_like "add template-only nodes"
    it_behaves_like "destination-only nodes preservation"
    it_behaves_like "invalid template detection"
    it_behaves_like "invalid destination detection"
    it_behaves_like "multi-byte character (emoji) handling"
  end

  describe "duplicate template preamble healing", :json_grammar, :mri_backend do
    around do |example|
      TreeHaver.with_backend(:mri) do
        example.run
      end
    end

    let(:template_content) do
      <<~JSON
        {
          // Shared header

          "alpha": 1
        }
      JSON
    end

    let(:destination_content) do
      <<~JSON
        {
          // Shared header
          // Shared header
          // Destination header
          "alpha": 9
        }
      JSON
    end

    it "collapses the duplicated template prefix in heal mode" do
      merged = described_class.new(
        template_content,
        destination_content,
        add_template_only_nodes: true,
      ).merge

      expect(merged.scan("Shared header").size).to eq(0)
      expect(merged.scan("Destination header").size).to eq(1)
      expect(merged).to include('"alpha": 9')
    end

    it "preserves the duplicated prefix in skip mode" do
      merged = described_class.new(
        template_content,
        destination_content,
        add_template_only_nodes: true,
        corruption_handling: :skip,
      ).merge

      expect(merged.scan("Shared header").size).to eq(2)
      expect(merged.scan("Destination header").size).to eq(1)
    end

    it "warns and preserves the duplicated prefix in warn mode" do
      allow(Json::Merge::DebugLogger).to receive(:debug_warning)

      merged = described_class.new(
        template_content,
        destination_content,
        add_template_only_nodes: true,
        corruption_handling: :warn,
      ).merge

      expect(Json::Merge::DebugLogger).to have_received(:debug_warning).with(
        /Suspected corruption \(duplicate_template_preamble_prefix\)/,
        hash_including(template_comment_lines: 1, merged_comment_lines: 3, destination_specific_comment_lines: 1),
      )
      expect(merged.scan("Shared header").size).to eq(2)
    end

    it "raises in error mode" do
      expect {
        described_class.new(
          template_content,
          destination_content,
          add_template_only_nodes: true,
          corruption_handling: :error,
        ).merge
      }.to raise_error(Json::Merge::CorruptionDetectedError, /duplicate_template_preamble_prefix/)
    end
  end

  describe "#merge_with_debug", :json_grammar do
    let(:runtime_debug_merger) do
      described_class.new(
        <<~JSON,
          {
            "name": "template",
            "enabled": true
          }
        JSON
        <<~JSON
          {
            "name": "destination",
            "enabled": true
          }
        JSON
      )
    end

    it_behaves_like "Ast::Merge::RuntimeDebugContract"

    it "returns runtime-aware debug information" do
      debug_result = runtime_debug_merger.merge_with_debug

      expect(debug_result).to include(
        :content,
        :debug,
        :runtime,
        :statistics,
        :decisions,
        :template_analysis,
        :dest_analysis,
      )
      expect(debug_result.dig(:runtime, :summary, :operation_count)).to eq(1)
      expect(debug_result.dig(:runtime, :operation_trees, 0, :surface, :surface_kind)).to eq(:json_document)
      expect(debug_result.dig(:runtime, :operation_trees, 0, :delegate_name)).to eq("json-runtime")
      expect(debug_result.dig(:debug, :corruption_handling)).to eq(:heal)
      expect(runtime_debug_merger.options[:corruption_handling]).to eq(:heal)
    end
  end
end
