# Blank Line Normalization Plan for `json-merge`

_Date: 2026-03-19_

## Role in the family refactor

`json-merge` is primarily a boundary-review repo for this effort.

Strict JSON does not support comments, so this repo is likely a documented no-op unless the blank-line normalization scope is intentionally widened beyond comment-aware and layout-sensitive merge paths.

## Current evidence files

- `README.md`
- `lib/json/merge/`
- `spec/`

## Expected scope

Default expectation:

- no new shared blank-line behavior is required beyond whatever already falls out of generic merge-result emission
- no comment-aware spacing semantics should be introduced accidentally

## Workstreams

### Workstream A: confirm the boundary

- review whether any current JSON merge path has user-visible blank-line drift that matters semantically
- document explicit non-goals if the answer remains no

### Workstream B: adopt only if scope expands deliberately

If the family later decides that pure structural JSON formatting should also normalize blank lines, this repo can opt in intentionally.

## Exit criteria

Either:

1. `json-merge` remains an explicit no-op for this effort and documents that boundary clearly

or

2. it adopts a deliberately chosen subset of the shared layout contract with focused evidence
