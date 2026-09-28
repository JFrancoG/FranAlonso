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
4. For SwiftUI scope, discover and inspect affected screens in supported `Large`, `XXX Large` and `AX 5` variants,
   including for functional delivery, and record ADR 0022 evidence. Use representative states/appearances and apply
   ADR 0029 to the remaining exhaustive matrix when the approved scope uses progressive validation.
5. Launch `$franalonso-review-ios-standards` read-only. In parallel, launch `$franalonso-review-accessibility` when UI, previews,
   visual resources, localization or accessibility changed.
6. Fix valid findings that block the current gate; record eligible deferrals under ADR 0029. Repeat only the affected
   audit; repeat both for cross-scope corrections.
7. Run repository governance validators and inspect `git diff --check` plus secret-sensitive paths.

## Reconciliation

1. Update `docs/progress/phase-XX.md` with scope, RED/GREEN, build/tests/diagnostics, previews/accessibility, audits,
   remaining work and blockers.
2. Keep `docs/Progress.md` to a short current snapshot.
3. Reconcile Linear with the real state. Do not mark Done when delivery or a gate required for that delivery remains.
   Under ADR 0029, functional delivery for the demo may close a subphase only after its authorized delivery and the
   explicit transfer of deferred accessibility work to a linked issue. The phase remains open while integral validation
   is pending; existing open work is not transferred automatically.
4. Verify Obsidian only when a separate note outside the repo is an approved source; the repo-root vault needs no copy.

Use [references/closeout-output.md](references/closeout-output.md) for the handoff.

## Progressive accessibility validation

ADR 0029 preserves accessible construction, static/focused review, representative affected previews and technical
validation. Only the exhaustive/manual matrix and recorded accessibility defects may be deferred. The linked issue
must identify the owner, retained evidence, remaining checks/defects and trigger: feedback and stabilization of each
flow, always before the first candidate for real use. Preserve `Falla`, `Pendiente` and `Limitado`; deferral is neither
`N/A` nor a pass. Reuse accepted evidence and retest by impact.

Data integrity, data loss, privacy, functional regressions and defects preventing operation of the demo remain blocking.
A pass for the functional gate never establishes a pass for integral accessibility validation.

## Delivery boundary

Do only the delivery action explicitly requested. “Commit and push” does not authorize PR, merge, branch deletion,
Linear Done, live activation or the next subphase.
