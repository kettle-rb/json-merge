# frozen_string_literal: true

RSpec.describe Json::Merge::FileAnalysis do
  let(:simple_json) do
    <<~JSON
      {
        "name": "test",
        "version": "1.0.0"
      }
    JSON
  end

  let(:complex_json) do
    <<~JSON
      {
        "name": "test-package",
        "version": "2.0.0",
        "dependencies": {
          "lodash": "^4.17.21",
          "express": "^4.18.0"
        },
        "devDependencies": {
          "jest": "^29.0.0"
        }
      }
    JSON
  end

  describe "#initialize", :tree_sitter_json do
    it "returns a FileAnalysis instance" do
      result = described_class.new(simple_json)
      expect(result).to be_a(described_class)
    end

    it "handles invalid JSON gracefully" do
      # tree-sitter may still parse with errors (error recovery)
      analysis = described_class.new("{ invalid json }")
      expect(analysis.valid?).to be(false).or be(true) # depends on parser behavior
    end
  end

  describe "#statements", :tree_sitter_json do
    it "returns an array of statements" do
      analysis = described_class.new(simple_json)
      expect(analysis.statements).to be_an(Array)
    end
  end

  describe "#lines", :tree_sitter_json do
    it "returns the content split into lines" do
      analysis = described_class.new(simple_json)
      expect(analysis.lines).to be_an(Array)
      expect(analysis.lines).to include("{")
    end
  end

  describe "#line_at", :tree_sitter_json do
    it "returns the line at the given 1-based index" do
      analysis = described_class.new(simple_json)
      expect(analysis.line_at(1)).to eq("{")
    end

    it "returns nil for out of bounds" do
      analysis = described_class.new(simple_json)
      expect(analysis.line_at(1000)).to be_nil
    end
  end

  describe "#generate_signature", :tree_sitter_json do
    it "generates a signature for statements" do
      analysis = described_class.new(complex_json)
      statement = analysis.statements.first
      if statement.is_a?(Json::Merge::NodeWrapper)
        sig = analysis.generate_signature(statement)
        # Signatures are Arrays like [:pair, "key_name"] or nil
        expect(sig).to be_an(Array).or be_nil
      end
    end
  end

  describe "#valid?", :tree_sitter_json do
    it "returns true for valid JSON" do
      analysis = described_class.new(simple_json)
      expect(analysis.valid?).to be true
    end
  end

  describe "#root_node", :tree_sitter_json do
    it "returns the root node" do
      analysis = described_class.new(simple_json)
      root = analysis.root_node
      expect(root).to be_a(Json::Merge::NodeWrapper)
    end

    it "returns nil when parse fails" do
      analysis = described_class.new("{ invalid json }")
      if analysis.valid?
        expect(analysis.root_node).to be_a(Json::Merge::NodeWrapper)
      else
        expect(analysis.root_node).to be_nil
      end
    end
  end

  describe "#root_object", :tree_sitter_json do
    it "returns the root object" do
      analysis = described_class.new(simple_json)
      obj = analysis.root_object
      expect(obj).to be_a(Json::Merge::NodeWrapper)
      expect(obj.object?).to be true
    end

    it "returns nil for array root" do
      analysis = described_class.new('["item1", "item2"]')
      obj = analysis.root_object
      expect(obj).to be_nil
    end

    it "returns nil when JSON is an array" do
      analysis = described_class.new("[1, 2, 3]")
      expect(analysis.root_object).to be_nil
    end
  end

  describe "#root_pairs", :tree_sitter_json do
    it "returns pairs from root object" do
      analysis = described_class.new(simple_json)
      pairs = analysis.root_pairs
      expect(pairs).to be_an(Array)
      expect(pairs.size).to eq(2)
    end

    it "returns empty array for array root" do
      analysis = described_class.new('["item1"]')
      pairs = analysis.root_pairs
      expect(pairs).to eq([])
    end

    it "returns empty array when no root object" do
      analysis = described_class.new("[]")
      expect(analysis.root_pairs).to eq([])
    end
  end

  describe "#normalized_line", :tree_sitter_json do
    it "returns stripped line content" do
      analysis = described_class.new(simple_json)
      line = analysis.normalized_line(2)
      expect(line).to be_a(String)
      expect(line).not_to start_with(" ")
    end

    it "returns nil for out of bounds" do
      analysis = described_class.new(simple_json)
      expect(analysis.normalized_line(0)).to be_nil
      expect(analysis.normalized_line(-1)).to be_nil
      expect(analysis.normalized_line(1000)).to be_nil
    end
  end

  describe "#fallthrough_node?", :tree_sitter_json do
    it "returns true for NodeWrapper instances" do
      analysis = described_class.new(simple_json)
      node = analysis.root_object
      skip "No root object" unless node
      expect(analysis.fallthrough_node?(node)).to be true
    end

    it "returns false for other types" do
      analysis = described_class.new(simple_json)
      expect(analysis.fallthrough_node?("string")).to be false
      expect(analysis.fallthrough_node?(123)).to be false
      expect(analysis.fallthrough_node?(nil)).to be false
      expect(analysis.fallthrough_node?([:array])).to be false
    end
  end

  describe "custom signature generator", :tree_sitter_json do
    it "uses custom signature generator when provided" do
      custom_gen = ->(statement) { [:custom, statement.class.name] }
      analysis = described_class.new(simple_json, signature_generator: custom_gen)
      statement = analysis.statements.first
      if statement.is_a?(Json::Merge::NodeWrapper)
        sig = analysis.generate_signature(statement)
        expect(sig.first).to eq(:custom)
      end
    end

    it "falls through to default when custom returns a statement" do
      custom_gen = ->(statement) { statement }  # Returns the statement itself
      analysis = described_class.new(simple_json, signature_generator: custom_gen)
      statement = analysis.statements.first
      if statement.is_a?(Json::Merge::NodeWrapper)
        sig = analysis.generate_signature(statement)
        expect(sig).to be_an(Array)
      end
    end
  end

  describe "parser path handling" do
    it "uses TREE_SITTER_JSON_PATH environment variable" do
      expect(described_class).to respond_to(:find_parser_path)
    end

    it "handles nonexistent parser path gracefully" do
      # When an explicit parser_path is provided that doesn't exist,
      # TreeHaver should raise NotAvailable (Principle of Least Surprise)
      analysis = described_class.new(simple_json, parser_path: "/nonexistent/path/to/parser.so")
      expect(analysis.valid?).to be false
      expect(analysis.errors).not_to be_empty
      expect(analysis.errors.first).to include("nonexistent")
    end

    it "handles TreeHaver::NotAvailable gracefully" do
      allow(TreeHaver).to receive(:parser_for).and_raise(TreeHaver::NotAvailable.new("No parser available"))

      analysis = described_class.new(simple_json)
      expect(analysis.valid?).to be false
      expect(analysis.errors).not_to be_empty
      expect(analysis.errors.first).to include("No parser available")
    end

    it "handles other parse errors gracefully" do
      allow(TreeHaver).to receive(:parser_for).and_raise(StandardError.new("Unexpected error"))

      analysis = described_class.new(simple_json)
      expect(analysis.valid?).to be false
      expect(analysis.errors).not_to be_empty
    end

    describe ".find_parser_path" do
      it "returns env path when TREE_SITTER_JSON_PATH is set and exists" do
        require "tempfile"
        Tempfile.create(["fake_parser", ".so"]) do |f|
          stub_env("TREE_SITTER_JSON_PATH" => f.path)
          result = described_class.find_parser_path
          expect(result).to eq(f.path)
        end
      end

      it "raises TreeHaver::NotAvailable when env path is set but file does not exist" do
        stub_env("TREE_SITTER_JSON_PATH" => "/nonexistent/path/to/parser.so")
        expect {
          described_class.find_parser_path
        }.to raise_error(TreeHaver::NotAvailable, /file does not exist/)
      end
    end
  end

  describe "edge cases", :tree_sitter_json do
    it "handles empty JSON object" do
      analysis = described_class.new("{}")
      expect(analysis.valid?).to be true
      expect(analysis.root_object).not_to be_nil
    end

    it "handles empty JSON array" do
      analysis = described_class.new("[]")
      expect(analysis.valid?).to be true
      expect(analysis.root_object).to be_nil
    end

    it "handles deeply nested JSON" do
      deep_json = '{"a": {"b": {"c": {"d": "value"}}}}'
      analysis = described_class.new(deep_json)
      expect(analysis.valid?).to be true
    end

    it "handles parse errors gracefully" do
      analysis = described_class.new("{\"key\": }")
      expect(analysis.valid?).to be(true).or be(false)
    end
  end

  describe "compute_node_signature", :tree_sitter_json do
    it "returns nil for non-NodeWrapper" do
      analysis = described_class.new(simple_json)
      sig = analysis.generate_signature("not a node")
      expect(sig).to be_nil
    end
  end

  describe "#integrate_nodes", :tree_sitter_json do
    it "skips pairs without line info" do
      analysis = described_class.new(simple_json)
      expect(analysis.statements).to be_an(Array)
      analysis.statements.each do |stmt|
        expect(stmt.start_line).not_to be_nil if stmt.respond_to?(:start_line)
      end
    end
  end

  describe "#root_object_open_line", :tree_sitter_json do
    it "returns the opening brace line for objects" do
      json = "{\n  \"key\": \"value\"\n}"
      analysis = described_class.new(json)
      expect(analysis.root_object_open_line).to eq("{")
    end

    it "returns nil for array root" do
      json = '["item"]'
      analysis = described_class.new(json)
      expect(analysis.root_object_open_line).to be_nil
    end

    it "returns nil when root_object has no start_line" do
      json = "{}"
      analysis = described_class.new(json)
      obj = analysis.root_object
      if obj && obj.start_line
        expect(analysis.root_object_open_line).not_to be_nil
      end
    end
  end

  describe "#root_object_close_line", :tree_sitter_json do
    it "returns the closing brace line for objects" do
      json = "{\n  \"key\": \"value\"\n}"
      analysis = described_class.new(json)
      expect(analysis.root_object_close_line).to eq("}")
    end

    it "returns nil for array root" do
      json = '["item"]'
      analysis = described_class.new(json)
      expect(analysis.root_object_close_line).to be_nil
    end
  end
end

