---
name: franalonso-finish-subphase
description: Finish a FranAlonso subphase through focused validation, specialist read-only audits, accessibility evidence, documentation, Progress and Linear reconciliation, and an exact delivery handoff. Use after the approved implementation is complete and before commit, push, PR, merge, or starting the next subphase.
---

# Finish FranAlonso Subphase

Close the approved scope without broadening delivery authority.

## Validation

1. Re-read the approved proposal, active spec, ADRs and `docs/PULL_REQUEST_CHECKLIST.md`.
2. Inspect the final diff and verify that unrelated local work is excluded.
3. Use Xcode MCP for build, affected tests and diagnostics. Never use `xcodebuild`.
4. For SwiftUI scope, discover and inspect supported preview variants and complete ADR 0022 evidence per screen.
5. Launch `$franalonso-review-ios-standards` read-only. In parallel, launch `$franalonso-review-accessibility` when UI, previews,
   visual resources, localization or accessibility changed.
6. Fix valid findings and repeat only the affected audit; repeat both for cross-scope corrections.
7. Run repository governance validators and inspect `git diff --check` plus secret-sensitive paths.

## Reconciliation

1. Update `docs/progress/phase-XX.md` with scope, RED/GREEN, build/tests/diagnostics, previews/accessibility, audits,
   remaining work and blockers.
2. Keep `docs/Progress.md` to a short current snapshot.
3. Reconcile Linear with the real state. Do not mark Done when delivery or an explicit operational gate remains.
4. Verify Obsidian only when a separate note outside the repo is an approved source; the repo-root vault needs no copy.

Use [references/closeout-output.md](references/closeout-output.md) for the handoff.

## Delivery boundary

Do only the delivery action explicitly requested. “Commit and push” does not authorize PR, merge, branch deletion,
Linear Done, live activation or the next subphase.
