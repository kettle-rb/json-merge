# frozen_string_literal: true

RSpec.describe Json::Merge::SmartMerger do
  let(:template_json) do
    <<~JSON
      {
        "name": "template-package",
        "version": "2.0.0",
        "description": "A template package",
        "dependencies": {
          "lodash": "^4.18.0"
        }
      }
    JSON
  end

  let(:dest_json) do
    <<~JSON
      {
        "name": "my-package",
        "version": "1.0.0",
        "dependencies": {
          "lodash": "^4.17.21",
          "express": "^4.18.0"
        },
        "custom": "my-value"
      }
    JSON
  end

  describe "#initialize" do
    it "creates a merger with content" do
      merger = described_class.new(template_json, dest_json)
      expect(merger.template_content).to eq(template_json)
      expect(merger.dest_content).to eq(dest_json)
    end

    it "accepts options" do
      merger = described_class.new(
        template_json,
        dest_json,
        preference: :template,
        add_template_only_nodes: true,
      )
      expect(merger.options[:preference]).to eq(:template)
      expect(merger.options[:add_template_only_nodes]).to be true
    end

    it "has default options" do
      merger = described_class.new(template_json, dest_json)
      expect(merger.options[:preference]).to eq(:destination)
      expect(merger.options[:add_template_only_nodes]).to be false
    end
  end

  describe "#merge", :tree_sitter_json do
    it "returns a MergeResult" do
      merger = described_class.new(template_json, dest_json)
      result = merger.merge_result
      expect(result).to be_a(Json::Merge::MergeResult)
    end

    it "produces a result with lines" do
      merger = described_class.new(template_json, dest_json)
      result = merger.merge_result
      expect(result).to respond_to(:lines)
    end

    it "preserves destination customizations by default" do
      merger = described_class.new(template_json, dest_json)
      result = merger.merge_result
      expect(result.to_json).to include("custom")
    end

    context "with template preference" do
      it "uses template values for matches" do
        merger = described_class.new(
          template_json,
          dest_json,
          preference: :template,
        )
        result = merger.merge_result
        expect(result).to be_a(Json::Merge::MergeResult)
      end
    end

    context "with add_template_only_nodes enabled" do
      it "adds template-only nodes" do
        merger = described_class.new(
          template_json,
          dest_json,
          add_template_only_nodes: true,
        )
        result = merger.merge_result
        expect(result.to_json).to include("description")
      end
    end
  end

  describe "error handling", :tree_sitter_json do
    it "raises TemplateParseError for invalid template" do
      expect {
        described_class.new("{ invalid", dest_json)
      }.to raise_error(Json::Merge::TemplateParseError)
    end

    it "raises DestinationParseError for invalid destination" do
      expect {
        described_class.new(template_json, "{ also invalid")
      }.to raise_error(Json::Merge::DestinationParseError)
    end

    it "includes error details in TemplateParseError" do
      expect {
        described_class.new("{ invalid json }", dest_json)
      }.to raise_error(Json::Merge::TemplateParseError) do |error|
        expect(error.message).to include("ERROR")
        expect(error.content).to eq("{ invalid json }")
      end
    end

    it "includes error details in DestinationParseError" do
      expect {
        described_class.new(template_json, "not json at all")
      }.to raise_error(Json::Merge::DestinationParseError) do |error|
        expect(error.message).to include("ERROR")
        expect(error.content).to eq("not json at all")
      end
    end
  end

  # Tests that run when tree-sitter-json is NOT available
  describe "without parser", :not_tree_sitter_json do
    it "handles missing parser gracefully" do
      merger = described_class.new(template_json, dest_json)
      expect(merger.template_analysis.valid?).to be false
    end
  end
end

