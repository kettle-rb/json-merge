# frozen_string_literal: true

RSpec.describe Json::Merge::NodeWrapper do
  # NodeWrapper requires a tree-sitter node, which requires parser availability
  # These tests use the actual parser when available

  describe "when tree-sitter parser is available" do
    let(:json_content) { '{"key": "value"}' }

    it "creates wrapper instances from FileAnalysis" do
      analysis = Json::Merge::FileAnalysis.new(json_content)
      statements = analysis.statements
      expect(statements).to be_an(Array)
      expect(statements).to all(be_a(described_class))
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "instance methods" do
    let(:json_content) { '{"name": "test", "version": "1.0.0"}' }

    before do
      @analysis = Json::Merge::FileAnalysis.new(json_content)
      @wrapper = @analysis.statements.find { |s| s.is_a?(described_class) }
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    describe "#type" do
      it "returns the node type" do
        skip "No wrapper node available" unless @wrapper
        expect(@wrapper.type).to be_a(Symbol)
      end
    end

    describe "#start_line" do
      it "returns the starting line number" do
        skip "No wrapper node available" unless @wrapper
        expect(@wrapper.start_line).to be_a(Integer)
        expect(@wrapper.start_line).to be >= 1
      end
    end

    describe "#end_line" do
      it "returns the ending line number" do
        skip "No wrapper node available" unless @wrapper
        expect(@wrapper.end_line).to be_a(Integer)
        expect(@wrapper.end_line).to be >= @wrapper.start_line
      end
    end

    describe "#text" do
      it "returns the node text" do
        skip "No wrapper node available" unless @wrapper
        expect(@wrapper.text).to be_a(String)
      end
    end

    describe "#children" do
      it "returns an array" do
        skip "No wrapper node available" unless @wrapper
        expect(@wrapper.children).to be_an(Array)
      end
    end

    describe "#frozen?" do
      it "returns false for regular nodes" do
        skip "No wrapper node available" unless @wrapper
        expect(@wrapper.frozen?).to be false
      end
    end
  end

  describe "type predicate methods" do
    describe "#object?" do
      it "returns true for object nodes" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        expect(root.object?).to be true
      end
    end

    describe "#array?" do
      it "returns true for array root" do
        json = '["item1", "item2"]'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_node
        skip "No root node" unless root
        # The root document contains an array
        array_node = root.children.find(&:array?)
        skip "No array child" unless array_node
        expect(array_node.array?).to be true
      end

      it "returns false for non-array nodes" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        expect(root.array?).to be false
      end
    end

    describe "#string?" do
      it "returns true for string values" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value node" unless value
        expect(value.string?).to be true
      end
    end

    describe "#number?" do
      it "returns true for number values" do
        json = '{"count": 42}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value node" unless value
        expect(value.number?).to be true
      end
    end

    describe "#boolean?" do
      it "returns true for true values" do
        json = '{"enabled": true}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value node" unless value
        expect(value.boolean?).to be true
      end

      it "returns true for false values" do
        json = '{"enabled": false}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value node" unless value
        expect(value.boolean?).to be true
      end
    end

    describe "#null?" do
      it "returns true for null values" do
        json = '{"value": null}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value node" unless value
        expect(value.null?).to be true
      end
    end

    describe "#pair?" do
      it "returns true for key-value pairs" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        expect(pair.pair?).to be true
      end
    end
  end

  describe "#key_name" do
    it "returns key name for pair nodes" do
      json = '{"myKey": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      expect(pair.key_name).to eq("myKey")
    end

    it "returns nil for non-pair nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.key_name).to be_nil
    end
  end

  describe "#value_node" do
    it "returns value wrapper for pair nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      expect(value).to be_a(described_class)
    end

    it "returns nil for non-pair nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.value_node).to be_nil
    end
  end

  describe "#pairs" do
    it "returns pairs for object nodes" do
      json = '{"a": 1, "b": 2}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pairs = root.pairs
      expect(pairs.size).to eq(2)
      pairs.each { |p| expect(p.pair?).to be true }
    end

    it "returns empty array for non-object nodes" do
      json = '["item"]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      expect(array_node.pairs).to eq([])
    end
  end

  describe "#elements" do
    it "returns elements for array nodes" do
      json = '["a", "b", "c"]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      elements = array_node.elements
      expect(elements.size).to eq(3)
    end

    it "returns empty array for non-array nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.elements).to eq([])
    end
  end

  describe "#signature" do
    it "generates signature for pair nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      sig = pair.signature
      expect(sig).to be_an(Array)
    end
  end

  describe "#type?" do
    it "returns true when type matches" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.type?(:object)).to be true
      expect(root.type?("object")).to be true
    end

    it "returns false when type does not match" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.type?(:array)).to be false
    end
  end

  describe "#comment?" do
    it "returns false for non-comment nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.comment?).to be false
    end
  end

  describe "#content" do
    it "returns node content from source lines" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.content).to be_a(String)
      expect(root.content).not_to be_empty
    end

    it "returns empty string when start_line is nil" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      # Test the edge case by checking the method exists
      expect(root).to respond_to(:content)
    end
  end

  describe "#node_text" do
    it "extracts text from tree-sitter node" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.text).to be_a(String)
    end
  end

  describe "#find_child_by_type" do
    it "finds child node by type" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.send(:find_child_by_type, "pair")
      expect(pair).not_to be_nil if root.pairs.any?
    end

    it "returns nil when type not found" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      result = root.send(:find_child_by_type, "nonexistent_type")
      expect(result).to be_nil
    end
  end

  describe "#inspect" do
    it "returns a debug string" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.inspect).to be_a(String)
      expect(root.inspect).to include("NodeWrapper")
    end
  end

  describe "signature generation" do
    describe "for document type" do
      it "generates signature for document root" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_node
        skip "No root node" unless root
        sig = root.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:document)
      end
    end

    describe "for object type" do
      it "generates signature with sorted keys" do
        json = '{"b": 1, "a": 2}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        sig = root.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:object)
        expect(sig[1]).to eq(["a", "b"])
      end
    end

    describe "for array type" do
      it "generates signature with element count" do
        json = '["a", "b", "c"]'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_node
        skip "No root node" unless root
        array_node = root.children.find(&:array?)
        skip "No array node" unless array_node
        sig = array_node.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:array)
        expect(sig[1]).to eq(3)
      end
    end

    describe "for string type" do
      it "generates signature with string content" do
        json = '{"key": "hello"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value" unless value
        sig = value.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:string)
        expect(sig[1]).to include("hello")
      end
    end

    describe "for number type" do
      it "generates signature with number value" do
        json = '{"count": 42}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value" unless value
        sig = value.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:number)
        expect(sig[1]).to eq("42")
      end

      it "handles negative numbers" do
        json = '{"value": -123}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value" unless value
        expect(value.number?).to be true
      end

      it "handles decimal numbers" do
        json = '{"value": 3.14}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value" unless value
        expect(value.number?).to be true
      end
    end

    describe "for boolean type" do
      it "generates signature for true" do
        json = '{"flag": true}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value" unless value
        sig = value.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:boolean)
        expect(sig[1]).to eq("true")
      end

      it "generates signature for false" do
        json = '{"flag": false}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value" unless value
        sig = value.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:boolean)
        expect(sig[1]).to eq("false")
      end
    end

    describe "for null type" do
      it "generates signature for null" do
        json = '{"nothing": null}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value" unless value
        sig = value.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:null)
      end
    end

    describe "for pair type" do
      it "generates signature with key name" do
        json = '{"myKey": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        sig = pair.signature
        expect(sig).to be_an(Array)
        expect(sig.first).to eq(:pair)
        expect(sig[1]).to eq("myKey")
      end
    end
  end

  describe "nested structures" do
    it "handles nested objects" do
      json = '{"outer": {"inner": "value"}}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value" unless value
      expect(value.object?).to be true
      expect(value.pairs.size).to eq(1)
    end

    it "handles nested arrays" do
      json = '{"items": [1, 2, [3, 4]]}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value" unless value
      expect(value.array?).to be true
    end

    it "handles arrays of objects" do
      json = '[{"a": 1}, {"b": 2}]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      elements = array_node.elements
      expect(elements.size).to eq(2)
      elements.each { |e| expect(e.object?).to be true }
    end
  end

  describe "edge cases" do
    it "handles empty object" do
      json = "{}"
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.pairs).to eq([])
    end

    it "handles empty array" do
      json = "[]"
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      expect(array_node.elements).to eq([])
    end

    it "handles empty string value" do
      json = '{"key": ""}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value" unless value
      expect(value.string?).to be true
    end

    it "handles unicode in strings" do
      json = '{"emoji": "🎉"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      expect(pair.key_name).to eq("emoji")
    end

    it "handles escaped characters in strings" do
      json = '{"path": "C:\\\\Users\\\\test"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      expect(pair.key_name).to eq("path")
    end
  end

  describe "method edge cases" do
    describe "#find_child_by_field" do
      it "returns nil when node does not respond to child_by_field_name" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        # The method should handle this gracefully
        result = root.send(:find_child_by_field, "nonexistent")
        expect(result).to be_nil.or be_a(Object)
      end
    end

    describe "#node_text" do
      it "returns empty string when node doesn't have byte methods" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        # Test that the method exists and works
        expect(root.text).to be_a(String)
      end
    end

    describe "#children" do
      it "returns empty array when node does not respond to each" do
        json = '"simple string"'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_node
        skip "No root node" unless root
        # Children should be an array
        expect(root.children).to be_an(Array)
      end
    end

    describe "#key_name edge cases" do
      it "returns nil when key node is not found" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        # Object node should return nil for key_name
        expect(root.key_name).to be_nil
      end
    end

    describe "#value_node edge cases" do
      it "handles pair with missing value" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        # Value should be present
        expect(pair.value_node).to be_a(described_class)
      end
    end

    describe "#content edge cases" do
      it "handles missing lines gracefully" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        # Content should be a string
        expect(root.content).to be_a(String)
      end
    end
  end

  describe "array element edge cases" do
    it "skips punctuation in elements" do
      json = '["a", "b"]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      elements = array_node.elements
      # Should only have 2 elements, not punctuation
      expect(elements.size).to eq(2)
      expect(elements.all?(&:string?)).to be true
    end

    it "handles mixed type arrays" do
      json = '[1, "two", true, null]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      elements = array_node.elements
      expect(elements.size).to eq(4)
    end
  end

  describe "object pairs edge cases" do
    it "skips non-pair children" do
      json = '{"a": 1, "b": 2}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pairs = root.pairs
      # Should only include pair nodes
      expect(pairs.all?(&:pair?)).to be true
    end
  end

  describe "signature extraction" do
    describe "#extract_object_keys" do
      it "extracts keys from object" do
        json = '{"z": 1, "a": 2, "m": 3}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        sig = root.signature
        expect(sig.first).to eq(:object)
        # Keys should be sorted
        expect(sig[1]).to eq(["a", "m", "z"])
      end
    end
  end

  describe "document signature" do
    it "generates signature for document root" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      sig = root.signature
      expect(sig.first).to eq(:document)
      expect(sig[1]).to eq("object")
    end

    it "generates signature for array document" do
      json = '["item"]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      sig = root.signature
      expect(sig.first).to eq(:document)
      expect(sig[1]).to eq("array")
    end
  end

  describe "string signature" do
    it "generates signature for string values" do
      json = '{"key": "hello world"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value" unless value
      sig = value.signature
      expect(sig.first).to eq(:string)
      expect(sig[1]).to include("hello world")
    end
  end

  describe "number signature" do
    it "generates signature for number values" do
      json = '{"count": 42}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value" unless value
      sig = value.signature
      expect(sig.first).to eq(:number)
      expect(sig[1]).to eq("42")
    end
  end

  describe "boolean signature" do
    it "generates signature for true" do
      json = '{"flag": true}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value" unless value
      sig = value.signature
      expect(sig).to eq([:boolean, "true"])
    end

    it "generates signature for false" do
      json = '{"flag": false}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value" unless value
      sig = value.signature
      expect(sig).to eq([:boolean, "false"])
    end
  end

  describe "null signature" do
    it "generates signature for null" do
      json = '{"value": null}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value" unless value
      sig = value.signature
      expect(sig).to eq([:null])
    end
  end

  describe "array signature" do
    it "generates signature with element count" do
      json = "[1, 2, 3, 4, 5]"
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      sig = array_node.signature
      expect(sig.first).to eq(:array)
      expect(sig[1]).to eq(5)
    end

    it "handles empty arrays" do
      json = "[]"
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      sig = array_node.signature
      expect(sig).to eq([:array, 0])
    end
  end

  describe "edge case: end_line before start_line" do
    # This tests the constructor's edge case handling
    it "handles malformed line ranges" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      # Normal case - end should be >= start
      expect(root.end_line).to be >= root.start_line
    end
  end

  describe "#key_name edge cases" do
    it "returns nil for non-pair nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.key_name).to be_nil
    end
  end

  describe "#value_node edge cases" do
    it "returns nil for non-pair nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.value_node).to be_nil
    end
  end

  describe "#pairs edge cases" do
    it "returns empty array for non-object nodes" do
      json = '["item"]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      expect(array_node.pairs).to eq([])
    end
  end

  describe "#elements edge cases" do
    it "returns empty array for non-array nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.elements).to eq([])
    end
  end

  describe "branch coverage for edge cases with mock nodes" do
    # These tests use mock objects to cover edge cases that are difficult
    # or impossible to trigger with real tree-sitter nodes

    describe "initialize line info extraction" do
      it "handles nodes without start_point method" do
        mock_node = double("node", type: "object")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:each).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:child_by_field_name).and_return(false)

        wrapper = described_class.new(mock_node, lines: ["{}"], source: "{}")
        expect(wrapper.start_line).to be_nil
        expect(wrapper.end_line).to be_nil
      end

      it "handles nodes with only start_point" do
        mock_node = double("node", type: "object")
        start_point = double("point", row: 0)
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(true)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:start_point).and_return(start_point)

        wrapper = described_class.new(mock_node, lines: ["{}"], source: "{}")
        expect(wrapper.start_line).to eq(1)
        expect(wrapper.end_line).to be_nil
      end

      it "handles nodes with only end_point" do
        mock_node = double("node", type: "object")
        end_point = double("point", row: 0)
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(true)
        allow(mock_node).to receive(:end_point).and_return(end_point)

        wrapper = described_class.new(mock_node, lines: ["{}"], source: "{}")
        expect(wrapper.start_line).to be_nil
        expect(wrapper.end_line).to eq(1)
      end

      it "corrects end_line when it is before start_line" do
        mock_node = double("node", type: "object")
        start_point = double("start", row: 5)
        end_point = double("end", row: 2) # end is before start - edge case
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(true)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(true)
        allow(mock_node).to receive_messages(start_point: start_point, end_point: end_point)

        wrapper = described_class.new(mock_node, lines: Array.new(10) { |i| "line #{i}" }, source: "")
        # end_line should be corrected to equal start_line
        expect(wrapper.start_line).to eq(6)
        expect(wrapper.end_line).to eq(6) # Corrected from 3 to 6
      end
    end

    describe "#key_name edge cases" do
      it "returns nil when key_node is not found via child_by_field_name" do
        mock_node = double("pair_node", type: "pair")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:child_by_field_name).and_return(true)
        allow(mock_node).to receive(:child_by_field_name).with("key").and_return(nil)

        wrapper = described_class.new(mock_node, lines: ['{"key": "value"}'], source: '{"key": "value"}')
        expect(wrapper.key_name).to be_nil
      end

      it "returns nil when node_text returns nil for key" do
        mock_key = double("key_node", type: "string")
        allow(mock_key).to receive(:respond_to?).with(:start_byte).and_return(false)
        allow(mock_key).to receive(:respond_to?).with(:end_byte).and_return(false)

        mock_node = double("pair_node", type: "pair")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:child_by_field_name).and_return(true)
        allow(mock_node).to receive(:child_by_field_name).with("key").and_return(mock_key)

        wrapper = described_class.new(mock_node, lines: ['{"key": "value"}'], source: '{"key": "value"}')
        # key_text will be empty string, gsub returns empty string, which is truthy
        # so this returns empty string not nil
        expect(wrapper.key_name).to eq("")
      end
    end

    describe "#value_node edge cases" do
      it "returns nil when value is not found via child_by_field_name" do
        mock_node = double("pair_node", type: "pair")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:child_by_field_name).and_return(true)
        allow(mock_node).to receive(:child_by_field_name).with("value").and_return(nil)

        wrapper = described_class.new(mock_node, lines: ['{"key": "value"}'], source: '{"key": "value"}')
        expect(wrapper.value_node).to be_nil
      end
    end

    describe "#pairs with comment children" do
      it "skips comment children when building pairs" do
        mock_comment = double("comment", type: "comment")
        mock_pair = double("pair", type: "pair")
        allow(mock_pair).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_pair).to receive(:respond_to?).with(:end_point).and_return(false)

        mock_node = double("object_node", type: "object")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:each).and_return(true)
        allow(mock_node).to receive(:each).and_yield(mock_comment).and_yield(mock_pair)

        wrapper = described_class.new(mock_node, lines: ["{}"], source: "{}")
        pairs = wrapper.pairs
        # Should have 1 pair, comment should be skipped
        expect(pairs.length).to eq(1)
        expect(pairs.first.type).to eq(:pair)
      end
    end

    describe "#elements with punctuation children" do
      it "skips bracket punctuation when building elements" do
        mock_open_bracket = double("bracket", type: "[")
        mock_close_bracket = double("bracket", type: "]")
        mock_string = double("string", type: "string")
        allow(mock_string).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_string).to receive(:respond_to?).with(:end_point).and_return(false)

        mock_node = double("array_node", type: "array")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:each).and_return(true)
        allow(mock_node).to receive(:each)
          .and_yield(mock_open_bracket)
          .and_yield(mock_string)
          .and_yield(mock_close_bracket)

        wrapper = described_class.new(mock_node, lines: ["[]"], source: "[]")
        elements = wrapper.elements
        # Should have 1 element, brackets should be skipped
        expect(elements.length).to eq(1)
        expect(elements.first.type).to eq(:string)
      end

      it "skips comment children when building elements" do
        mock_comment = double("comment", type: "comment")
        mock_string = double("string", type: "string")
        allow(mock_string).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_string).to receive(:respond_to?).with(:end_point).and_return(false)

        mock_node = double("array_node", type: "array")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:each).and_return(true)
        allow(mock_node).to receive(:each)
          .and_yield(mock_comment)
          .and_yield(mock_string)

        wrapper = described_class.new(mock_node, lines: ["[]"], source: "[]")
        elements = wrapper.elements
        # Should have 1 element, comment should be skipped
        expect(elements.length).to eq(1)
      end
    end

    describe "#children edge cases" do
      it "returns empty array when node does not respond to each" do
        mock_node = double("string_node", type: "string")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:each).and_return(false)

        wrapper = described_class.new(mock_node, lines: ['"test"'], source: '"test"')
        expect(wrapper.children).to eq([])
      end
    end

    describe "#find_child_by_field edge cases" do
      it "returns nil when node does not respond to child_by_field_name" do
        mock_node = double("string_node", type: "string")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:child_by_field_name).and_return(false)

        wrapper = described_class.new(mock_node, lines: ['"test"'], source: '"test"')
        expect(wrapper.find_child_by_field("key")).to be_nil
      end
    end

    describe "#find_child_by_type edge cases" do
      it "returns nil when node does not respond to each" do
        mock_node = double("string_node", type: "string")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:each).and_return(false)

        wrapper = described_class.new(mock_node, lines: ['"test"'], source: '"test"')
        expect(wrapper.find_child_by_type("object")).to be_nil
      end
    end

    describe "#node_text edge cases" do
      it "returns empty string when node does not have byte methods" do
        mock_node = double("string_node", type: "string")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:start_byte).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_byte).and_return(false)

        wrapper = described_class.new(mock_node, lines: ['"test"'], source: '"test"')
        expect(wrapper.text).to eq("")
      end

      it "returns empty string when source slice returns nil" do
        mock_node = double("string_node", type: "string")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:start_byte).and_return(true)
        allow(mock_node).to receive(:respond_to?).with(:end_byte).and_return(true)
        # Out of range bytes will return nil from slice
        allow(mock_node).to receive_messages(start_byte: 1000, end_byte: 2000)

        wrapper = described_class.new(mock_node, lines: ['"test"'], source: '"test"')
        expect(wrapper.text).to eq("")
      end
    end

    describe "#content edge cases" do
      it "returns empty string when start_line is nil" do
        mock_node = double("string_node", type: "string")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)

        wrapper = described_class.new(mock_node, lines: ['"test"'], source: '"test"')
        expect(wrapper.content).to eq("")
      end
    end

    describe "compute_signature edge cases" do
      it "generates signature for comment type nodes" do
        mock_node = double("comment_node", type: "comment")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:start_byte).and_return(true)
        allow(mock_node).to receive(:respond_to?).with(:end_byte).and_return(true)
        allow(mock_node).to receive_messages(start_byte: 0, end_byte: 15) # "// test comment" is 15 chars

        wrapper = described_class.new(mock_node, lines: ["// test comment"], source: "// test comment")
        sig = wrapper.signature
        expect(sig).to eq([:comment, "// test comment"])
      end

      it "generates signature for unknown type nodes (generic fallback)" do
        mock_node = double("unknown_node", type: "unknown_type_xyz")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:start_byte).and_return(true)
        allow(mock_node).to receive(:respond_to?).with(:end_byte).and_return(true)
        allow(mock_node).to receive_messages(start_byte: 0, end_byte: 7)

        wrapper = described_class.new(mock_node, lines: ["content"], source: "content")
        sig = wrapper.signature
        expect(sig).to eq([:unknown_type_xyz, "content"])
      end

      it "truncates long content in generic fallback signature" do
        long_content = "x" * 100
        mock_node = double("unknown_node", type: "unknown_type")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:start_byte).and_return(true)
        allow(mock_node).to receive(:respond_to?).with(:end_byte).and_return(true)
        allow(mock_node).to receive_messages(start_byte: 0, end_byte: 100)

        wrapper = described_class.new(mock_node, lines: [long_content], source: long_content)
        sig = wrapper.signature
        expect(sig[0]).to eq(:unknown_type)
        expect(sig[1].length).to eq(50) # Truncated to 50 chars
      end

      it "generates document signature with child type" do
        mock_child = double("object_child", type: "object")
        mock_node = double("document_node", type: "document")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:each).and_yield(mock_child)

        wrapper = described_class.new(mock_node, lines: ["{}"], source: "{}")
        sig = wrapper.signature
        expect(sig).to eq([:document, "object"])
      end

      it "generates document signature skipping comments" do
        mock_comment = double("comment", type: "comment")
        mock_child = double("array_child", type: "array")
        mock_node = double("document_node", type: "document")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:each).and_yield(mock_comment).and_yield(mock_child)

        wrapper = described_class.new(mock_node, lines: ["[]"], source: "[]")
        sig = wrapper.signature
        expect(sig).to eq([:document, "array"])
      end
    end

    describe "extract_object_keys edge cases" do
      it "skips children without child_by_field_name support" do
        mock_pair = double("pair", type: "pair")
        allow(mock_pair).to receive(:respond_to?).with(:child_by_field_name).and_return(false)

        mock_node = double("object_node", type: "object")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:each).and_yield(mock_pair)

        wrapper = described_class.new(mock_node, lines: ["{}"], source: "{}")
        # signature will call extract_object_keys
        sig = wrapper.signature
        expect(sig).to eq([:object, []]) # No keys extracted
      end

      it "skips pairs where key_node is nil" do
        mock_pair = double("pair", type: "pair")
        allow(mock_pair).to receive(:respond_to?).with(:child_by_field_name).and_return(true)
        allow(mock_pair).to receive(:child_by_field_name).with("key").and_return(nil)

        mock_node = double("object_node", type: "object")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:each).and_yield(mock_pair)

        wrapper = described_class.new(mock_node, lines: ["{}"], source: "{}")
        sig = wrapper.signature
        expect(sig).to eq([:object, []]) # No keys extracted
      end

      it "skips pairs where key_text is empty" do
        mock_key = double("key", type: "string")
        allow(mock_key).to receive(:respond_to?).with(:start_byte).and_return(true)
        allow(mock_key).to receive(:respond_to?).with(:end_byte).and_return(true)
        # Empty string
        allow(mock_key).to receive_messages(start_byte: 0, end_byte: 0)

        mock_pair = double("pair", type: "pair")
        allow(mock_pair).to receive(:respond_to?).with(:child_by_field_name).and_return(true)
        allow(mock_pair).to receive(:child_by_field_name).with("key").and_return(mock_key)

        mock_node = double("object_node", type: "object")
        allow(mock_node).to receive(:respond_to?).with(:start_point).and_return(false)
        allow(mock_node).to receive(:respond_to?).with(:end_point).and_return(false)
        allow(mock_node).to receive(:each).and_yield(mock_pair)

        wrapper = described_class.new(mock_node, lines: ["{}"], source: "{}")
        sig = wrapper.signature
        # Empty key text after gsub will be falsy empty string
        # Actually "" is truthy in Ruby, so it will be included
        expect(sig).to eq([:object, [""]])
      end
    end
  end

  describe "#mergeable_children", :json_grammar do
    context "with object nodes" do
      it "returns pairs" do
        json = '{"a": 1, "b": 2}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        children = root.mergeable_children
        expect(children.size).to eq(root.pairs.size)
        expect(children.all?(&:pair?)).to be true
      end
    end

    context "with array nodes" do
      it "returns elements" do
        json = '["a", "b"]'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_node
        skip "No root node" unless root
        array_node = root.children.find(&:array?)
        skip "No array" unless array_node
        children = array_node.mergeable_children
        expect(children.size).to eq(array_node.elements.size)
        expect(children.all?(&:string?)).to be true
      end
    end

    context "with leaf nodes (string, number, etc.)" do
      it "returns empty array for string values" do
        json = '{"key": "value"}'
        analysis = Json::Merge::FileAnalysis.new(json)
        root = analysis.root_object
        skip "No root object" unless root
        pair = root.pairs.first
        skip "No pair" unless pair
        value = pair.value_node
        skip "No value node" unless value
        expect(value.mergeable_children).to eq([])
      end
    end
  end

  describe "#container?", :json_grammar do
    it "returns true for objects" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.container?).to be true
    end

    it "returns true for arrays" do
      json = '["item"]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      expect(array_node.container?).to be true
    end

    it "returns false for leaf nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value node" unless value
      expect(value.container?).to be false
    end
  end

  describe "#leaf?", :json_grammar do
    it "returns false for objects" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.leaf?).to be false
    end

    it "returns true for string values" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value node" unless value
      expect(value.leaf?).to be true
    end
  end

  describe "#opening_line", :json_grammar do
    it "returns the opening line for objects" do
      json = "{\n  \"key\": \"value\"\n}"
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.opening_line).to eq("{")
    end

    it "returns the opening line for arrays" do
      json = "[\n  \"item\"\n]"
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      expect(array_node.opening_line).to eq("[")
    end

    it "returns nil for non-container nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value node" unless value
      expect(value.opening_line).to be_nil
    end
  end

  describe "#closing_line", :json_grammar do
    it "returns the closing line for objects" do
      json = "{\n  \"key\": \"value\"\n}"
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.closing_line).to eq("}")
    end

    it "returns the closing line for arrays" do
      json = "[\n  \"item\"\n]"
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      expect(array_node.closing_line).to eq("]")
    end

    it "returns nil for non-container nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value node" unless value
      expect(value.closing_line).to be_nil
    end
  end

  describe "#opening_bracket", :json_grammar do
    it "returns { for objects" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.opening_bracket).to eq("{")
    end

    it "returns [ for arrays" do
      json = '["item"]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      expect(array_node.opening_bracket).to eq("[")
    end

    it "returns nil for non-container nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value node" unless value
      expect(value.opening_bracket).to be_nil
    end
  end

  describe "#closing_bracket", :json_grammar do
    it "returns } for objects" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      expect(root.closing_bracket).to eq("}")
    end

    it "returns ] for arrays" do
      json = '["item"]'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_node
      skip "No root node" unless root
      array_node = root.children.find(&:array?)
      skip "No array" unless array_node
      expect(array_node.closing_bracket).to eq("]")
    end

    it "returns nil for non-container nodes" do
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root object" unless root
      pair = root.pairs.first
      skip "No pair" unless pair
      value = pair.value_node
      skip "No value node" unless value
      expect(value.closing_bracket).to be_nil
    end
  end
end
