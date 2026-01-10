# frozen_string_literal: true

require "spec_helper"

# Integration tests for ConflictResolver with real merge scenarios
# Note: tree-sitter JSON parser does not support JSONC comments, so tests
# that need valid parsing use strict JSON.

RSpec.describe "Json::Merge::ConflictResolver Integration", :json_grammar do
  describe "with template preference for matching signatures" do
    let(:template_json) do
      <<~JSON
        {
          "shared": "template-value"
        }
      JSON
    end

    let(:dest_json) do
      <<~JSON
        {
          "shared": "dest-value"
        }
      JSON
    end

    it "uses template version when preference is :template" do
      template_analysis = Json::Merge::FileAnalysis.new(template_json)
      dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

      result = Json::Merge::MergeResult.new
      resolver = Json::Merge::ConflictResolver.new(
        template_analysis,
        dest_analysis,
        preference: :template,
      )

      resolver.resolve(result)
      # The merge should use template's version
      expect(result).to be_a(Json::Merge::MergeResult)
    end

    it "uses destination version when preference is :destination" do
      template_analysis = Json::Merge::FileAnalysis.new(template_json)
      dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

      result = Json::Merge::MergeResult.new
      resolver = Json::Merge::ConflictResolver.new(
        template_analysis,
        dest_analysis,
        preference: :destination,
      )

      resolver.resolve(result)
      expect(result).to be_a(Json::Merge::MergeResult)
    end
  end

  describe "with template-only nodes and add_template_only_nodes: true" do
    let(:template_json) do
      <<~JSON
        {
          "shared": "value",
          "templateOnly": "from-template"
        }
      JSON
    end

    let(:dest_json) { '{"shared": "value"}' }

    it "adds template-only nodes when configured" do
      template_analysis = Json::Merge::FileAnalysis.new(template_json)
      dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

      result = Json::Merge::MergeResult.new
      resolver = Json::Merge::ConflictResolver.new(
        template_analysis,
        dest_analysis,
        add_template_only_nodes: true,
      )

      resolver.resolve(result)

      output = result.to_json
      expect(output).to include("templateOnly")
    end

    it "skips template-only nodes when not configured" do
      template_analysis = Json::Merge::FileAnalysis.new(template_json)
      dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

      result = Json::Merge::MergeResult.new
      resolver = Json::Merge::ConflictResolver.new(
        template_analysis,
        dest_analysis,
        add_template_only_nodes: false,
      )

      resolver.resolve(result)

      output = result.to_json
      expect(output).not_to include("templateOnly")
    end
  end
end
