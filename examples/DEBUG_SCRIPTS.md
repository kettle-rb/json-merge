# Debug Scripts for `json-merge`

This directory contains backend-focused debug scripts for `json-merge`.

These scripts were migrated from the old `jsonc-merge` example set after JSONC support moved into `json-merge`. They now exercise the unified `Json::Merge` API and the `tree_haver` JSON parser path, which can parse both JSON and JSONC in this workspace.

## Available scripts

### `debug_mri_backend.rb`
Tests the MRI C-extension backend (`ruby_tree_sitter`).

**Usage:**
```bash
ruby examples/debug_mri_backend.rb
```

**Requirements:**
- MRI Ruby
- `ruby_tree_sitter`
- `TREE_SITTER_JSON_PATH` pointing at the JSON grammar if it is not in a standard location

### `debug_ffi_backend.rb`
Tests the FFI backend.

**Usage:**
```bash
ruby examples/debug_ffi_backend.rb
```

**Requirements:**
- Ruby with FFI support
- `ffi`
- `TREE_SITTER_JSON_PATH`
- `libtree-sitter` available to the dynamic loader

### `debug_rust_backend.rb`
Tests the Rust backend via `tree_stump`.

**Usage:**
```bash
ruby examples/debug_rust_backend.rb
```

**Requirements:**
- MRI Ruby
- `tree_stump`
- `TREE_SITTER_JSON_PATH`

### `debug_java_backend.rb`
Tests the JRuby / Java backend.

**Usage:**
```bash
jruby examples/debug_java_backend.rb
```

**Requirements:**
- JRuby
- `TREE_SITTER_JAVA_JARS_DIR`
- `TREE_SITTER_RUNTIME_LIB`
- `TREE_SITTER_JSON_PATH`

### `debug_array_merge.rb`
Small repro for array merge behavior.

**Usage:**
```bash
ruby examples/debug_array_merge.rb
```

### `debug_nested_merge.rb`
Small repro for nested object merge behavior.

**Usage:**
```bash
ruby examples/debug_nested_merge.rb
```

### `test_complex_merge.rb`
Compact complex-merge smoke test.

**Usage:**
```bash
ruby examples/test_complex_merge.rb
```

## What these scripts test

Most scripts exercise some combination of:

1. Grammar loading through `TreeHaver.parser_for(:json)`
2. Parsing valid JSONC input through `Json::Merge::FileAnalysis`
3. Detecting invalid JSON input
4. Verifying recursive merge behavior
5. Confirming destination preservation and template-only additions
6. Comparing backend behavior when debugging parser differences

## Capturing and comparing output

Write scratch output inside this repo’s `tmp/` directory:

```bash
mkdir -p tmp/examples
ruby examples/debug_mri_backend.rb > tmp/examples/mri_output.txt
ruby examples/debug_ffi_backend.rb > tmp/examples/ffi_output.txt
ruby examples/debug_rust_backend.rb > tmp/examples/rust_output.txt
jruby examples/debug_java_backend.rb > tmp/examples/java_output.txt

diff -u tmp/examples/mri_output.txt tmp/examples/java_output.txt
```

## Expected signals

For a healthy backend, you should usually see:

- grammar loading succeeds
- commented JSON input parses successfully
- invalid JSON is detected
- merged output keeps destination values where expected
- template-only fields appear when `add_template_only_nodes: true`
- merge output remains parseable JSON

## Notes

- For general installation, parser setup, and JSONC support details, see the main [`README.md`](../README.md).
- The `jsonc-merge` shim no longer owns example scripts; all active examples live here in `json-merge`.
