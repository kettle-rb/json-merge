# AGENTS.md - json-merge Development Guide

## 🎯 Project Overview

`json-merge` is a **format-specific implementation of the `*-merge` gem family** for strict JSON files. It provides intelligent JSON file merging using AST analysis with tree-sitter JSON parser.

**Core Philosophy**: Intelligent strict-JSON merging that preserves structure and formatting while applying updates from templates.

**Repository**: https://github.com/kettle-rb/json-merge
**Current Version**: 1.1.2
**Required Ruby**: >= 3.2.0 (currently developed against Ruby 4.0.1)

## ⚠️ AI Agent Terminal Limitations

### Terminal Output Is Available, but Each Command Is Isolated

**CRITICAL**: AI agents can reliably read terminal output when commands run in the background and the output is polled afterward. However, each terminal command should be treated as a fresh shell with no shared state.

### Use `mise` for Project Environment

**CRITICAL**: The canonical project environment now lives in `mise.toml`, with local overrides in `.env.local` loaded via `dotenvy`.

⚠️ **Watch for trust prompts**: After editing `mise.toml` or `.env.local`, `mise` may require trust to be refreshed before commands can load the project environment. That interactive trust screen can masquerade as missing terminal output, so commands may appear hung or silent until you handle it.

**Recovery rule**: If a `mise exec` command in this repo goes silent, appears hung, or terminal polling stops returning useful output, assume `mise trust` is needed first and recover with:

```bash
mise trust -C /home/pboling/src/kettle-rb/json-merge
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bundle exec rspec
```

Do this before spending time on unrelated debugging; in this workspace, silent `mise` commands are usually a trust problem.

```bash
mise trust -C /home/pboling/src/kettle-rb/json-merge
```

✅ **CORRECT**:
```bash
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bundle exec rspec
```

✅ **CORRECT**:
```bash
eval "$(mise env -C /home/pboling/src/kettle-rb/json-merge -s bash)" && bundle exec rspec
```

❌ **WRONG**:
```bash
cd /home/pboling/src/kettle-rb/json-merge
bundle exec rspec
```

❌ **WRONG**:
```bash
cd /home/pboling/src/kettle-rb/json-merge && bundle exec rspec
```

### Prefer Internal Tools Over Terminal

Use `read_file`, `list_dir`, `grep_search`, `file_search` instead of terminal commands for gathering information. Only use terminal for running tests, installing dependencies, and git operations.

### Workspace layout

This repo is a sibling project inside the `/home/pboling/src/kettle-rb` workspace, not a vendored dependency under another repo.

### NEVER Pipe Test Commands Through head/tail

Run the plain command and inspect the full output afterward. Do not truncate test output.

## 🏗️ Architecture: Format-Specific Implementation

### What json-merge Provides

- **`Json::Merge::SmartMerger`** – JSON-specific SmartMerger implementation
- **`Json::Merge::FileAnalysis`** – JSON file analysis with object/array extraction
- **`Json::Merge::NodeWrapper`** – Wrapper for JSON AST nodes
- **`Json::Merge::MergeResult`** – JSON-specific merge result
- **`Json::Merge::ConflictResolver`** – JSON conflict resolution
- **`Json::Merge::FreezeNode`** – JSON freeze block support (via special freeze keys)
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
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bundle exec rspec

# Single file (disable coverage threshold check)
mise exec -C /home/pboling/src/kettle-rb/json-merge -- env K_SOUP_COV_MIN_HARD=false bundle exec rspec spec/json/merge/smart_merger_spec.rb

# Specific backend tests
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bundle exec rspec --tag mri_backend
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bundle exec rspec --tag rust_backend
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bundle exec rspec --tag ffi_backend
```

**Note**: Always make commands self-contained. Use `mise exec -C /home/pboling/src/kettle-rb/json-merge -- ...` so the command gets the project environment in the same invocation.

### Coverage Reports

```bash
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bin/rake coverage
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bin/kettle-soup-cover -d
```

**Key ENV variables** (set in `mise.toml`, with local overrides in `.env.local`):
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

Strict JSON does **not** support comments. For commented JSON-like inputs, use `jsonc-merge` instead.

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
| `mise.toml` | Shared development environment defaults |

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
6. **Do NOT expect `cd` to persist** – Every terminal command is isolated; use a self-contained `mise exec -C ... -- ...` invocation.
7. **Do NOT rely on prior shell state** – Previous `cd`, `export`, aliases, and functions are not available to the next command.

## 🔧 JSON-Specific Notes

### Node Types
```json
{
  "object": {},
  "array": [],
  "string": "text",
  "number": 42,
  "boolean": true,
  "null": null
}
```

- `object`: matched by keys
- `array`: elements matched by position or value
- `string`, `number`, `boolean`, `null`: leaf values

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
  "string": "text",
  "number": 42,
  "float": 3.14,
  "boolean": true,
  "null": null,
  "array": [1, 2, 3],
  "object": {"a": 1}
}
```

- String, number, float, boolean, and null values preserve their JSON types
- Arrays preserve array structure
- Objects preserve object structure
