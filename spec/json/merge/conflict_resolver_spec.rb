# frozen_string_literal: true

require "ast/merge/rspec/shared_examples"

RSpec.describe Json::Merge::ConflictResolver do
  # Use shared examples to validate base ConflictResolverBase integration
  # Note: json-merge uses the :batch strategy
  it_behaves_like "Ast::Merge::ConflictResolverBase" do
    let(:conflict_resolver_class) { described_class }
    let(:strategy) { :batch }
    let(:build_conflict_resolver) do
      ->(preference:, template_analysis:, dest_analysis:, **opts) {
        described_class.new(
          template_analysis,
          dest_analysis,
          preference: preference,
          add_template_only_nodes: opts.fetch(:add_template_only_nodes, false),
        )
      }
    end
    let(:build_mock_analysis) do
      -> {
        begin
          source = '{"key": "value"}'
          Json::Merge::FileAnalysis.new(source)
        rescue Json::Merge::ParseError
          # Return a mock if parser not available
          double("MockAnalysis", statements: [], valid?: true)
        end
      }
    end
  end

  it_behaves_like "Ast::Merge::ConflictResolverBase batch strategy" do
    let(:conflict_resolver_class) { described_class }
    let(:build_conflict_resolver) do
      ->(preference:, template_analysis:, dest_analysis:, **opts) {
        described_class.new(
          template_analysis,
          dest_analysis,
          preference: preference,
          add_template_only_nodes: opts.fetch(:add_template_only_nodes, false),
        )
      }
    end
    let(:build_mock_analysis) do
      -> {
        begin
          source = '{"key": "value"}'
          Json::Merge::FileAnalysis.new(source)
        rescue Json::Merge::ParseError
          # Return a mock if parser not available
          double("MockAnalysis", statements: [], valid?: true)
        end
      }
    end
  end

  let(:template_json) do
    <<~JSON
      {
        "name": "template-package",
        "version": "2.0.0",
        "dependencies": {
          "lodash": "^4.18.0"
        }
      }
    JSON
  end

  let(:dest_json) do
    <<~JSON
      {
        "name": "my-package",
        "version": "1.0.0",
        "dependencies": {
          "lodash": "^4.17.21"
        },
        "custom": "value"
      }
    JSON
  end

  describe "#initialize" do
    it "creates a resolver with analyses" do
      template_analysis = Json::Merge::FileAnalysis.new(template_json)
      dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

      resolver = described_class.new(template_analysis, dest_analysis)

      expect(resolver.template_analysis).to eq(template_analysis)
      expect(resolver.dest_analysis).to eq(dest_analysis)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "accepts preference option" do
      template_analysis = Json::Merge::FileAnalysis.new(template_json)
      dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

      resolver = described_class.new(
        template_analysis,
        dest_analysis,
        preference: :template,
      )

      expect(resolver.preference).to eq(:template)
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    it "accepts add_template_only_nodes option" do
      template_analysis = Json::Merge::FileAnalysis.new(template_json)
      dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

      resolver = described_class.new(
        template_analysis,
        dest_analysis,
        add_template_only_nodes: true,
      )

      expect(resolver.add_template_only_nodes).to be true
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end
  end

  describe "#resolve" do
    it "populates the result" do
      template_analysis = Json::Merge::FileAnalysis.new(template_json)
      dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

      # Skip if analysis failed (parser may not be working)
      skip "FileAnalysis not valid - parser may not be available" unless template_analysis.valid? && dest_analysis.valid?

      resolver = described_class.new(template_analysis, dest_analysis)
      result = Json::Merge::MergeResult.new

      resolver.resolve(result)

      expect(result.lines).not_to be_empty
    rescue Json::Merge::ParseError => e
      skip "tree-sitter parser not available: #{e.message}"
    end

    context "with destination preference" do
      it "preserves destination values" do
        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        # Skip if analysis failed (parser may not be working)
        skip "FileAnalysis not valid - parser may not be available" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(
          template_analysis,
          dest_analysis,
          preference: :destination,
        )
        result = Json::Merge::MergeResult.new

        resolver.resolve(result)

        output = result.to_json
        # Destination-only values should be preserved
        expect(output).to include("custom")
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    context "with template preference" do
      it "uses template values for matching signatures" do
        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(
          template_analysis,
          dest_analysis,
          preference: :template,
        )
        result = Json::Merge::MergeResult.new

        resolver.resolve(result)

        expect(result.lines).not_to be_empty
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    context "with add_template_only_nodes enabled" do
      let(:template_with_extra) do
        <<~JSON
          {
            "name": "template",
            "newField": "from-template"
          }
        JSON
      end

      let(:simple_dest) do
        <<~JSON
          {
            "name": "dest"
          }
        JSON
      end

      it "adds template-only nodes to result" do
        template_analysis = Json::Merge::FileAnalysis.new(template_with_extra)
        dest_analysis = Json::Merge::FileAnalysis.new(simple_dest)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(
          template_analysis,
          dest_analysis,
          add_template_only_nodes: true,
        )
        result = Json::Merge::MergeResult.new

        resolver.resolve(result)

        output = result.to_json
        expect(output).to include("newField")
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    context "with nodes that have no signature" do
      it "handles nodes without signatures gracefully" do
        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(template_analysis, dest_analysis)
        result = Json::Merge::MergeResult.new

        # Should not raise
        expect { resolver.resolve(result) }.not_to raise_error
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    context "with template preference" do
      let(:template_json) do
        <<~JSON
          {
            "name": "template-value",
            "version": "2.0.0"
          }
        JSON
      end

      let(:dest_json) do
        <<~JSON
          {
            "name": "dest-value",
            "version": "1.0.0"
          }
        JSON
      end

      it "uses template version when preference is :template" do
        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(
          template_analysis,
          dest_analysis,
          preference: :template,
        )
        result = Json::Merge::MergeResult.new
        resolver.resolve(result)

        # With template preference, should use template values
        content = result.to_json
        expect(content).to include("template-value").or include("2.0.0")
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    context "with add_template_only_nodes enabled" do
      let(:template_json) do
        <<~JSON
          {
            "name": "test",
            "new_field": "from_template"
          }
        JSON
      end

      let(:dest_json) do
        <<~JSON
          {
            "name": "test"
          }
        JSON
      end

      it "adds nodes only present in template" do
        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(
          template_analysis,
          dest_analysis,
          add_template_only_nodes: true,
        )
        result = Json::Merge::MergeResult.new
        resolver.resolve(result)

        # Should include the template-only field
        content = result.to_json
        expect(content).to include("new_field")
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end

      it "skips template-only nodes when disabled" do
        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(
          template_analysis,
          dest_analysis,
          add_template_only_nodes: false,
        )
        result = Json::Merge::MergeResult.new
        resolver.resolve(result)

        # Should NOT include the template-only field
        content = result.to_json
        expect(content).not_to include("new_field")
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end
  end

  describe "branch coverage for edge cases" do
    describe "#build_signature_map" do
      it "handles statements with nil signatures" do
        # Create analysis with valid JSON
        template_json = '{"key": "value"}'
        dest_json = '{"key": "value"}'

        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(template_analysis, dest_analysis)
        result = Json::Merge::MergeResult.new
        # Resolve should work even if some signatures are nil
        expect { resolver.resolve(result) }.not_to raise_error
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    describe "#add_statement_to_result" do
      it "handles non-NodeWrapper statement types" do
        # This tests the else branch in add_statement_to_result
        template_json = '{"key": "value"}'
        dest_json = '{"other": "data"}'

        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(template_analysis, dest_analysis)
        result = Json::Merge::MergeResult.new
        # Should handle various statement types gracefully
        expect { resolver.resolve(result) }.not_to raise_error
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end

    describe "#merge_statements" do
      it "handles matched statements correctly" do
        # Same keys in both template and dest - should match
        template_json = '{"shared": "template_value"}'
        dest_json = '{"shared": "dest_value"}'

        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(template_analysis, dest_analysis)
        result = Json::Merge::MergeResult.new
        resolver.resolve(result)

        content = result.to_json
        # Should have the shared key
        expect(content).to include("shared")
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end

      it "handles destination-only statements" do
        template_json = '{"template_only": "value"}'
        dest_json = '{"dest_only": "value"}'

        template_analysis = Json::Merge::FileAnalysis.new(template_json)
        dest_analysis = Json::Merge::FileAnalysis.new(dest_json)

        skip "FileAnalysis not valid" unless template_analysis.valid? && dest_analysis.valid?

        resolver = described_class.new(template_analysis, dest_analysis, add_template_only_nodes: false)
        result = Json::Merge::MergeResult.new
        resolver.resolve(result)

        content = result.to_json
        # Should have dest_only but not template_only
        expect(content).to include("dest_only")
        expect(content).not_to include("template_only")
      rescue Json::Merge::ParseError => e
        skip "tree-sitter parser not available: #{e.message}"
      end
    end
  end
end
