# frozen_string_literal: true

# Load shared dependency tags from tree_haver
#
# This file follows the standard spec/support/ convention. The actual
# implementation is in tree_haver so it can be shared across all gems
# in the TreeHaver/ast-merge family.
#
# @see TreeHaver::RSpec::DependencyTags

require "tree_haver/rspec"

# Alias for convenience in existing specs
JsonMergeDependencies = TreeHaver::RSpec::DependencyTags

# Additional json-merge specific configuration
RSpec.configure do |config|
  # Print dependency summary if JSON_MERGE_DEBUG is set
  config.before(:suite) do
    if ENV["JSON_MERGE_DEBUG"]
      puts "\n=== Json::Merge Test Dependencies ==="
      TreeHaver::RSpec::DependencyTags.summary.each do |dep, available|
        status = case available
        when true then "✓ available"
        when false then "✗ not available"
        else available.to_s
        end
        puts "  #{dep}: #{status}"
      end
      puts "======================================\n"

      # Detailed grammar finder debugging
      puts "\n=== JSON Grammar Finder Debug ==="
      begin
        finder = TreeHaver::GrammarFinder.new(:json)
        puts "  ENV var name: #{finder.env_var_name}"
        puts "  ENV var set?: #{ENV.key?(finder.env_var_name)}"
        puts "  ENV var value: #{ENV[finder.env_var_name].inspect}"
        puts "  Library filename: #{finder.library_filename}"
        puts "  Search paths:"
        finder.search_paths.each do |path|
          exists = File.exist?(path)
          puts "    #{path} (exists: #{exists})"
        end
        puts "  find_library_path result: #{finder.find_library_path.inspect}"
        puts "  tree_sitter_runtime_usable?: #{TreeHaver::GrammarFinder.tree_sitter_runtime_usable?}"
        puts "  available?: #{finder.available?}"
      rescue => e
        puts "  ERROR: #{e.class}: #{e.message}"
        puts e.backtrace.first(5).map { |l| "    #{l}" }.join("\n")
      end
      puts "=================================\n"

      # Also show LD_LIBRARY_PATH
      puts "\n=== Library Path Environment ==="
      puts "  LD_LIBRARY_PATH: #{ENV["LD_LIBRARY_PATH"].inspect}"
      puts "  DYLD_LIBRARY_PATH: #{ENV["DYLD_LIBRARY_PATH"].inspect}"
      puts "================================\n"
    end
  end
end
