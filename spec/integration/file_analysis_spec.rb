# frozen_string_literal: true

# Integration tests for FileAnalysis with real JSON parsing scenarios

RSpec.describe "Json::Merge::FileAnalysis Integration", :json_grammar do
  describe "with valid JSON" do
    let(:json_content) do
      <<~JSON
        {
          "name": "test",
          "version": "1.0.0"
        }
      JSON
    end

    it "parses JSON content" do
      analysis = Json::Merge::FileAnalysis.new(json_content)
      expect(analysis).to be_a(Json::Merge::FileAnalysis)
      expect(analysis.valid?).to be true
    end
  end

  describe "with custom signature generator" do
    let(:json_content) { '{"name": "test", "version": "1.0.0"}' }

    it "uses custom signature generator" do
      custom_sig_called = false
      custom_generator = ->(stmt) {
        custom_sig_called = true
        [:custom, stmt.class.name]
      }

      analysis = Json::Merge::FileAnalysis.new(
        json_content,
        signature_generator: custom_generator,
      )

      expect(analysis.valid?).to be(true)
      expect(analysis.statements).not_to be_empty

      # Generate signature for first statement to trigger custom generator
      analysis.statements.each do |statement|
        analysis.generate_signature(statement)
      end

      expect(custom_sig_called).to be true
    end

    it "falls through when custom generator returns a statement" do
      # Generator returns a statement, which triggers fallthrough to compute_node_signature
      fallthrough_generator = ->(statement) { statement }

      analysis = Json::Merge::FileAnalysis.new(
        json_content,
        signature_generator: fallthrough_generator,
      )

      expect(analysis.valid?).to be(true)

      analysis.statements.each do |statement|
        sig = analysis.generate_signature(statement)
        # Should compute signature via fallthrough
        expect(sig).not_to be_nil if statement.is_a?(Json::Merge::NodeWrapper)
      end
    end
  end

  describe "#normalized_line" do
    let(:json_content) { "{\n  \"key\": \"value\"\n}" }

    it "returns stripped line content" do
      analysis = Json::Merge::FileAnalysis.new(json_content)
      expect(analysis.normalized_line(2)).to eq('"key": "value"')
    end

    it "returns nil for invalid line numbers" do
      analysis = Json::Merge::FileAnalysis.new(json_content)
      expect(analysis.normalized_line(0)).to be_nil
      expect(analysis.normalized_line(100)).to be_nil
    end
  end

  describe "#root_node and #root_object" do
    let(:object_json) { '{"key": "value"}' }
    let(:array_json) { '["item1", "item2"]' }

    it "returns root_node for valid JSON" do
      analysis = Json::Merge::FileAnalysis.new(object_json)
      expect(analysis.valid?).to be(true)
      expect(analysis.root_node).to be_a(Json::Merge::NodeWrapper)
    end

    it "returns root_object for object JSON" do
      analysis = Json::Merge::FileAnalysis.new(object_json)
      expect(analysis.valid?).to be(true)
      root_obj = analysis.root_object
      expect(root_obj).to be_a(Json::Merge::NodeWrapper)
      expect(root_obj.object?).to be true
    end

    it "returns nil root_object for array JSON" do
      analysis = Json::Merge::FileAnalysis.new(array_json)
      expect(analysis.valid?).to be(true)
      # root_object looks for an object node, array JSON doesn't have one at root
      expect(analysis.root_object).to be_nil
    end
  end

  describe "#root_pairs" do
    let(:json_content) { '{"a": 1, "b": 2}' }

    it "returns key-value pairs from root object" do
      analysis = Json::Merge::FileAnalysis.new(json_content)
      expect(analysis.valid?).to be(true)
      pairs = analysis.root_pairs
      expect(pairs).to be_an(Array)
    end

    it "returns empty array when no root object" do
      analysis = Json::Merge::FileAnalysis.new('["item"]')
      expect(analysis.valid?).to be(true)
      expect(analysis.root_pairs).to eq([])
    end
  end
end
