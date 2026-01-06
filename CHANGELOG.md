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

- Initial release

### Changed

- **NodeWrapper**: Now inherits from `Ast::Merge::NodeWrapperBase`
  - Removes ~80 lines of duplicated code (initialization, line extraction, basic methods)
  - Keeps only JSON-specific type predicates and signature computation
  - Adds `#node_wrapper?` method for distinguishing from `NodeTyping::Wrapper`
- **FileAnalysis error handling**: Now rescues `TreeHaver::Error` instead of `TreeHaver::NotAvailable`
  - `TreeHaver::Error` inherits from `Exception`, not `StandardError`
  - `TreeHaver::NotAvailable` is a subclass of `TreeHaver::Error`, so it's also caught
  - Fixes parse error handling on alternative Ruby engines
- **Dependency tags**: Refactored to use shared `TreeHaver::RSpec::DependencyTags` from tree_haver gem
  - All dependency detection is now centralized in tree_haver
  - Use `require "tree_haver/rspec"` for shared RSpec configuration
  - `JsonMergeDependencies` is now an alias to `TreeHaver::RSpec::DependencyTags`
  - Enables `JSON_MERGE_DEBUG=1` for dependency summary output

### Deprecated

### Removed

- **Load-time grammar registration** - TreeHaver's `parser_for` now handles grammar discovery
  and registration automatically. Removed manual `GrammarFinder` calls and warnings from
  `lib/json/merge.rb`.

### Fixed

- No longer warns about missing JSON grammar when the grammar file exists but tree-sitter runtime is unavailable
  - This is expected behavior when using non-tree-sitter backends (Citrus, Prism, etc.)
  - Warning now only appears when the grammar file is actually missing

### Security

[Unreleased]: https://github.com/kettle-rb/json-merge/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/kettle-rb/json-merge/compare/f1cc25b1d9b79c598270e3aa203fa56787e6c6fc...v1.0.0
[1.0.0t]: https://github.com/kettle-rb/json-merge/tags/v1.0.0
