# AGENTS.md - Development Guide

## 🎯 Project Overview

`json-merge` is a **format-specific implementation of the `*-merge` gem family** for strict JSON files. It provides intelligent JSON file merging using AST analysis with tree-sitter JSON parser.

**Core Philosophy**: Intelligent strict-JSON merging that preserves structure and formatting while applying updates from templates.

**Repository**: https://github.com/kettle-rb/json-merge
**Current Version**: 1.1.2
**Required Ruby**: >= 3.2.0 (currently developed against Ruby 4.0.1)

## ⚠️ AI Agent Terminal Limitations

### Terminal Output Is Available, but Each Command Is Isolated

**Minimum Supported Ruby**: See the gemspec `required_ruby_version` constraint.
**Local Development Ruby**: See `.tool-versions` for the version used in local development (typically the latest stable Ruby).

### Use `mise` for Project Environment

**CRITICAL**: The canonical project environment lives in `mise.toml`, with local overrides in `.env.local` loaded via `dotenvy`.

⚠️ **Watch for trust prompts**: After editing `mise.toml` or `.env.local`, `mise` may require trust to be refreshed before commands can load the project environment. Until that trust step is handled, commands can appear hung or produce no output, which can look like terminal access is broken.

**Recovery rule**: If a `mise exec` command goes silent or appears hung, assume `mise trust` is the first thing to check. Recover by running:

```bash
mise trust -C /home/pboling/src/kettle-rb/json-merge
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bundle exec rspec
```

```bash
mise trust -C /path/to/project
mise exec -C /path/to/project -- bundle exec rspec
```

Do this before spending time on unrelated debugging; in this workspace pattern, silent `mise` commands are usually a trust problem first.

```bash
mise trust -C /home/pboling/src/kettle-rb/json-merge
```

✅ **CORRECT**:
```bash
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bundle exec rspec
```

```bash
mise exec -C /path/to/project -- bundle exec rspec
```

✅ **CORRECT** — If you need shell syntax first, load the environment in the same command:

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

```bash
cd /path/to/project && bundle exec rspec
```

### Prefer Internal Tools Over Terminal

Full suite spec runs:

```bash
mise exec -C /path/to/project -- bundle exec rspec
```

For single file, targeted, or partial spec runs the coverage threshold **must** be disabled.
Use the `K_SOUP_COV_MIN_HARD=false` environment variable to disable hard failure:

### Workspace layout

## 🏗️ Architecture

### Toolchain Dependencies

This gem is part of the **kettle-rb** ecosystem. Key development tools:

### NEVER Pipe Test Commands Through head/tail

When you do run tests, keep the full output visible so you can inspect failures completely.

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

| Tool | Purpose |
|------|---------|
| `kettle-dev` | Development dependency: Rake tasks, release tooling, CI helpers |
| `kettle-test` | Test infrastructure: RSpec helpers, stubbed_env, timecop |
| `kettle-jem` | Template management and gem scaffolding |

### Executables (from kettle-dev)

| Executable | Purpose |
|-----------|---------|
| `kettle-release` | Full gem release workflow |
| `kettle-pre-release` | Pre-release validation |
| `kettle-changelog` | Changelog generation |
| `kettle-dvcs` | DVCS (git) workflow automation |
| `kettle-commit-msg` | Commit message validation |
| `kettle-check-eof` | EOF newline validation |

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

```
lib/
├── <gem_namespace>/           # Main library code
│   └── version.rb             # Version constant (managed by kettle-release)
spec/
├── fixtures/                  # Test fixture files (NOT auto-loaded)
├── support/
│   ├── classes/               # Helper classes for specs
│   └── shared_contexts/       # Shared RSpec contexts
├── spec_helper.rb             # RSpec configuration (loaded by .rspec)
gemfiles/
├── modular/                   # Modular Gemfile components
│   ├── coverage.gemfile       # SimpleCov dependencies
│   ├── debug.gemfile          # Debugging tools
│   ├── documentation.gemfile  # YARD/documentation
│   ├── optional.gemfile       # Optional dependencies
│   ├── rspec.gemfile          # RSpec testing
│   ├── style.gemfile          # RuboCop/linting
│   └── x_std_libs.gemfile     # Extracted stdlib gems
├── ruby_*.gemfile             # Per-Ruby-version Appraisal Gemfiles
└── Appraisal.root.gemfile     # Root Gemfile for Appraisal builds
.git-hooks/
├── commit-msg                 # Commit message validation hook
├── prepare-commit-msg         # Commit message preparation
├── commit-subjects-goalie.txt # Commit subject prefix filters
└── footer-template.erb.txt    # Commit footer ERB template
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

### Running Commands

Always make commands self-contained. Use `mise exec -C /home/pboling/src/kettle-rb/prism-merge -- ...` so the command gets the project environment in the same invocation.
If the command is complicated write a script in local tmp/ and then run the script.

```bash
mise exec -C /path/to/project -- env K_SOUP_COV_MIN_HARD=false bundle exec rspec spec/path/to/spec.rb
```

### Coverage Reports

```bash
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bin/rake coverage
mise exec -C /home/pboling/src/kettle-rb/json-merge -- bin/kettle-soup-cover -d
```

```bash
mise exec -C /path/to/project -- bin/rake coverage
mise exec -C /path/to/project -- bin/kettle-soup-cover -d
```

**Key ENV variables** (set in `mise.toml`, with local overrides in `.env.local`):
❌ **AVOID** when possible:

- `run_in_terminal` for information gathering

Only use terminal for:

- Running tests (`bundle exec rspec`)
- Installing dependencies (`bundle install`)
- Simple commands that do not require much shell escaping
- Running scripts (prefer writing a script over a complicated command with shell escaping)

### Code Quality

```bash
bundle exec rake reek
bundle exec rake rubocop_gradual
```

```bash
mise exec -C /path/to/project -- bundle exec rake reek
mise exec -C /path/to/project -- bundle exec rubocop-gradual
```

### Releasing

```bash
bin/kettle-pre-release    # Validate everything before release
bin/kettle-release        # Full release workflow
```

## 📝 Project Conventions

### API Conventions

#### SmartMerger API

### Test Infrastructure

- Uses `kettle-test` for RSpec helpers (stubbed_env, block_is_expected, silent_stream, timecop)
- Uses `Dir.mktmpdir` for isolated filesystem tests
- Spec helper is loaded by `.rspec` — never add `require "spec_helper"` to spec files

#### JSON-Specific Features

```bash
cd /path/to/project
bundle exec rspec
```

❌ **WRONG** — A chained `cd` does not give directory-change hooks time to update the environment:

**Object Merging**:
```ruby
merger = Json::Merge::SmartMerger.new(template_json, dest_json)
result = merger.merge
```

### Freeze Block Preservation

Template updates preserve custom code wrapped in freeze blocks:

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

This project is a **RubyGem** managed with the [kettle-rb](https://github.com/kettle-rb) toolchain.

- **Rakefile**: Sourced from kettle-dev template
- **CI Workflows**: GitHub Actions and GitLab CI managed via kettle-dev
- **Releases**: Use `kettle-release` for automated release process

### Version Requirements

- Ruby >= 3.2.0 (gemspec), developed against Ruby 4.0.1 (`.tool-versions`)
- `ast-merge` >= 4.0.0 required
- `tree_haver` >= 5.0.3 required

## 🧪 Testing Patterns

### TreeHaver Dependency Tags

### Environment Variable Helpers

```ruby
before do
  stub_env("MY_ENV_VAR" => "value")
end

before do
  hide_env("HOME", "USER")
end
```

### Dependency Tags

Use dependency tags to conditionally skip tests when optional dependencies are not available:

**Available tags**:
✅ **PREFERRED** — Use internal tools:

- `grep_search` instead of `grep` command
- `file_search` instead of `find` command
- `read_file` instead of `cat` command
- `list_dir` instead of `ls` command
- `replace_string_in_file` or `create_file` instead of `sed` / manual editing

✅ **CORRECT** — Run self-contained commands with `mise exec`:

```ruby
RSpec.describe Json::Merge::SmartMerger, :json_grammar do
  # Skipped if no JSON parser available
end

it "parses with tree-sitter", :mri_backend, :json_grammar do
  # Skipped if tree-sitter not available
end
```

```bash
eval "$(mise env -C /path/to/project -s bash)" && bundle exec rspec
```

❌ **WRONG** — Do not rely on a previous command changing directories:

```ruby
before do
  skip "Requires tree-sitter" unless tree_sitter_available?  # DO NOT DO THIS
end
```

### Backend Isolation

```ruby
# kettle-jem:freeze
# ... custom code preserved across template runs ...
# kettle-jem:unfreeze
```

### Modular Gemfile Architecture

Gemfiles are split into modular components under `gemfiles/modular/`. Each component handles a specific concern (coverage, style, debug, etc.). The main `Gemfile` loads these modular components via `eval_gemfile`.

### Forward Compatibility with `**options`

**CRITICAL**: All constructors and public API methods that accept keyword arguments MUST include `**options` as the final parameter for forward compatibility.

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

- `K_SOUP_COV_DO=true` – Enable coverage
- `K_SOUP_COV_MIN_LINE` – Line coverage threshold
- `K_SOUP_COV_MIN_BRANCH` – Branch coverage threshold
- `K_SOUP_COV_MIN_HARD=true` – Fail if thresholds not met

## 💡 Key Insights

1. **JSON has no comments**: Freeze blocks use special keys (`__json_merge_freeze__`)
2. **Multi-backend support**: json-merge works with 3 different tree-sitter backends
3. **Backend isolation is critical**: Always use `TreeHaver.with_backend` to prevent FFI/MRI conflicts
4. **Object matching**: JSON objects matched by key names
5. **Array merging**: Arrays can be merged element-wise or replaced entirely
6. **Type preservation**: Numbers, booleans, null are preserved (not stringified)
7. **Formatting preservation**: Indentation and whitespace are maintained

```ruby
RSpec.describe SomeClass, :prism_merge do
  # Skipped if prism-merge is not available
end
```

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

1. **NEVER pipe test output through `head`/`tail`** — Run tests without truncation so you can inspect the full output.
