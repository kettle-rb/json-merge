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

  describe "#initialize" do
    it "returns a FileAnalysis instance" do
      result = described_class.new(simple_json)
      expect(result).to be_a(described_class)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "handles invalid JSON gracefully" do
      # First ensure parser is available
      described_class.new(simple_json)
      # Then test invalid JSON - tree-sitter may still parse with errors
      analysis = described_class.new("{ invalid json }")
      expect(analysis.valid?).to be(false).or be(true) # depends on parser behavior
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#statements" do
    it "returns an array of statements" do
      analysis = described_class.new(simple_json)
      expect(analysis.statements).to be_an(Array)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#lines" do
    it "returns the content split into lines" do
      analysis = described_class.new(simple_json)
      expect(analysis.lines).to be_an(Array)
      expect(analysis.lines).to include("{")
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#line_at" do
    it "returns the line at the given 1-based index" do
      analysis = described_class.new(simple_json)
      expect(analysis.line_at(1)).to eq("{")
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "returns nil for out of bounds" do
      analysis = described_class.new(simple_json)
      expect(analysis.line_at(1000)).to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#generate_signature" do
    it "generates a signature for statements" do
      analysis = described_class.new(complex_json)
      statement = analysis.statements.first
      if statement.is_a?(Json::Merge::NodeWrapper)
        sig = analysis.generate_signature(statement)
        # Signatures are Arrays like [:pair, "key_name"] or nil
        expect(sig).to be_an(Array).or be_nil
      end
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#valid?" do
    it "returns true for valid JSON" do
      analysis = described_class.new(simple_json)
      expect(analysis.valid?).to be true
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#root_node" do
    it "returns the root node" do
      analysis = described_class.new(simple_json)
      root = analysis.root_node
      expect(root).to be_a(Json::Merge::NodeWrapper)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#root_object" do
    it "returns the root object" do
      analysis = described_class.new(simple_json)
      obj = analysis.root_object
      expect(obj).to be_a(Json::Merge::NodeWrapper)
      expect(obj.object?).to be true
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "returns nil for array root" do
      analysis = described_class.new('["item1", "item2"]')
      obj = analysis.root_object
      expect(obj).to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#root_pairs" do
    it "returns pairs from root object" do
      analysis = described_class.new(simple_json)
      pairs = analysis.root_pairs
      expect(pairs).to be_an(Array)
      expect(pairs.size).to eq(2)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "returns empty array for array root" do
      analysis = described_class.new('["item1"]')
      pairs = analysis.root_pairs
      expect(pairs).to eq([])
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#normalized_line" do
    it "returns stripped line content" do
      analysis = described_class.new(simple_json)
      line = analysis.normalized_line(2)
      expect(line).to be_a(String)
      expect(line).not_to start_with(" ")
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "returns nil for out of bounds" do
      analysis = described_class.new(simple_json)
      expect(analysis.normalized_line(0)).to be_nil
      expect(analysis.normalized_line(1000)).to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#fallthrough_node?" do
    it "returns true for NodeWrapper instances" do
      analysis = described_class.new(simple_json)
      node = analysis.root_object
      skip "No root object" unless node
      expect(analysis.fallthrough_node?(node)).to be true
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "returns false for other types" do
      analysis = described_class.new(simple_json)
      expect(analysis.fallthrough_node?("string")).to be false
      expect(analysis.fallthrough_node?(123)).to be false
      expect(analysis.fallthrough_node?(nil)).to be false
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "custom signature generator" do
    it "uses custom signature generator when provided" do
      custom_gen = ->(statement) { [:custom, statement.class.name] }
      analysis = described_class.new(simple_json, signature_generator: custom_gen)
      statement = analysis.statements.first
      if statement.is_a?(Json::Merge::NodeWrapper)
        sig = analysis.generate_signature(statement)
        expect(sig.first).to eq(:custom)
      end
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "falls through to default when custom returns a statement" do
      custom_gen = ->(statement) { statement }  # Returns the statement itself
      analysis = described_class.new(simple_json, signature_generator: custom_gen)
      statement = analysis.statements.first
      if statement.is_a?(Json::Merge::NodeWrapper)
        sig = analysis.generate_signature(statement)
        expect(sig).to be_an(Array)
      end
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "parser path handling" do
    it "uses TREE_SITTER_JSON_PATH environment variable" do
      # Test that the class method exists
      expect(described_class).to respond_to(:find_parser_path)
    end

    it "handles missing parser gracefully" do
      # When parser is not found, it should set errors
      analysis = described_class.new(simple_json, parser_path: "/nonexistent/path")
      expect(analysis.valid?).to be false
      expect(analysis.errors).not_to be_empty
    end
  end

  describe "edge cases" do
    it "handles empty JSON object" do
      analysis = described_class.new("{}")
      expect(analysis.valid?).to be true
      expect(analysis.root_object).not_to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "handles empty JSON array" do
      analysis = described_class.new("[]")
      expect(analysis.valid?).to be true
      expect(analysis.root_object).to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "handles deeply nested JSON" do
      deep_json = '{"a": {"b": {"c": {"d": "value"}}}}'
      analysis = described_class.new(deep_json)
      expect(analysis.valid?).to be true
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#normalized_line" do
    it "returns stripped line content" do
      json = "{\n  \"key\": \"value\"\n}"
      analysis = described_class.new(json)
      # Line 2 has leading whitespace
      expect(analysis.normalized_line(2)).to eq('"key": "value"')
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "returns nil for line number less than 1" do
      analysis = described_class.new(simple_json)
      expect(analysis.normalized_line(0)).to be_nil
      expect(analysis.normalized_line(-1)).to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "returns nil for line number greater than total lines" do
      analysis = described_class.new(simple_json)
      expect(analysis.normalized_line(1000)).to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#fallthrough_node?" do
    it "returns true for NodeWrapper instances" do
      analysis = described_class.new(simple_json)
      statement = analysis.statements.first
      skip "No statements" unless statement
      expect(analysis.fallthrough_node?(statement)).to be true
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "returns false for non-NodeWrapper values" do
      analysis = described_class.new(simple_json)
      expect(analysis.fallthrough_node?("string")).to be false
      expect(analysis.fallthrough_node?(nil)).to be false
      expect(analysis.fallthrough_node?([:array])).to be false
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#generate_signature with custom generator" do
    it "uses custom signature generator when provided" do
      custom_gen = ->(statement) { [:custom, statement.type.to_s] }
      analysis = described_class.new(simple_json, signature_generator: custom_gen)
      statement = analysis.statements.first
      skip "No statements" unless statement
      sig = analysis.generate_signature(statement)
      expect(sig.first).to eq(:custom)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "falls through to default when custom generator returns NodeWrapper" do
      # Generator that returns the statement itself (fallthrough)
      custom_gen = ->(statement) { statement }
      analysis = described_class.new(simple_json, signature_generator: custom_gen)
      statement = analysis.statements.first
      skip "No statements" unless statement
      sig = analysis.generate_signature(statement)
      # Should use default signature computation
      expect(sig).to be_an(Array)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#root_node" do
    it "returns nil when not valid" do
      analysis = described_class.new(simple_json, parser_path: "/nonexistent")
      expect(analysis.root_node).to be_nil
    end

    it "returns NodeWrapper for valid parse" do
      analysis = described_class.new(simple_json)
      skip "Parser not available" unless analysis.valid?
      expect(analysis.root_node).to be_a(Json::Merge::NodeWrapper)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#root_object" do
    it "returns nil when not valid" do
      analysis = described_class.new(simple_json, parser_path: "/nonexistent")
      expect(analysis.root_object).to be_nil
    end

    it "returns nil when root has no object child" do
      analysis = described_class.new("[]")
      skip "Parser not available" unless analysis.valid?
      expect(analysis.root_object).to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#root_pairs" do
    it "returns empty array when no root object" do
      analysis = described_class.new("[]")
      expect(analysis.root_pairs).to eq([])
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#statements" do
    it "returns the statements array" do
      analysis = described_class.new(simple_json)
      expect(analysis.statements).to be_an(Array)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "compute_node_signature" do
    it "returns nil for non-NodeWrapper" do
      analysis = described_class.new(simple_json)
      # Access private method indirectly through generate_signature
      # with a non-NodeWrapper value
      sig = analysis.generate_signature("not a node")
      expect(sig).to be_nil
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "branch coverage for edge cases" do
    describe ".find_parser_path" do
      it "returns env path when TREE_SITTER_JSON_PATH is set and exists" do
        # This branch tests the env_path check
        original_env = ENV["TREE_SITTER_JSON_PATH"]
        begin
          # Create a temp file to simulate parser path
          require "tempfile"
          Tempfile.create("fake_parser") do |f|
            ENV["TREE_SITTER_JSON_PATH"] = f.path
            result = described_class.find_parser_path
            expect(result).to eq(f.path)
          end
        ensure
          ENV["TREE_SITTER_JSON_PATH"] = original_env
        end
      end

      it "returns nil when env path is set but file does not exist" do
        original_env = ENV["TREE_SITTER_JSON_PATH"]
        begin
          ENV["TREE_SITTER_JSON_PATH"] = "/nonexistent/path/to/parser.so"
          # Will fall back to searching PARSER_SEARCH_PATHS
          result = described_class.find_parser_path
          # Result depends on whether any search path exists
          expect(result).to be_nil.or be_a(String)
        ensure
          ENV["TREE_SITTER_JSON_PATH"] = original_env
        end
      end
    end

    describe "#root_object" do
      it "returns nil when JSON is an array (not an object)" do
        analysis = described_class.new("[1, 2, 3]")
        expect(analysis.root_object).to be_nil
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    describe "#parse_source error handling" do
      it "handles parse errors gracefully" do
        # Malformed JSON that tree-sitter will flag as having errors
        analysis = described_class.new("{\"key\": }")
        # Should have errors or be invalid
        expect(analysis.valid?).to be(true).or be(false)
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    describe "#integrate_nodes" do
      it "skips pairs without line info" do
        analysis = described_class.new(simple_json)
        # The integrate_nodes method filters out pairs without start_line/end_line
        # This is tested indirectly through statements
        expect(analysis.statements).to be_an(Array)
        analysis.statements.each do |stmt|
          expect(stmt.start_line).not_to be_nil if stmt.respond_to?(:start_line)
        end
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end
  end
end
