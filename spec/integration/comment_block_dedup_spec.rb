# frozen_string_literal: true

require "spec_helper"
require "json"
require "json/merge"

RSpec.describe "Json::Merge bidirectional comment block deduplication", :json_grammar do
  describe Json::Merge::SmartMerger do
    context "when a floating comment block is attached to different nodes in template vs destination" do
      # Simulates the same bug pattern as prism-merge gemspec dedup:
      # A positional comment block (gap-separated from its owner node)
      # gets greedily attached to different nodes in template vs dest
      # because the dest has an extra node between the comment and the
      # node the template attaches it to.
      let(:template) do
        <<~JSONC
          {
            "alpha": "one",

            // NOTE: This is a floating positional comment block
            // that documents the development dependencies below.
            "gamma": "three"
          }
        JSONC
      end

      let(:destination) do
        <<~JSONC
          {
            "alpha": "one",

            // NOTE: This is a floating positional comment block
            // that documents the development dependencies below.
            "beta": "two",
            "gamma": "three"
          }
        JSONC
      end

      it "does not duplicate the floating comment block" do
        merged = described_class.new(template, destination).merge
        occurrences = merged.scan("NOTE: This is a floating positional comment block").size
        expect(occurrences).to eq(1), "Expected 1 occurrence of floating comment block, got #{occurrences}.\nMerged output:\n#{merged}"
      end

      it "does not duplicate with preference: :template" do
        merged = described_class.new(template, destination, preference: :template).merge
        occurrences = merged.scan("NOTE: This is a floating positional comment block").size
        expect(occurrences).to eq(1), "Expected 1 occurrence of floating comment block, got #{occurrences}.\nMerged output:\n#{merged}"
      end

      it "does not duplicate with preference: :destination" do
        merged = described_class.new(template, destination, preference: :destination).merge
        occurrences = merged.scan("NOTE: This is a floating positional comment block").size
        expect(occurrences).to eq(1), "Expected 1 occurrence of floating comment block, got #{occurrences}.\nMerged output:\n#{merged}"
      end

      it "preserves all data nodes from both sources" do
        merged = described_class.new(template, destination).merge
        expect(merged).to include('"alpha"')
        expect(merged).to include('"beta"')
        expect(merged).to include('"gamma"')
      end
    end

    context "when both template and dest have identical leading comments on the same matched key" do
      let(:template) do
        <<~JSONC
          {
            // Config section
            "config": {
              "debug": true
            }
          }
        JSONC
      end

      let(:destination) do
        <<~JSONC
          {
            // Config section
            "config": {
              "debug": false,
              "verbose": true
            }
          }
        JSONC
      end

      it "emits the comment only once" do
        merged = described_class.new(template, destination).merge
        occurrences = merged.scan("// Config section").size
        expect(occurrences).to eq(1), "Expected 1 occurrence of '// Config section', got #{occurrences}.\nMerged output:\n#{merged}"
      end
    end
  end
end
