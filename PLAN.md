# PLAN.md

## Goal
Keep `json-merge` as the strict-JSON counterpart to `jsonc-merge`, while deciding whether to expose an explicit shared `comment_capability` of `none` for API symmetry.

`psych-merge` is the reference for the shared comment API, but this gem is expected to remain a no-comment format unless there is a clear reason to add capability-symmetry helpers.

## Current Status
- `json-merge` is in scope because it belongs to the merge-gem family, even though strict JSON does not support comments.
- The gem has the standard merge-gem layout and should stay focused on deterministic structural merges.
- Real comment-preserving behavior belongs in `jsonc-merge`, not here.
- The planning question is API symmetry, not comment merge semantics.

## Integration Strategy
- Do not add real comment-preservation behavior to strict JSON merges.
- Decide whether to expose shared capability methods that explicitly return a no-comment capability.
- Keep JSON parsing and emission strict and deterministic.
- Document the boundary clearly: use `jsonc-merge` for commented JSON-like sources.

## First Slices
1. Decide whether `json-merge` should expose explicit `comment_capability: none` helpers.
2. If yes, add the smallest possible analysis-layer surface with no behavioral change.
3. Add tests proving strict JSON behavior does not change.
4. Update docs to point comment-preserving use cases to `jsonc-merge`.

## First Files To Inspect
- `lib/json/merge/file_analysis.rb`
- `lib/json/merge/node_wrapper.rb`
- `lib/json/merge/smart_merger.rb`
- `lib/json/merge/conflict_resolver.rb`
- `README.md`

## Tests To Add First
- strict JSON parser/merger non-regression specs
- optional API-symmetry specs for `comment_capability`
- docs/examples proving commented inputs still belong to `jsonc-merge`

## Risks
- Adding too much symmetry code could blur the JSON vs JSONC boundary.
- Any accidental comment support would be a format regression.
- The no-op plan should stay intentionally small.

## Success Criteria
- Strict JSON behavior remains unchanged.
- If capability symmetry is added, it is explicit and no-op.
- Tests prove that comment-preserving behavior still belongs to `jsonc-merge`.
- The boundary between JSON and JSONC is clearer, not fuzzier.

## Rollout Phase
- Phase 4 target.
- This is intentionally the smallest plan because strict JSON should not gain comment semantics.

## Execution Backlog

### Slice 1 — Decide API symmetry
- Decide whether `json-merge` should expose explicit `comment_capability: none` behavior for family-wide API consistency.
- Keep the decision small and documentation-driven.

### Slice 2 — Optional no-op capability surface
- If symmetry is desired, add the smallest possible analysis-layer no-op surface with no merge behavior changes.
- Add narrow tests proving the capability is explicit and inert.

### Slice 3 — Boundary docs and non-regression coverage
- Update docs to direct commented JSON-like use cases to `jsonc-merge`.
- Keep strict JSON parser and merge behavior fully unchanged.
- Add only non-regression coverage, not comment-merging behavior.

## Dependencies / Resume Notes
- Coordinate the no-op decision with `jsonc-merge` so the format boundary stays clear.
- Start in `lib/json/merge/file_analysis.rb` only if API symmetry is explicitly desired.
- Avoid any change that would imply JSON comments are supported.

## Exit Gate For This Plan
- The JSON vs JSONC boundary remains explicit, and any shared capability surface is clearly no-op.
