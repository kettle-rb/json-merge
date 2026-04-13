# frozen_string_literal: true

require "spec_helper"
require "json/merge"

RSpec.describe "Json::Merge JSONC file analysis behavior", :json_grammar do
  describe Json::Merge::FileAnalysis do
    it "supports custom freeze tokens in commented JSON input" do
      source = <<~JSONC
        {
          // custom-token:freeze
          "secret": true,
          // custom-token:unfreeze
          "visible": true
        }
      JSONC

      analysis = described_class.new(source, freeze_token: "custom-token")

      expect(analysis.freeze_blocks.size).to eq(1)
      expect(analysis.freeze_blocks.first.start_line).to eq(2)
      expect(analysis.freeze_blocks.first.end_line).to eq(4)
    end

    it "builds source-augmented comment capability, attachments, and postlude regions" do
      source = <<~JSONC
        // Header docs

        {
          "name": "test"
        }

        // Footer docs
      JSONC

      analysis = described_class.new(source)
      owner = analysis.statements.first
      augmenter = analysis.comment_augmenter
      attachment = augmenter.attachment_for(owner)

      expect(analysis.comment_capability).to be_a(Ast::Merge::Comment::Capability)
      expect(analysis.comment_capability.source_augmented?).to be true
      # Line-1 comment separated by a gap is preamble, not owned by the first node
      expect(attachment.leading_region).to be_nil
      expect(augmenter.preamble_region).not_to be_nil
      expect(augmenter.preamble_region.normalized_content).to eq("Header docs")
      expect(augmenter.postlude_region.normalized_content).to eq("Footer docs")
    end

    it "reports a source-augmented synthetic support style for JSONC comments" do
      analysis = described_class.new("// Header docs\n{}\n")

      expect(analysis.comment_support_style).to be_a(Ast::Merge::Comment::SupportStyle)
      expect(analysis.comment_support_style.source_augmented_synthetic?).to be true
      expect(analysis.comment_support_style.synthetic_write?).to be true
      expect(analysis.comment_support_style.details[:capability]).to eq(:source_augmented)
      expect(analysis.comment_support_style.details[:source]).to eq(:json_source)
      expect(analysis.comment_support_style.details[:style]).to eq(:c_style_line)
    end

    it "builds shared line comment nodes while leaving block comments out of the line-comment adapter" do
      line_analysis = described_class.new("// Header docs\n{}\n")
      block_analysis = described_class.new("/* Block docs */\n{}\n")

      expect(line_analysis.comment_nodes).not_to be_empty
      expect(line_analysis.comment_nodes.first).to be_a(Ast::Merge::Comment::Line)
      expect(line_analysis.comment_nodes.first.content).to eq("Header docs")
      expect(block_analysis.comment_nodes).to eq([])
      expect(block_analysis.comment_node_at(1)).to be_nil
    end

    it "includes a top-level array as a mergeable statement for JSONC sources" do
      analysis = described_class.new("[\n  // comment\n  1,\n  2\n]\n")

      expect(analysis).to be_valid
      expect(analysis.statements.size).to eq(1)
      expect(analysis.statements.first).to be_a(Json::Merge::NodeWrapper)
      expect(analysis.statements.first.array?).to be true
    end
  end
end
