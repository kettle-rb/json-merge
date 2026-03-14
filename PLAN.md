# PLAN.md

## Goal
Keep `json-merge` as the strict-JSON counterpart to `jsonc-merge`, with comment handling explicitly out of scope.

`psych-merge` is the reference for the shared comment API, but strict JSON does not support comments and the parser boundary sits below `json-merge`, so no shared comment surface is needed here.

## Current Status
- `json-merge` is in scope because it belongs to the merge-gem family, even though strict JSON does not support comments.
- The gem has the standard merge-gem layout and should stay focused on deterministic structural merges.
- Real comment-preserving behavior belongs in `jsonc-merge`, not here.
- The no-op decision is settled: `json-merge` should not grow comment-specific APIs or behavior.

## Integration Strategy
- Do not add real comment-preservation behavior to strict JSON merges.
- Keep JSON parsing and emission strict and deterministic.
- Document the boundary clearly: use `jsonc-merge` for commented JSON-like sources.

## First Slices
1. Keep strict JSON behavior unchanged.
2. Remove or avoid any comment-specific planning drift in docs and code comments.
3. Keep tests focused on strict JSON parsing and merge behavior.
4. Continue pointing commented JSON-like use cases to `jsonc-merge`.

## First Files To Inspect
- `lib/json/merge/file_analysis.rb`
- `lib/json/merge/node_wrapper.rb`
- `lib/json/merge/smart_merger.rb`
- `lib/json/merge/conflict_resolver.rb`
- `README.md`

## Tests To Add First
- strict JSON parser/merger non-regression specs
- docs/examples proving commented inputs still belong to `jsonc-merge`

## Risks
- Adding too much symmetry code could blur the JSON vs JSONC boundary.
- Any accidental comment support would be a format regression.
- The no-op plan should stay intentionally small.

## Success Criteria
- Strict JSON behavior remains unchanged.
- Tests prove that comment-preserving behavior still belongs to `jsonc-merge`.
- The boundary between JSON and JSONC is clearer, not fuzzier.

## Rollout Phase
- Phase 4 target.
- This is intentionally the smallest plan because strict JSON should not gain comment semantics.

## Latest `ast-merge` Comment Logic Checklist (2026-03-13)
- [x] Shared capability decision: no-op; strict JSON does not expose comment behavior
- [x] Document boundary behavior: intentionally unchanged for strict JSON
- [x] Matched-node fallback: intentionally unsupported (comments are out of scope)
- [x] Removed-node preservation: intentionally unsupported (comments are out of scope)
- [x] Boundary/fixture parity: docs and tests reinforce JSON vs JSONC separation

Current parity status: complete no-op boundary; strict JSON comment handling is permanently out of scope, and the local workspace-path gem wiring has now been revalidated under `KETTLE_RB_DEV`.
Next execution target: none for the comment rollout beyond guarding the JSON vs JSONC boundary in future maintenance.

## Execution Backlog

## Progress
- 2026-03-12: Status sync completed; the strict-JSON/no-comments boundary is now treated as settled, and project guidance was updated to keep commented JSON-like inputs pointed at `jsonc-merge`.
- 2026-03-13: Local workspace-path validation rechecked after modular gemfile wiring normalization.
- Replaced direct local `path:` overrides in modular tree-sitter / templating gemfiles with the shared `nomono` local-override pattern and reran the full `json-merge` suite in workspace mode; the suite is green with the existing FFI-backend pending examples only.

### Slice 1 — Boundary docs and non-regression coverage
- Update docs to direct commented JSON-like use cases to `jsonc-merge`.
- Keep strict JSON parser and merge behavior fully unchanged.
- Add only non-regression coverage, not comment-merging behavior.

## Dependencies / Resume Notes
- Coordinate boundary wording with `jsonc-merge` so the format boundary stays clear.
- Avoid any change that would imply JSON comments are supported.

## Exit Gate For This Plan
- The JSON vs JSONC boundary remains explicit, and any shared capability surface is clearly no-op.
