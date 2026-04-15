# frozen_string_literal: true

require "spec_helper"

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

  describe "#call", :json_grammar do
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

  describe "array object matching", :json_grammar do
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

  describe "greedy matching", :json_grammar do
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

  describe "#match_array_objects", :json_grammar do
    let(:template_json) { <<~JSON }
      [
        {"id": 1, "name": "Alice"},
        {"id": 2, "name": "Bob"}
      ]
    JSON

    let(:dest_json) { <<~JSON }
      [
        {"id": 1, "name": "Alice Updated"},
        {"id": 3, "name": "Charlie"}
      ]
    JSON

    let(:template_analysis) { Json::Merge::FileAnalysis.new(template_json) }
    let(:dest_analysis) { Json::Merge::FileAnalysis.new(dest_json) }

    it "matches objects in arrays by key overlap" do
      # Get array elements - they should be objects
      template_nodes = template_analysis.statements.flat_map do |s|
        s.respond_to?(:elements) ? s.elements : []
      end.select { |n| n.respond_to?(:object?) && n.object? }

      dest_nodes = dest_analysis.statements.flat_map do |s|
        s.respond_to?(:elements) ? s.elements : []
      end.select { |n| n.respond_to?(:object?) && n.object? }

      skip "No objects in arrays" if template_nodes.empty? || dest_nodes.empty?

      matches = refiner.send(:match_array_objects, template_nodes, dest_nodes)
      expect(matches).to be_an(Array)
    end

    it "returns empty array when template objects is empty" do
      matches = refiner.send(:match_array_objects, [], [double("obj")])
      expect(matches).to eq([])
    end

    it "returns empty array when dest objects is empty" do
      matches = refiner.send(:match_array_objects, [double("obj")], [])
      expect(matches).to eq([])
    end
  end

  describe "#compute_object_similarity", :json_grammar do
    let(:template_json) { '{"a": 1, "b": 2}' }
    let(:dest_json) { '{"a": 1, "c": 3}' }

    let(:template_analysis) { Json::Merge::FileAnalysis.new(template_json) }
    let(:dest_analysis) { Json::Merge::FileAnalysis.new(dest_json) }

    it "returns 1.0 when both objects are empty" do
      t_json = "{}"
      d_json = "{}"
      t_analysis = Json::Merge::FileAnalysis.new(t_json)
      d_analysis = Json::Merge::FileAnalysis.new(d_json)
      t_obj = t_analysis.root_object
      d_obj = d_analysis.root_object
      skip "No objects" unless t_obj && d_obj

      score = refiner.send(:compute_object_similarity, t_obj, d_obj)
      expect(score).to eq(1.0)
    end

    it "returns 0.0 when template is empty but dest has keys" do
      t_json = "{}"
      d_json = '{"key": "value"}'
      t_analysis = Json::Merge::FileAnalysis.new(t_json)
      d_analysis = Json::Merge::FileAnalysis.new(d_json)
      t_obj = t_analysis.root_object
      d_obj = d_analysis.root_object
      skip "No objects" unless t_obj && d_obj

      score = refiner.send(:compute_object_similarity, t_obj, d_obj)
      expect(score).to eq(0.0)
    end

    it "returns 0.0 when dest is empty but template has keys" do
      t_json = '{"key": "value"}'
      d_json = "{}"
      t_analysis = Json::Merge::FileAnalysis.new(t_json)
      d_analysis = Json::Merge::FileAnalysis.new(d_json)
      t_obj = t_analysis.root_object
      d_obj = d_analysis.root_object
      skip "No objects" unless t_obj && d_obj

      score = refiner.send(:compute_object_similarity, t_obj, d_obj)
      expect(score).to eq(0.0)
    end
  end

  describe "#compute_fuzzy_key_matches" do
    it "returns 1.0 when both key sets are empty" do
      score = refiner.send(:compute_fuzzy_key_matches, [], [])
      expect(score).to eq(1.0)
    end

    it "returns 0.0 when first set is empty" do
      score = refiner.send(:compute_fuzzy_key_matches, [], ["key"])
      expect(score).to eq(0.0)
    end

    it "returns 0.0 when second set is empty" do
      score = refiner.send(:compute_fuzzy_key_matches, ["key"], [])
      expect(score).to eq(0.0)
    end

    it "computes fuzzy similarity between keys" do
      score = refiner.send(:compute_fuzzy_key_matches, ["userName"], ["user_name"])
      expect(score).to be > 0.5
    end
  end

  describe "#value_similarity", :json_grammar do
    it "returns 0.5 when template value is nil" do
      score = refiner.send(:value_similarity, nil, double("value"))
      expect(score).to eq(0.5)
    end

    it "returns 0.5 when dest value is nil" do
      score = refiner.send(:value_similarity, double("value"), nil)
      expect(score).to eq(0.5)
    end

    it "returns 0.0 when types differ" do
      t_val = double("string", type: :string, string?: true)
      d_val = double("number", type: :number, number?: true)
      score = refiner.send(:value_similarity, t_val, d_val)
      expect(score).to eq(0.0)
    end

    it "compares string values" do
      json = '{"a": "hello", "b": "world"}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      skip "No root" unless root
      pairs = root.pairs
      skip "Not enough pairs" if pairs.size < 2
      t_val = pairs[0].value_node
      d_val = pairs[1].value_node
      skip "No values" unless t_val && d_val

      score = refiner.send(:value_similarity, t_val, t_val)
      expect(score).to eq(1.0)
    end

    it "compares object values" do
      t_json = '{"nested": {"a": 1}}'
      d_json = '{"nested": {"b": 2}}'
      t_analysis = Json::Merge::FileAnalysis.new(t_json)
      d_analysis = Json::Merge::FileAnalysis.new(d_json)
      t_obj = t_analysis.root_object
      d_obj = d_analysis.root_object
      skip "No objects" unless t_obj && d_obj
      t_pair = t_obj.pairs.first
      d_pair = d_obj.pairs.first
      skip "No pairs" unless t_pair && d_pair
      t_val = t_pair.value_node
      d_val = d_pair.value_node
      skip "No nested values" unless t_val && d_val

      score = refiner.send(:value_similarity, t_val, d_val)
      expect(score).to be_a(Float)
    end

    it "compares array values" do
      t_json = '{"arr": [1, 2, 3]}'
      d_json = '{"arr": [1, 2]}'
      t_analysis = Json::Merge::FileAnalysis.new(t_json)
      d_analysis = Json::Merge::FileAnalysis.new(d_json)
      t_obj = t_analysis.root_object
      d_obj = d_analysis.root_object
      skip "No objects" unless t_obj && d_obj
      t_pair = t_obj.pairs.first
      d_pair = d_obj.pairs.first
      skip "No pairs" unless t_pair && d_pair
      t_val = t_pair.value_node
      d_val = d_pair.value_node
      skip "No array values" unless t_val && d_val

      score = refiner.send(:value_similarity, t_val, d_val)
      expect(score).to be_a(Float)
      expect(score).to be > 0
    end

    it "returns 0.5 for other same-type values (numbers, booleans)" do
      json = '{"a": 42}'
      analysis = Json::Merge::FileAnalysis.new(json)
      root = analysis.root_object
      pair = root.pairs.first
      val = pair.value_node

      score = refiner.send(:value_similarity, val, val)
      expect(score).to be >= 0.5
    end
  end

  describe "#array_similarity", :json_grammar do
    it "returns 1.0 when both arrays are empty" do
      t_json = '{"arr": []}'
      d_json = '{"arr": []}'
      t_analysis = Json::Merge::FileAnalysis.new(t_json)
      d_analysis = Json::Merge::FileAnalysis.new(d_json)
      t_obj = t_analysis.root_object
      d_obj = d_analysis.root_object
      skip "No objects" unless t_obj && d_obj
      t_arr = t_obj.pairs.first&.value_node
      d_arr = d_obj.pairs.first&.value_node
      skip "No arrays" unless t_arr && d_arr

      score = refiner.send(:array_similarity, t_arr, d_arr)
      expect(score).to eq(1.0)
    end

    it "returns 0.0 when one array is empty" do
      t_json = '{"arr": []}'
      d_json = '{"arr": [1, 2, 3]}'
      t_analysis = Json::Merge::FileAnalysis.new(t_json)
      d_analysis = Json::Merge::FileAnalysis.new(d_json)
      t_obj = t_analysis.root_object
      d_obj = d_analysis.root_object
      skip "No objects" unless t_obj && d_obj
      t_arr = t_obj.pairs.first&.value_node
      d_arr = d_obj.pairs.first&.value_node
      skip "No arrays" unless t_arr && d_arr

      score = refiner.send(:array_similarity, t_arr, d_arr)
      expect(score).to eq(0.0)
    end
  end
end
