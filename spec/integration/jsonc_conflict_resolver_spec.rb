# frozen_string_literal: true

require "spec_helper"
require "json/merge"

RSpec.describe "Json::Merge JSONC conflict resolver", :json_grammar do
  describe Json::Merge::ConflictResolver do
    before do
      stub_const("AnalysisDouble", Struct.new(:lines, :comment_tracker) do
        def line_at(line_num)
          lines[line_num - 1]
        end

        def comment_region_for_range(range, kind:, full_line_only: false)
          comment_tracker.comment_region_for_range(range, kind: kind, full_line_only: full_line_only)
        end
      end)
    end

    def resolve_jsonc(template_source, destination_source, **options)
      template_analysis = Json::Merge::FileAnalysis.new(template_source)
      dest_analysis = Json::Merge::FileAnalysis.new(destination_source)

      expect(template_analysis).to be_valid
      expect(dest_analysis).to be_valid

      resolver = described_class.new(template_analysis, dest_analysis, **options)
      result = Json::Merge::MergeResult.new
      resolver.resolve(result)
      result.to_json
    end

    it "replays leading block comments when a matched template-preferred pair wins" do
      merged = resolve_jsonc(
        <<~JSON,
          {
            "shared": "template"
          }
        JSON
        <<~JSONC,
          {
            /* Shared docs */
            "shared": "destination" // destination inline
          }
        JSONC
        preference: :template,
      )

      expect(merged).to eq(<<~JSONC)
        {
          /* Shared docs */
          "shared": "template" // destination inline
        }
      JSONC
    end

    it "replays multi-line leading block comments without collapsing them" do
      merged = resolve_jsonc(
        <<~JSON,
          {
            "shared": "template"
          }
        JSON
        <<~JSONC,
          {
            /* Shared docs
             * spanning lines
             */
            "shared": "destination" // destination inline
          }
        JSONC
        preference: :template,
      )

      expect(merged).to eq(<<~JSONC)
        {
          /* Shared docs
           * spanning lines
           */
          "shared": "template" // destination inline
        }
      JSONC
    end

    it "promotes inline comments from removed containers using the opening line" do
      merged = resolve_jsonc(
        <<~JSON,
          {
            "keep": 1,
            "tail": 3
          }
        JSON
        <<~JSONC,
          {
            "keep": 1,
            "remove": { // remove inline
              "nested": true
            },
            "tail": 3
          }
        JSONC
        remove_template_missing_nodes: true,
      )

      expect(merged).to eq(<<~JSONC)
        {
          "keep": 1,
          // remove inline
          "tail": 3
        }
      JSONC
    end

    it "replays blank lines and full-line comments from trailing container ranges" do
      source = <<~JSONC
        {
          "config": {
            "keep": 9,

            // trailing destination note

          }
        }
      JSONC
      tracker = Json::Merge::CommentTracker.new(source)
      analysis = AnalysisDouble.new(source.lines.map(&:chomp), tracker)
      child = Struct.new(:start_line, :end_line).new(3, 3)
      container_node = double(
        "ContainerNode",
        container?: true,
        start_line: 2,
        end_line: 7,
        mergeable_children: [child],
      )
      resolver = described_class.new(double("TemplateAnalysis"), double("DestAnalysis"))

      expect(analysis).to receive(:comment_region_for_range)
        .with(4..6, kind: :trailing, full_line_only: true)
        .and_call_original

      resolver.send(:emit_container_trailing_lines, container_node, analysis)

      expect(resolver.instance_variable_get(:@emitter).lines).to eq([
        "",
        "    // trailing destination note",
        "",
      ])
    end

    it "compacts matched empty nested objects while keeping destination comments aligned" do
      merged = resolve_jsonc(
        <<~JSONC,
          {
            "features": {
              // comment from template
              "./apt-install": {}
            }
          }
        JSONC
        <<~JSONC,
          {
            "features": {
              // comment from destination
              "./apt-install": {
              }
            }
          }
        JSONC
        preference: :template,
      )

      expect(merged).to eq(<<~JSONC)
        {
          "features": {
            // comment from destination
            "./apt-install": {}
          }
        }
      JSONC
    end
  end
end
