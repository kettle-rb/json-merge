# frozen_string_literal: true

# External RSpec & related config
require "kettle/test/rspec"
require "ast/merge/rspec"

# Internal ENV config
require_relative "config/debug"

# Config for development dependencies of this library
# i.e., not configured by this library
#
# Simplecov & related config (must run BEFORE any other requires)
# NOTE: Gemfiles for older rubies won't have kettle-soup-cover.
#       The rescue LoadError handles that scenario.
begin
  require "kettle-soup-cover"
  require "simplecov" if Kettle::Soup::Cover::DO_COV # `.simplecov` is run here!
rescue LoadError => error
  # check the error message and re-raise when unexpected
  raise error unless error.message.include?("kettle")
end

# this library - must be loaded BEFORE support files so TreeHaver is available
# for dependency detection in support/dependency_tags.rb
require "json/merge"

# Support files (dependency tags, helpers)
# NOTE: Loaded after json/merge so TreeHaver is available for dependency checks
Dir[File.join(__dir__, "support", "**", "*.rb")].each { |f| require f }

# Load shared examples
Dir[File.join(__dir__, "support", "shared_examples", "**", "*.rb")].sort.each { |f| require f }

# Register JSON grammar for TreeHaver if available
# This is required for tests that use TreeHaver to parse JSON
begin
  require "tree_haver"
  finder = TreeHaver::GrammarFinder.new(:json)
  finder.register! if finder.available?
rescue LoadError, TreeHaver::NotAvailable
  # TreeHaver or JSON grammar not available - tests will skip or use fallback
end

RSpec.configure do |config|
  config.before do
    # Speed up polling loops
    allow(described_class).to receive(:sleep) unless described_class.nil?
  end
end
