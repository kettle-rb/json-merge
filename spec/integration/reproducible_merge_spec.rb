# frozen_string_literal: true

require "json/merge"
require "ast/merge/rspec/shared_examples"

RSpec.describe "JSON reproducible merge" do
  let(:fixtures_path) { File.expand_path("../fixtures/reproducible", __dir__) }
  let(:merger_class) { Json::Merge::SmartMerger }
  let(:file_extension) { "json" }

  describe "basic merge scenarios (destination wins by default)" do
    context "when a key is removed in destination" do
      it_behaves_like "a reproducible merge", "01_key_removed"
    end

    context "when a key is added in destination" do
      it_behaves_like "a reproducible merge", "02_key_added"
    end

    context "when a value is changed in destination" do
      it_behaves_like "a reproducible merge", "03_value_changed"
    end
  end
end
