# frozen_string_literal: true

require "spec_helper"

# FileAnalysis specs with explicit backend testing
#
# This spec file tests FileAnalysis behavior across all available tree-sitter backends:
# - :mri (via ruby_tree_sitter gem, tagged :mri_backend)
# - :ffi (via FFI bindings, tagged :ffi_backend)
# - :rust (via tree_stump gem, tagged :rust_backend)
# - :java (via jtreesitter, tagged :java_backend)
#
# We define shared examples that are parameterized, then include them in
# backend-specific contexts that use TreeHaver.with_backend to explicitly
# select the backend under test.

RSpec.describe Json::Merge::FileAnalysis do
  describe "#feature_profile" do
    it "advertises the JSONC ruleset shape", :json_grammar do
      analysis = described_class.new("{\n  \"name\": \"value\" // comment\n}\n")
      profile = analysis.feature_profile

      expect(profile.owner_selector).to eq(:line_bound_statements)
      expect(profile.match_key).to eq(:signature)
      expect(profile.read_strategy).to eq(:source_augmented_portable_write)
      expect(profile.attachment_strategy).to eq(:augmenter_preferred_tracker_layout)
      expect(profile.comment_style).to eq(:c_style_line)
      expect(profile.render_family).to eq(:json_object_pairs)
      expect(profile.repair_policies).to eq([])
      expect(profile.surfaces).to eq([])
      expect(profile.delegation_policies).to eq([])
    end
  end

  # ============================================================
  # :auto backend tests (uses whatever is available)
  # This tests the default behavior most users will experience
  # ============================================================

  context "with :auto backend", :json_grammar do
    it_behaves_like "valid JSON parsing", expected_backend: :auto
    it_behaves_like "invalid JSON detection"
    it_behaves_like "root node access"
    it_behaves_like "root pairs extraction"
    it_behaves_like "line access"
    it_behaves_like "signature generation"
    it_behaves_like "custom signature generator"
    it_behaves_like "fallthrough_node? behavior"
    it_behaves_like "shared layout compliance"
    it_behaves_like "parser path handling"
    it_behaves_like "edge cases"
    it_behaves_like "integrate_nodes"
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

    it_behaves_like "valid JSON parsing", expected_backend: :mri
    it_behaves_like "invalid JSON detection"
    it_behaves_like "root node access"
    it_behaves_like "root pairs extraction"
    it_behaves_like "line access"
    it_behaves_like "signature generation"
    it_behaves_like "custom signature generator"
    it_behaves_like "fallthrough_node? behavior"
    it_behaves_like "shared layout compliance"
    it_behaves_like "parser path handling"
    it_behaves_like "edge cases"
    it_behaves_like "integrate_nodes"
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

    it_behaves_like "valid JSON parsing", expected_backend: :ffi
    it_behaves_like "invalid JSON detection"
    it_behaves_like "root node access"
    it_behaves_like "root pairs extraction"
    it_behaves_like "line access"
    it_behaves_like "signature generation"
    it_behaves_like "custom signature generator"
    it_behaves_like "fallthrough_node? behavior"
    it_behaves_like "shared layout compliance"
    it_behaves_like "parser path handling"
    it_behaves_like "edge cases"
    it_behaves_like "integrate_nodes"
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

    it_behaves_like "valid JSON parsing", expected_backend: :rust
    it_behaves_like "invalid JSON detection"
    it_behaves_like "root node access"
    it_behaves_like "root pairs extraction"
    it_behaves_like "line access"
    it_behaves_like "signature generation"
    it_behaves_like "custom signature generator"
    it_behaves_like "fallthrough_node? behavior"
    it_behaves_like "shared layout compliance"
    it_behaves_like "parser path handling"
    it_behaves_like "edge cases"
    it_behaves_like "integrate_nodes"
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

    it_behaves_like "valid JSON parsing", expected_backend: :java
    it_behaves_like "invalid JSON detection"
    it_behaves_like "root node access"
    it_behaves_like "root pairs extraction"
    it_behaves_like "line access"
    it_behaves_like "signature generation"
    it_behaves_like "custom signature generator"
    it_behaves_like "fallthrough_node? behavior"
    it_behaves_like "shared layout compliance"
    it_behaves_like "parser path handling"
    it_behaves_like "edge cases"
    it_behaves_like "integrate_nodes"
  end
end
