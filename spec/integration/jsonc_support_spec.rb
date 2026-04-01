# frozen_string_literal: true

require "spec_helper"
require "json/merge"

RSpec.describe "Json::Merge JSONC support", :json_grammar do
  describe Json::Merge::FileAnalysis do
    it "parses commented JSON with the json grammar and exposes tracked comments" do
      source = <<~JSONC
        // prelude
        {
          // leading
          "name": "destination" // inline
        }
      JSONC

      analysis = described_class.new(source)

      expect(analysis).to be_valid
      expect(analysis.comment_tracker).to be_a(Json::Merge::CommentTracker)
      expect(analysis.comment_nodes.map(&:text)).to include("// prelude", "  // leading", "// inline")
      expect(analysis.root_pairs.map(&:key_name)).to eq(["name"])
    end

    it "detects comment-based freeze blocks" do
      source = <<~JSONC
        {
          // json-merge:freeze
          "secret": true,
          // json-merge:unfreeze
          "visible": true
        }
      JSONC

      analysis = described_class.new(source)
      freeze_blocks = analysis.statements.grep(Json::Merge::FreezeNode)

      expect(analysis).to be_valid
      expect(freeze_blocks.size).to eq(1)
      expect(freeze_blocks.first.start_line).to eq(2)
      expect(freeze_blocks.first.end_line).to eq(4)
    end
  end

  describe Json::Merge::SmartMerger do
    it "preserves document, leading, inline, and nested comments while merging JSONC input" do
      template = <<~JSONC
        {
          "name": "template",
          "nested": {
            "enabled": false,
            "added": true
          }
        }
      JSONC

      destination = <<~JSONC
        // prelude
        {
          // leading
          "name": "destination", // inline
          "nested": {
            // nested leading
            "enabled": true
          }
        }
        // postlude
      JSONC

      merged = described_class.new(
        template,
        destination,
        add_template_only_nodes: true,
      ).merge

      expect(merged).to include("// prelude")
      expect(merged).to include("// leading")
      expect(merged).to include("// inline")
      expect(merged).to include("// nested leading")
      expect(merged).to include("\"name\": \"destination\"")
      expect(merged).to include("\"added\": true")
      expect(merged).to include("// postlude")
    end

    it "promotes comments from removed destination-only nodes when removal mode is enabled" do
      template = <<~JSONC
        {
          "stay": 2
        }
      JSONC

      destination = <<~JSONC
        {
          // keep orphaned comment
          "obsolete": true,
          "stay": 1
        }
      JSONC

      merged = described_class.new(
        template,
        destination,
        preference: :template,
        remove_template_missing_nodes: true,
      ).merge

      expect(merged).to include("// keep orphaned comment")
      expect(merged).not_to include("\"obsolete\"")
      expect(merged).to include("\"stay\": 2")
    end
  end
end
