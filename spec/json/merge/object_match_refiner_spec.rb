# frozen_string_literal: true

RSpec.describe Json::Merge::ObjectMatchRefiner do
  subject(:refiner) { described_class.new(**options) }

  let(:options) { {} }

  # Helper to extract pairs from analysis - with tree-based merging,
  # statements are root-level nodes (objects), and pairs are their mergeable_children
  def extract_pairs(analysis)
    analysis.statements.flat_map do |node|
      if node.respond_to?(:mergeable_children)
        node.mergeable_children
      elsif node.respond_to?(:pair?) && node.pair?
        [node]
      else
        []
      end
    end.select { |n| n.respond_to?(:pair?) && n.pair? }
  end

  describe "#initialize" do
    it "uses default threshold of 0.5" do
      expect(refiner.threshold).to eq(0.5)
    end

    it "uses default key_weight of 0.7" do
      expect(refiner.key_weight).to eq(0.7)
    end

    it "uses default value_weight of 0.3" do
      expect(refiner.value_weight).to eq(0.3)
    end

    context "with custom options" do
      let(:options) { {threshold: 0.6, key_weight: 0.8, value_weight: 0.2} }

      it "uses custom threshold" do
        expect(refiner.threshold).to eq(0.6)
      end

      it "uses custom key_weight" do
        expect(refiner.key_weight).to eq(0.8)
      end

      it "uses custom value_weight" do
        expect(refiner.value_weight).to eq(0.2)
      end
    end
  end

  describe "#call" do
    let(:template_json) { <<~JSON }
      {
        "databaseUrl": "postgres://localhost/myapp",
        "cacheTtl": 3600,
        "apiEndpoint": "https://api.example.com"
      }
    JSON

    let(:dest_json) { <<~JSON }
      {
        "database_url": "postgres://localhost/production",
        "cacheTimeout": 7200,
        "errorHandler": "default"
      }
    JSON

    let(:template_analysis) { Json::Merge::FileAnalysis.new(template_json) }
    let(:dest_analysis) { Json::Merge::FileAnalysis.new(dest_json) }

    let(:template_pairs) { extract_pairs(template_analysis) }
    let(:dest_pairs) { extract_pairs(dest_analysis) }

    it "matches keys with similar names (camelCase vs snake_case)" do
      matches = refiner.call(template_pairs, dest_pairs)

      # databaseUrl should match database_url
      db_match = matches.find do |m|
        t_key = m.template_node.key_name
        t_key&.include?("database") || t_key&.include?("Database")
      end
      expect(db_match).not_to be_nil
      expect(db_match.dest_node.key_name).to eq("database_url")
    end

    it "matches keys with similar semantics" do
      matches = refiner.call(template_pairs, dest_pairs)

      # cacheTtl should match cacheTimeout (similar concept)
      cache_match = matches.find do |m|
        t_key = m.template_node.key_name
        t_key&.include?("cache") || t_key&.include?("Cache")
      end
      expect(cache_match).not_to be_nil
      expect(cache_match.dest_node.key_name.downcase).to include("cache")
    end

    it "returns MatchResult objects with scores" do
      matches = refiner.call(template_pairs, dest_pairs)

      expect(matches).to all(be_a(Ast::Merge::MatchRefinerBase::MatchResult))
      expect(matches.map(&:score)).to all(be_a(Float))
      expect(matches.map(&:score)).to all(be >= refiner.threshold)
    end

    context "with high threshold" do
      let(:options) { {threshold: 0.9} }

      it "returns fewer matches" do
        matches = refiner.call(template_pairs, dest_pairs)

        # With 0.9 threshold, only very similar keys should match
        expect(matches.size).to be <= 1
      end
    end

    context "when one list is empty" do
      it "returns empty array for empty template" do
        matches = refiner.call([], dest_pairs)
        expect(matches).to eq([])
      end

      it "returns empty array for empty destination" do
        matches = refiner.call(template_pairs, [])
        expect(matches).to eq([])
      end
    end

    context "with exact key matches but different values" do
      let(:dest_json) { <<~JSON }
        {
          "databaseUrl": "postgres://localhost/production"
        }
      JSON

      it "matches keys with identical names" do
        matches = refiner.call(template_pairs, dest_pairs)

        db_match = matches.find { |m| m.template_node.key_name == "databaseUrl" }
        expect(db_match).not_to be_nil
        expect(db_match.dest_node.key_name).to eq("databaseUrl")
        expect(db_match.score).to be >= 0.7
      end
    end
  end

  describe "array object matching" do
    let(:template_json) { <<~JSON }
      {
        "users": [
          {"id": 1, "name": "Alice", "email": "alice@example.com"},
          {"id": 2, "name": "Bob", "email": "bob@example.com"}
        ]
      }
    JSON

    let(:dest_json) { <<~JSON }
      {
        "users": [
          {"id": 1, "name": "Alice Smith", "email": "alice@example.com"},
          {"id": 3, "name": "Charlie", "email": "charlie@example.com"}
        ]
      }
    JSON

    let(:template_analysis) { Json::Merge::FileAnalysis.new(template_json) }
    let(:dest_analysis) { Json::Merge::FileAnalysis.new(dest_json) }

    let(:template_objects) do
      # Get the array objects (users array contents)
      template_analysis.statements.select do |n|
        n.respond_to?(:object?) && n.object? && !n.respond_to?(:pair?)
      end
    end

    let(:dest_objects) do
      dest_analysis.statements.select do |n|
        n.respond_to?(:object?) && n.object? && !n.respond_to?(:pair?)
      end
    end

    # Note: The actual array element matching behavior depends on how FileAnalysis
    # structures array elements. This test verifies the refiner handles objects correctly.
    it "handles object nodes" do
      # The refiner should at minimum not crash when given object nodes
      expect { refiner.call(template_objects, dest_objects) }.not_to raise_error
    end
  end

  describe "greedy matching" do
    let(:template_json) { <<~JSON }
      {
        "foo": 1,
        "bar": 2,
        "baz": 3
      }
    JSON

    let(:dest_json) { <<~JSON }
      {
        "fooo": 1,
        "barr": 2
      }
    JSON

    let(:template_analysis) { Json::Merge::FileAnalysis.new(template_json) }
    let(:dest_analysis) { Json::Merge::FileAnalysis.new(dest_json) }

    let(:template_pairs) { extract_pairs(template_analysis) }
    let(:dest_pairs) { extract_pairs(dest_analysis) }

    it "ensures each destination node is matched at most once" do
      matches = refiner.call(template_pairs, dest_pairs)

      dest_nodes = matches.map(&:dest_node)
      expect(dest_nodes.uniq.size).to eq(dest_nodes.size)
    end

    it "ensures each template node is matched at most once" do
      matches = refiner.call(template_pairs, dest_pairs)

      template_nodes = matches.map(&:template_node)
      expect(template_nodes.uniq.size).to eq(template_nodes.size)
    end
  end
end
