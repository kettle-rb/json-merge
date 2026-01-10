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

- bin/rspec-ffi to run FFI isolated specs
  - Also bin/rake ffi_specs
- FFI backend isolation for test suite
  - Added `bin/rspec-ffi` script to run FFI specs in isolation (before MRI backend loads)
  - Added `spec/spec_ffi_helper.rb` for FFI-specific test configuration
  - Updated Rakefile with `ffi_specs` and `remaining_specs` tasks
  - The `:test` task now runs FFI specs first, then remaining specs

### Changed

- ast-merge v3.1.0
  - adds Ast::Merge::EmitterBase
- tree_haver v4.0.5
  - FFI Backend improvements
  - Error handling improvements
- **Simplified dependency_tags.rb**: Removed redundant debug code
  - Removed `JSON_MERGE_DEBUG` env var handling (use `TREE_HAVER_DEBUG` instead)
  - tree_haver's debug output now respects blocked backends via `compute_blocked_backends`
  - Avoids accidentally loading MRI backend during FFI-only test runs

### Deprecated

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

### Security

## [1.0.0] - 2026-01-06

- TAG: [v1.0.0][1.0.0t]
- COVERAGE: 100.00% -- 194/194 lines in 2 files
- BRANCH COVERAGE: 84.15% -- 69/82 branches in 2 files
- 96.67% documented

### Added

- Initial release

### Security

[Unreleased]: https://github.com/kettle-rb/json-merge/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kettle-rb/json-merge/compare/f1cc25b1d9b79c598270e3aa203fa56787e6c6fc...v1.0.0
[1.0.0t]: https://github.com/kettle-rb/json-merge/tags/v1.0.0
