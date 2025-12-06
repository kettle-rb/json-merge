# frozen_string_literal: true

require "ast/merge/rspec/shared_examples"

RSpec.describe Json::Merge::DebugLogger do
  # Use the shared examples to validate base DebugLogger integration
  it_behaves_like "Ast::Merge::DebugLogger" do
    let(:described_logger) { described_class }
    let(:env_var_name) { "JSON_MERGE_DEBUG" }
    let(:log_prefix) { "[Json::Merge]" }
  end

  describe "JSON-specific functionality" do
    describe ".time" do
      it "returns the block result" do
        result = described_class.time("test") { 42 }
        expect(result).to eq(42)
      end

      context "when enabled" do
        it "outputs timing information" do
          stub_env("JSON_MERGE_DEBUG" => "1")
          expect { described_class.time("test operation") { sleep(0.001) } }.to output(/Completed: test operation.*real_ms/).to_stderr
        end
      end
    end

    describe ".log_node" do
      context "when enabled" do
        it "logs NodeWrapper info" do
          stub_env("JSON_MERGE_DEBUG" => "1")
          json = '{"key": "value"}'
          analysis = Json::Merge::FileAnalysis.new(json)
          statement = analysis.statements.first

          if statement.is_a?(Json::Merge::NodeWrapper)
            expect {
              described_class.log_node(statement, label: "TestWrapper")
            }.to output(/TestWrapper/).to_stderr
          end
        end

        it "logs unknown node type info using extract_node_info" do
          stub_env("JSON_MERGE_DEBUG" => "1")
          unknown_node = Object.new

          expect {
            described_class.log_node(unknown_node, label: "TestUnknown")
          }.to output(/TestUnknown/).to_stderr
        end
      end

      context "when disabled" do
        it "does not output anything" do
          # Don't stub JSON_MERGE_DEBUG - it defaults to disabled
          unknown_node = Object.new

          expect {
            described_class.log_node(unknown_node, label: "Test")
          }.not_to output.to_stderr
        end
      end
    end
  end
end
