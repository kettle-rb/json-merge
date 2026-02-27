# Changelog

[![SemVer 2.0.0][📌semver-img]][📌semver] [![Keep-A-Changelog 1.0.0][📗keep-changelog-img]][📗keep-changelog]

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog][📗keep-changelog],
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html),
and [yes][📌major-versions-not-sacred], platform and engine support are part of the [public API][📌semver-breaking].
Please file a bug if you notice a violation of semantic versioning.

[📌semver]: https://semver.org/spec/v2.0.0.html
[📌semver-img]: https://img.shields.io/badge/semver-2.0.0-FFDD67.svg?style=flat
[📌semver-breaking]: https://github.com/semver/semver/issues/716#issuecomment-869336139
[📌major-versions-not-sacred]: https://tom.preston-werner.com/2022/05/23/major-version-numbers-are-not-sacred.html
[📗keep-changelog]: https://keepachangelog.com/en/1.0.0/
[📗keep-changelog-img]: https://img.shields.io/badge/keep--a--changelog-1.0.0-FFDD67.svg?style=flat

## [Unreleased]

### Added

### Changed

### Deprecated

### Removed

### Fixed

- ConflictResolver no longer collapses nodes that share the same signature.
  Multiple nodes with identical signatures are now matched 1:1 in order via
  cursor-based positional matching, instead of being treated as a single node.
  While duplicate keys are invalid in JSON per RFC 7159, the recursive merge
  already scopes each level, and this fix ensures correctness for any edge cases.

### Security

## [1.1.2] - 2026-02-19

- TAG: [v1.1.2][1.1.2t]
- COVERAGE: 95.72% -- 604/631 lines in 10 files
- BRANCH COVERAGE: 77.81% -- 235/302 branches in 10 files
- 96.63% documented

### Added

- AGENTS.md

### Changed

- appraisal2 v3.0.6
- kettle-test v1.0.10
- stone_checksums v1.0.3
- [ast-merge v4.0.6](https://github.com/kettle-rb/ast-merge/releases/tag/v4.0.6)
- [tree_haver v5.0.5](https://github.com/kettle-rb/tree_haver/releases/tag/v5.0.5)
- tree_stump v0.2.0
  - fork no longer required, updates all applied upstream
- Updated documentation on hostile takeover of RubyGems
  - https://dev.to/galtzo/hostile-takeover-of-rubygems-my-thoughts-5hlo

## [1.1.1] - 2026-01-26

- TAG: [v1.1.1][1.1.1t]
- COVERAGE: 95.72% -- 604/631 lines in 10 files
- BRANCH COVERAGE: 77.81% -- 235/302 branches in 10 files
- 96.63% documented

### Added

- ConflictResolver now applies per-node-type preferences via `node_typing`.

### Changed

- Upgrade to [ast-merge v4.0.4](https://github.com/kettle-rb/ast-merge/releases/tag/v4.0.4)
- Upgrade to [tree_haver v5.0.2](https://github.com/kettle-rb/tree_haver/releases/tag/v5.0.2)

## [1.1.0] - 2026-01-12

- TAG: [v1.1.0][1.1.0t]
- COVERAGE: 95.77% -- 589/615 lines in 10 files
- BRANCH COVERAGE: 78.82% -- 227/288 branches in 10 files
- 96.63% documented

### Added

- bin/rspec-ffi to run FFI isolated specs
  - Also bin/rake ffi_specs
- FFI backend isolation for test suite
  - Added `bin/rspec-ffi` script to run FFI specs in isolation (before MRI backend loads)
  - Added `spec/spec_ffi_helper.rb` for FFI-specific test configuration
  - Updated Rakefile with `ffi_specs` and `remaining_specs` tasks
  - The `:test` task now runs FFI specs first, then remaining specs

### Changed

- Upgrade to [ast-merge v4.0.2](https://github.com/kettle-rb/ast-merge/releases/tag/v4.0.2)
  - Includes Ast::Merge::EmitterBase
- Upgrade to [tree_haver v5.0.1](https://github.com/kettle-rb/tree_haver/releases/tag/v5.0.1)
  - Many Backend improvements
  - Many error handling improvements
- **Simplified dependency_tags.rb**: Removed redundant debug code
  - Removed `JSON_MERGE_DEBUG` env var handling (use `TREE_HAVER_DEBUG` instead)
  - tree_haver's debug output now respects blocked backends via `compute_blocked_backends`
  - Avoids accidentally loading MRI backend during FFI-only test runs

### Removed

- **Obsolete Tests**: Removed 3 obsolete integration tests
  - Tests for `add_node_to_result` and `add_wrapper_to_result` methods
  - These methods don't exist in the `:batch` strategy (ConflictResolver now uses Emitter)
  - Tests were for old `:node` strategy pattern

### Fixed

- **NodeWrapper signature tests**: Updated tests to expect `:root_object`/`:root_array` for root-level containers
  - Root-level objects now correctly return `[:root_object, ...]` instead of `[:object, ...]`
  - Root-level arrays now correctly return `[:root_array]` instead of `[:array, count]`
  - Added `:parent` method stubs to mock node tests for `root_level_container?` compatibility
- **ConflictResolver#emit_node**: Fixed handling of pair nodes with object values
  - When emitting a pair like `"features": {...}`, the value was treated as raw text
  - Now correctly detects when a pair's value is an object container
  - Recursively emits object structure using `emit_nested_object_start/end`
  - Treats arrays as atomic values (emits as raw text)
  - Prevents double key emission and invalid JSON output in nested merges
- **ConflictResolver#merge_matched_nodes_to_emitter**: Fixed array handling in merge logic
  - Arrays are now treated atomically and replaced based on preference setting
  - Only objects (not arrays) are recursively merged
  - Fixes potential "expected object key, got number" errors when merging arrays
  - Arrays like `[1,2,3]` are now correctly replaced with `[4,5]` based on preference

## [1.0.0] - 2026-01-06

- TAG: [v1.0.0][1.0.0t]
- COVERAGE: 100.00% -- 194/194 lines in 2 files
- BRANCH COVERAGE: 84.15% -- 69/82 branches in 2 files
- 96.67% documented

### Added

- Initial release

### Security

[Unreleased]: https://github.com/kettle-rb/json-merge/compare/v1.1.2...HEAD
[1.1.3]: https://github.com/kettle-rb/json-merge/compare/v1.1.2...v1.1.3
[1.1.3t]: https://github.com/kettle-rb/json-merge/releases/tag/v1.1.3
[1.1.2]: https://github.com/kettle-rb/json-merge/compare/v1.1.1...v1.1.2
[1.1.2t]: https://github.com/kettle-rb/json-merge/releases/tag/v1.1.2
[1.1.1]: https://github.com/kettle-rb/json-merge/compare/v1.1.0...v1.1.1
[1.1.1t]: https://github.com/kettle-rb/json-merge/releases/tag/v1.1.1
[1.1.0]: https://github.com/kettle-rb/json-merge/compare/v1.0.0...v1.1.0
[1.1.0t]: https://github.com/kettle-rb/json-merge/releases/tag/v1.1.0
[1.0.0]: https://github.com/kettle-rb/json-merge/compare/f1cc25b1d9b79c598270e3aa203fa56787e6c6fc...v1.0.0
[1.0.0t]: https://github.com/kettle-rb/json-merge/tags/v1.0.0
