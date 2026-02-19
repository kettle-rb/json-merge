# AGENTS.md - json-merge Development Guide

## 🎯 Project Overview

`json-merge` is a **format-specific implementation of the `*-merge` gem family** for JSON files. It provides intelligent JSON file merging using AST analysis with tree-sitter JSON parser.

**Core Philosophy**: Intelligent JSON merging that preserves structure and formatting while applying updates from templates.

**Repository**: https://github.com/kettle-rb/json-merge
**Current Version**: 1.1.2
**Required Ruby**: >= 3.2.0 (currently developed against Ruby 4.0.1)

## 🏗️ Architecture: Format-Specific Implementation

### What json-merge Provides

- **`Json::Merge::SmartMerger`** – JSON-specific SmartMerger implementation
- **`Json::Merge::FileAnalysis`** – JSON file analysis with object/array extraction
- **`Json::Merge::NodeWrapper`** – Wrapper for JSON AST nodes
- **`Json::Merge::MergeResult`** – JSON-specific merge result
- **`Json::Merge::ConflictResolver`** – JSON conflict resolution
- **`Json::Merge::FreezeNode`** – JSON freeze block support (via special comment keys)
- **`Json::Merge::DebugLogger`** – JSON-specific debug logging

### Key Dependencies

| Gem | Role |
|-----|------|
| `ast-merge` (~> 4.0) | Base classes and shared infrastructure |
| `tree_haver` (~> 5.0) | Unified parser adapter (tree-sitter) |
| `version_gem` (~> 1.1) | Version management |

### Parser Backend Support

json-merge works with tree-sitter JSON parser via TreeHaver:

| Backend | Parser | Platform | Notes |
|---------|--------|----------|-------|
| `:mri` | tree-sitter-json | MRI only | Best performance, requires native library |
| `:rust` | tree-sitter-json | MRI only | Rust implementation via tree_stump |
| `:ffi` | tree-sitter-json | All platforms | FFI binding, works on JRuby/TruffleRuby |

## 📁 Project Structure

```
lib/json/merge/
├── smart_merger.rb          # Main SmartMerger implementation
├── file_analysis.rb         # JSON file analysis
├── node_wrapper.rb          # AST node wrapper
├── merge_result.rb          # Merge result object
├── conflict_resolver.rb     # Conflict resolution
├── freeze_node.rb           # Freeze block support
├── debug_logger.rb          # Debug logging
└── version.rb

spec/json/merge/
├── smart_merger_spec.rb
├── file_analysis_spec.rb
├── node_wrapper_spec.rb
└── integration/
```

## 🔧 Development Workflows

### Running Tests

```bash
# Full suite (required for coverage thresholds)
bundle exec rspec

# Single file (disable coverage threshold check)
K_SOUP_COV_MIN_HARD=false bundle exec rspec spec/json/merge/smart_merger_spec.rb

# Specific backend tests
bundle exec rspec --tag mri_backend
bundle exec rspec --tag rust_backend
bundle exec rspec --tag ffi_backend
```

**Note**: Always run commands in the project root (`/home/pboling/src/kettle-rb/ast-merge/vendor/json-merge`). Allow `direnv` to load environment variables first by doing a plain `cd` before running commands.

### Coverage Reports

```bash
cd /home/pboling/src/kettle-rb/ast-merge/vendor/json-merge
bin/rake coverage && bin/kettle-soup-cover -d
```

**Key ENV variables** (set in `.envrc`, loaded via `direnv allow`):
- `K_SOUP_COV_DO=true` – Enable coverage
- `K_SOUP_COV_MIN_LINE=100` – Line coverage threshold
- `K_SOUP_COV_MIN_BRANCH=82` – Branch coverage threshold
- `K_SOUP_COV_MIN_HARD=true` – Fail if thresholds not met

### Code Quality

```bash
bundle exec rake reek
bundle exec rake rubocop_gradual
```

## 📝 Project Conventions

### API Conventions

#### SmartMerger API
- `merge` – Returns a **String** (the merged JSON content)
- `merge_result` – Returns a **MergeResult** object
- `to_s` on MergeResult returns the merged content as a string

#### JSON-Specific Features

**Object Merging**:
```ruby
merger = Json::Merge::SmartMerger.new(template_json, dest_json)
result = merger.merge
```

**Freeze Blocks** (via special comment keys):
```json
{
  "database": {
    "__json_merge_freeze__": true,
    "password": "custom_secret",
    "host": "localhost"
  }
}
```

**Array Handling**:
- Arrays can be merged or replaced based on preference
- Element matching by value equality

### kettle-dev Tooling

This project uses `kettle-dev` for gem maintenance automation:

- **Rakefile**: Sourced from kettle-dev template
- **CI Workflows**: GitHub Actions and GitLab CI managed via kettle-dev
- **Releases**: Use `kettle-release` for automated release process

### Version Requirements
- Ruby >= 3.2.0 (gemspec), developed against Ruby 4.0.1 (`.tool-versions`)
- `ast-merge` >= 4.0.0 required
- `tree_haver` >= 5.0.3 required

## 🧪 Testing Patterns

### TreeHaver Dependency Tags

All spec files use TreeHaver RSpec dependency tags for conditional execution:

**Available tags**:
- `:json_grammar` – Requires JSON grammar (any backend)
- `:mri_backend` – Requires tree-sitter MRI backend
- `:rust_backend` – Requires tree-sitter Rust backend
- `:ffi_backend` – Requires tree-sitter FFI backend
- `:json_parsing` – Requires any JSON parser

✅ **CORRECT** – Use dependency tag on describe/context/it:
```ruby
RSpec.describe Json::Merge::SmartMerger, :json_grammar do
  # Skipped if no JSON parser available
end

it "parses with tree-sitter", :mri_backend, :json_grammar do
  # Skipped if tree-sitter not available
end
```

❌ **WRONG** – Never use manual skip checks:
```ruby
before do
  skip "Requires tree-sitter" unless tree_sitter_available?  # DO NOT DO THIS
end
```

### Backend Isolation

**CRITICAL**: Tests must respect backend isolation to prevent FFI/MRI conflicts:

```ruby
# Use TreeHaver.with_backend to ensure backend isolation
TreeHaver.with_backend(:mri) do
  analysis = Json::Merge::FileAnalysis.new(json_source)
end
```

### Shared Examples

json-merge uses shared examples from `ast-merge`:

```ruby
it_behaves_like "Ast::Merge::FileAnalyzable"
it_behaves_like "Ast::Merge::ConflictResolverBase"
it_behaves_like "a reproducible merge", "scenario_name", { preference: :template }
```

## 🔍 Critical Files

| File | Purpose |
|------|---------|
| `lib/json/merge/smart_merger.rb` | Main JSON SmartMerger implementation |
| `lib/json/merge/file_analysis.rb` | JSON file analysis and object extraction |
| `lib/json/merge/node_wrapper.rb` | JSON node wrapper with type-specific methods |
| `lib/json/merge/debug_logger.rb` | JSON-specific debug logging |
| `spec/spec_helper.rb` | Test suite entry point |
| `.envrc` | Coverage thresholds and backend configuration |

## 🚀 Common Tasks

```bash
# Run all specs with coverage
bundle exec rake spec

# Generate coverage report
bundle exec rake coverage

# Check code quality
bundle exec rake reek
bundle exec rake rubocop_gradual

# Run with specific backend
TREE_HAVER_BACKEND=mri bundle exec rspec

# Prepare and release
kettle-changelog && kettle-release
```

## 🌊 Integration Points

- **`ast-merge`**: Inherits base classes (`SmartMergerBase`, `FileAnalyzable`, etc.)
- **`tree_haver`**: Multi-backend JSON parsing (tree-sitter MRI, Rust, FFI)
- **RSpec**: Full integration via `ast/merge/rspec` and `tree_haver/rspec`
- **SimpleCov**: Coverage tracked for `lib/**/*.rb`; spec directory excluded

## 💡 Key Insights

1. **JSON has no comments**: Freeze blocks use special keys (`__json_merge_freeze__`)
2. **Multi-backend support**: json-merge works with 3 different tree-sitter backends
3. **Backend isolation is critical**: Always use `TreeHaver.with_backend` to prevent FFI/MRI conflicts
4. **Object matching**: JSON objects matched by key names
5. **Array merging**: Arrays can be merged element-wise or replaced entirely
6. **Type preservation**: Numbers, booleans, null are preserved (not stringified)
7. **Formatting preservation**: Indentation and whitespace are maintained

## 🚫 Common Pitfalls

1. **NEVER mix FFI and MRI backends** – Use `TreeHaver.with_backend` for isolation
2. **NEVER use manual skip checks** – Use dependency tags (`:json_grammar`, `:mri_backend`)
3. **JSON has no comments** – Use special keys for freeze blocks
4. **Do NOT load vendor gems** – They are not part of this project; they do not exist in CI
5. **Use `tmp/` for temporary files** – Never use `/tmp` or other system directories
6. **Do NOT chain `cd` with `&&`** – Run `cd` as a separate command so `direnv` loads ENV

## 🔧 JSON-Specific Notes

### Node Types
```json
{
  "object": {},        // Matched by keys
  "array": [],         // Elements matched by position or value
  "string": "text",    // Leaf value
  "number": 42,        // Leaf value
  "boolean": true,     // Leaf value
  "null": null         // Leaf value
}
```

### Merge Behavior
- **Objects**: Matched by key name; deep merging of nested objects
- **Arrays**: Can be merged or replaced based on preference
- **Primitives**: Leaf values; replaced when matched
- **Freeze blocks**: Use `__json_merge_freeze__: true` key

### Freeze Block Example
```json
{
  "config": {
    "__json_merge_freeze__": true,
    "customValue": "don't override",
    "preserveThis": 42
  },
  "normalKey": "this will merge"
}
```

### Type Handling
```json
{
  "string": "text",      // String type preserved
  "number": 42,          // Number type preserved
  "float": 3.14,         // Float type preserved
  "boolean": true,       // Boolean type preserved
  "null": null,          // Null type preserved
  "array": [1, 2, 3],    // Array structure preserved
  "object": {"a": 1}     // Object structure preserved
}
```
