# frozen_string_literal: true

# Dependency detection helpers for conditional test execution in json-merge
#
# This module detects whether the tree-sitter json grammar is available
# and configures RSpec to skip tests that require unavailable dependencies.
#
# Usage in specs:
#   it "requires tree-sitter-json", :tree_sitter_json do
#     # This test only runs when tree-sitter-json is available
#   end

module JsonMergeDependencies
  class << self
    # Check if tree-sitter-json grammar is available AND working via TreeHaver
    # This checks that parsing actually works, not just that a grammar file exists
    def tree_sitter_json_available?
      return @tree_sitter_json_available if defined?(@tree_sitter_json_available)
      @tree_sitter_json_available = begin
        # TreeHaver handles grammar discovery and raises NotAvailable if not found
        parser = TreeHaver.parser_for(:json)
        result = parser.parse('{"key": "value"}')
        !result.nil? && result.root_node && !result.root_node.has_error?
      rescue TreeHaver::NotAvailable
        false
      end
    end

    # Check if running on JRuby
    def jruby?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "jruby"
    end

    # Check if running on MRI (CRuby)
    def mri?
      defined?(RUBY_ENGINE) && RUBY_ENGINE == "ruby"
    end

    # Get a summary of available dependencies (for debugging)
    def summary
      {
        tree_sitter_json: tree_sitter_json_available?,
        ruby_engine: RUBY_ENGINE,
        jruby: jruby?,
        mri: mri?,
      }
    end
  end
end

RSpec.configure do |config|
  # Define exclusion filters for optional dependencies
  # Tests tagged with these will be skipped when the dependency is not available

  config.before(:suite) do
    # Print dependency summary if JSON_MERGE_DEBUG is set
    if ENV["JSON_MERGE_DEBUG"]
      puts "\n=== Json::Merge Test Dependencies ==="
      JsonMergeDependencies.summary.each do |dep, available|
        status = case available
        when true then "✓ available"
        when false then "✗ not available"
        else available.to_s
        end
        puts "  #{dep}: #{status}"
      end
      puts "======================================\n"
    end
  end

  # ============================================================
  # Positive tags: run when dependency IS available
  # ============================================================

  # Skip tests tagged :tree_sitter_json when tree-sitter-json grammar is not available
  config.filter_run_excluding tree_sitter_json: true unless JsonMergeDependencies.tree_sitter_json_available?

  # Skip tests tagged :jruby when not running on JRuby
  config.filter_run_excluding jruby: true unless JsonMergeDependencies.jruby?

  # ============================================================
  # Negated tags: run when dependency is NOT available
  # ============================================================

  # Skip tests tagged :not_tree_sitter_json when tree-sitter-json IS available
  config.filter_run_excluding not_tree_sitter_json: true if JsonMergeDependencies.tree_sitter_json_available?

  # Skip tests tagged :not_jruby when running on JRuby
  config.filter_run_excluding not_jruby: true if JsonMergeDependencies.jruby?
end

