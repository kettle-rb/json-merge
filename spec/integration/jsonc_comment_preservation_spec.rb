# frozen_string_literal: true

require "spec_helper"
require "json"
require "json/merge"

RSpec.describe "Json::Merge JSONC comment preservation", :json_grammar do
  describe Json::Merge::SmartMerger do
    it "preserves destination header and footer comments around a root object merge" do
      template = <<~JSON
        {
          "name": "template"
        }
      JSON
      destination = <<~JSONC
        // Destination header

        {
          "name": "destination"
        }

        // Destination footer
      JSONC

      merged = described_class.new(template, destination).merge

      expect(merged).to include("// Destination header")
      expect(merged).to include("// Destination footer")
      expect(merged).to include("// Destination header\n\n{")
      expect(merged).to end_with("}\n\n// Destination footer\n")
    end

    it "preserves destination header and footer comments around a root array merge" do
      template = <<~JSON
        [
          1,
          2
        ]
      JSON
      destination = <<~JSONC
        // Destination header

        [
          9,
          8
        ]

        // Destination footer
      JSONC

      merged = described_class.new(template, destination).merge

      expect(merged).to include("// Destination header")
      expect(merged).to include("// Destination footer")
      expect(merged).to include("// Destination header\n\n[")
      expect(merged).to end_with("]\n\n// Destination footer\n")
    end

    it "preserves a comment-only destination when no structural nodes exist" do
      template = <<~JSON
        {
          "name": "template"
        }
      JSON
      destination = <<~JSONC
        // Destination docs

        // More destination docs
      JSONC

      merged = described_class.new(template, destination).merge

      expect(merged).to eq(destination)
    end

    it "preserves destination leading and inline comments when a matched template-preferred pair wins" do
      template = <<~JSON
        {
          "keep": 1,
          "shared": "template"
        }
      JSON
      destination = <<~JSONC
        {
          "keep": 1,
          // Shared docs
          "shared": "destination" // destination inline
        }
      JSONC

      merged = described_class.new(template, destination, preference: :template).merge

      expect(merged).to include("// Shared docs")
      expect(merged).to include('"shared": "template" // destination inline')
      json_without_comments = merged.gsub(%r{//.*$}, "")
      expect { JSON.parse(json_without_comments) }.not_to raise_error
    end

    it "preserves comments for removed destination-only pairs when removal is enabled" do
      template = <<~JSON
        {
          "keep": 1,
          "tail": 3
        }
      JSON
      destination = <<~JSONC
        {
          "keep": 1,
          // Remove docs
          "remove": 2, // remove inline
          "tail": 3
        }
      JSONC

      merged = described_class.new(
        template,
        destination,
        remove_template_missing_nodes: true,
      ).merge

      expect(merged).to include("// Remove docs")
      expect(merged).to include("// remove inline")
      expect(merged).not_to include('"remove": 2')
    end

    it "keeps commas before inline comments when nested template-preferred pairs win" do
      template = <<~JSON
        {
          "config": {
            "keep": 1,
            "add": 2
          }
        }
      JSON
      destination = <<~JSONC
        {
          "config": {
            // Keep docs
            "keep": 9 // keep inline
          }
        }
      JSONC

      merged = described_class.new(
        template,
        destination,
        preference: :template,
        add_template_only_nodes: true,
      ).merge

      expect(merged).to include('"keep": 1, // keep inline')
      expect(merged).to include('"add": 2')
    end

    it "preserves blank lines between nested leading comment blocks and content" do
      template = <<~JSON
        {
          "config": {
            "keep": 1,
            "add": 2
          }
        }
      JSON
      destination = <<~JSONC
        {
          "config": {
            // Keep docs
            // More keep docs

            "keep": 9
          }
        }
      JSONC

      merged = described_class.new(
        template,
        destination,
        preference: :template,
        add_template_only_nodes: true,
      ).merge

      expect(merged).to include("// Keep docs\n    // More keep docs\n\n    \"keep\": 1")
    end

    it "recursively merges keyed arrays of objects without duplicating the array key" do
      template = <<~JSON
        {
          "items": [
            {
              "name": "shared",
              "enabled": true
            },
            {
              "id": "added",
              "enabled": true
            }
          ]
        }
      JSON
      destination = <<~JSONC
        {
          "items": [
            {
              // Shared docs
              "name": "shared",
              "enabled": false // inline note
            }
          ]
        }
      JSONC

      merged = described_class.new(
        template,
        destination,
        preference: :template,
        add_template_only_nodes: true,
      ).merge

      expect(merged.scan('"items":').count).to eq(1)
      expect(merged).to include("// Shared docs")
      expect(merged).to include('"enabled": true // inline note')
      expect(merged).to include('"id": "added"')
    end

    it "preserves comments for removed destination-only array items when removal is enabled" do
      template = <<~JSON
        {
          "items": [
            1,
            3
          ]
        }
      JSON
      destination = <<~JSONC
        {
          "items": [
            1,
            // Remove docs
            2, // remove inline
            3
          ]
        }
      JSONC

      merged = described_class.new(
        template,
        destination,
        remove_template_missing_nodes: true,
      ).merge

      expect(merged).to include("// Remove docs")
      expect(merged).to include("// remove inline")
      json_without_comments = merged.gsub(%r{//.*$}, "")
      expect(JSON.parse(json_without_comments).fetch("items")).to eq([1, 3])
    end
  end
end
