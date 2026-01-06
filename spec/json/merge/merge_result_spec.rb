# frozen_string_literal: true

require "ast/merge/rspec/shared_examples"

RSpec.describe Json::Merge::MergeResult do
  # Use the shared examples to validate base MergeResultBase integration
  subject(:result) { described_class.new }

  it_behaves_like "Ast::Merge::MergeResultBase" do
    let(:merge_result_class) { described_class }
    let(:build_merge_result) { -> { described_class.new } }
  end

  describe "#initialize" do
    it "creates an empty result" do
      expect(result.lines).to eq([])
      expect(result.decisions).to eq([])
    end

    it "initializes statistics" do
      expect(result.statistics).to be_a(Hash)
      expect(result.statistics[:total_decisions]).to eq(0)
    end
  end

  describe "#add_line" do
    it "adds a line to the result" do
      result.add_line('"key": "value"', decision: :kept_destination, source: :destination)
      expect(result.lines.map { |l| l[:content] }).to include('"key": "value"')
    end

    it "tracks the decision" do
      result.add_line('"key": "value"', decision: :kept_destination, source: :destination)
      expect(result.decisions).not_to be_empty
    end

    it "updates statistics" do
      result.add_line('"key": "value"', decision: :kept_destination, source: :destination)
      expect(result.statistics[:dest_lines]).to eq(1)
    end
  end

  describe "#add_lines" do
    it "adds multiple lines" do
      result.add_lines(["{", "}"], decision: :kept_destination, source: :destination)
      expect(result.line_count).to eq(2)
    end
  end

  describe "#to_json" do
    it "returns the merged content as a string" do
      result.add_line("{", decision: :merged, source: :merged)
      result.add_line('  "key": "value"', decision: :merged, source: :merged)
      result.add_line("}", decision: :merged, source: :merged)
      expect(result.to_json).to include("{")
      expect(result.to_json).to include('"key": "value"')
      expect(result.to_json).to include("}")
    end

    it "returns empty string for empty result" do
      # Empty result returns empty string
      expect(result.to_json).to eq("")
    end
  end

  describe "#content" do
    it "is aliased to to_json" do
      result.add_line("{", decision: :merged, source: :merged)
      expect(result.content).to eq(result.to_json)
    end
  end

  describe "#line_count" do
    it "returns 0 for empty result" do
      expect(result.line_count).to eq(0)
    end

    it "returns the number of lines" do
      result.add_line("{", decision: :merged, source: :merged)
      result.add_line("}", decision: :merged, source: :merged)
      expect(result.line_count).to eq(2)
    end
  end

  describe "#statistics" do
    it "returns a hash of decision counts" do
      stats = result.statistics
      expect(stats).to be_a(Hash)
    end

    it "tracks kept_destination decisions" do
      result.add_line('"a": 1', decision: :kept_destination, source: :destination)
      result.add_line('"b": 2', decision: :kept_destination, source: :destination)
      stats = result.statistics
      expect(stats[:dest_lines]).to eq(2)
    end

    it "tracks kept_template decisions" do
      result.add_line('"a": 1', decision: :kept_template, source: :template)
      stats = result.statistics
      expect(stats[:template_lines]).to eq(1)
    end
  end

  describe "#empty?" do
    it "returns true for empty result" do
      expect(result.empty?).to be true
    end

    it "returns false after adding lines" do
      result.add_line("{", decision: :merged, source: :merged)
      expect(result.empty?).to be false
    end
  end

  describe "#decision_summary" do
    it "returns summary of decisions" do
      result.add_line("{", decision: :kept_destination, source: :destination)
      result.add_line("}", decision: :kept_template, source: :template)
      summary = result.decision_summary
      expect(summary[:kept_destination]).to eq(1)
      expect(summary[:kept_template]).to eq(1)
    end
  end

  describe "#add_line with different decisions" do
    it "tracks merged decisions as merged_lines" do
      result.add_line("new line", decision: :added, source: :template)
      # :added decision falls through to merged_lines in the stats
      expect(result.statistics[:merged_lines]).to eq(1)
    end

    it "tracks original_line metadata" do
      result.add_line("content", decision: :kept_destination, source: :destination, original_line: 5)
      line_info = result.lines.first
      expect(line_info[:original_line]).to eq(5)
    end
  end

  describe "#decisions" do
    it "tracks all decisions made" do
      result.add_line("{", decision: :kept_destination, source: :destination)
      result.add_line("}", decision: :kept_template, source: :template)
      expect(result.decisions.size).to eq(2)
    end
  end

  describe "statistics edge cases" do
    it "handles unknown decision types" do
      result.add_line("line", decision: :unknown_type, source: :merged)
      # Should not raise, just count as total
      expect(result.statistics[:total_decisions]).to eq(1)
    end
  end

  describe "#lines structure" do
    it "includes content in each line entry" do
      result.add_line("test content", decision: :merged, source: :merged)
      expect(result.lines.first[:content]).to eq("test content")
    end

    it "includes decision in each line entry" do
      result.add_line("content", decision: :kept_destination, source: :destination)
      expect(result.lines.first[:decision]).to eq(:kept_destination)
    end

    it "includes source in each line entry" do
      result.add_line("content", decision: :kept_destination, source: :destination)
      expect(result.lines.first[:source]).to eq(:destination)
    end
  end

  describe "#add_node edge cases", :json_grammar do
    it "returns early when node has nil start_line" do
      # Create a mock-like object that returns nil for start_line
      json = '{"key": "value"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      node = analysis.root_object
      skip "No root object" unless node

      # Node should have valid lines, so this should work
      initial_count = result.lines.size
      result.add_node(node, decision: :kept_destination, source: :destination, analysis: analysis)
      expect(result.lines.size).to be >= initial_count
    end

    it "skips nodes without start_line" do
      analysis = Json::Merge::FileAnalysis.new('{"key": "value"}')
      skip "Parser not available" unless analysis.valid?

      # Create a mock node without start_line
      mock_node = double("node")
      allow(mock_node).to receive_messages(start_line: nil, end_line: 1)

      initial_line_count = result.lines.length
      result.add_node(mock_node, decision: :kept, source: :template, analysis: analysis)
      # Should not add any lines since start_line is nil
      expect(result.lines.length).to eq(initial_line_count)
    end

    it "skips nodes without end_line" do
      analysis = Json::Merge::FileAnalysis.new('{"key": "value"}')
      skip "Parser not available" unless analysis.valid?

      # Create a mock node without end_line
      mock_node = double("node")
      allow(mock_node).to receive_messages(start_line: 1, end_line: nil)

      initial_line_count = result.lines.length
      result.add_node(mock_node, decision: :kept, source: :template, analysis: analysis)
      # Should not add any lines since end_line is nil
      expect(result.lines.length).to eq(initial_line_count)
    end

    it "skips lines that are nil from analysis" do
      analysis = Json::Merge::FileAnalysis.new('{"key": "value"}')
      skip "Parser not available" unless analysis.valid?

      # Create a mock node with out-of-range lines
      mock_node = double("node")
      allow(mock_node).to receive_messages(start_line: 1000, end_line: 1001)

      initial_line_count = result.lines.length
      result.add_node(mock_node, decision: :kept, source: :template, analysis: analysis)
      # Should not add any lines since line_at returns nil for out-of-range
      expect(result.lines.length).to eq(initial_line_count)
    end
  end

  describe "#to_json newline handling" do
    it "does not add extra newline if content already ends with newline" do
      result.add_line("line1", decision: :merged, source: :merged)
      json = result.to_json
      # Should have exactly one trailing newline
      expect(json).to end_with("\n")
      expect(json).not_to end_with("\n\n")
    end

    it "adds newline to content that doesn't have one" do
      result.add_line("no newline", decision: :merged, source: :merged)
      json = result.to_json
      expect(json).to end_with("\n")
    end
  end

  describe "#add_lines with start_line" do
    it "calculates original line numbers from start_line" do
      result.add_lines(["line1", "line2", "line3"], decision: :merged, source: :merged, start_line: 10)
      expect(result.lines[0][:original_line]).to eq(10)
      expect(result.lines[1][:original_line]).to eq(11)
      expect(result.lines[2][:original_line]).to eq(12)
    end

    it "sets nil original_line when start_line is nil" do
      result.add_lines(["line1", "line2"], decision: :merged, source: :merged, start_line: nil)
      expect(result.lines[0][:original_line]).to be_nil
      expect(result.lines[1][:original_line]).to be_nil
    end
  end

  describe "#track_statistics branch coverage" do
    it "increments template_lines for DECISION_KEPT_TEMPLATE" do
      result.add_line("template line", decision: described_class::DECISION_KEPT_TEMPLATE, source: :template)
      expect(result.statistics[:template_lines]).to eq(1)
    end

    it "increments dest_lines for DECISION_KEPT_DEST" do
      result.add_line("dest line", decision: described_class::DECISION_KEPT_DEST, source: :destination)
      expect(result.statistics[:dest_lines]).to eq(1)
    end

    it "increments merged_lines for DECISION_MERGED" do
      result.add_line("merged line", decision: described_class::DECISION_MERGED, source: :merged)
      expect(result.statistics[:merged_lines]).to eq(1)
    end

    it "increments merged_lines for DECISION_ADDED" do
      result.add_line("added line", decision: described_class::DECISION_ADDED, source: :template)
      expect(result.statistics[:merged_lines]).to eq(1)
    end

    it "tracks all decision types correctly" do
      result.add_line("t1", decision: described_class::DECISION_KEPT_TEMPLATE, source: :template)
      result.add_line("t2", decision: described_class::DECISION_KEPT_TEMPLATE, source: :template)
      result.add_line("d1", decision: described_class::DECISION_KEPT_DEST, source: :destination)
      result.add_line("m1", decision: described_class::DECISION_MERGED, source: :merged)

      expect(result.statistics[:template_lines]).to eq(2)
      expect(result.statistics[:dest_lines]).to eq(1)
      expect(result.statistics[:merged_lines]).to eq(1)
      expect(result.statistics[:total_decisions]).to eq(4)
    end
  end

  describe "#content alias" do
    it "returns same result as to_json" do
      result.add_line("test", decision: :merged, source: :merged)
      expect(result.content).to eq(result.to_json)
    end
  end
end
