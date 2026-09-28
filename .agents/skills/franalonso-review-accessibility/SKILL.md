---
name: franalonso-review-accessibility
description: Independently audit FranAlonso SwiftUI changes without editing for declarative boundaries, previews, Dynamic Type, localization, adaptive layout, and the criterion-by-criterion native accessibility objective accepted in ADR 0022. Use after UI, interaction, visual resources, String Catalogs, previews, or accessibility behavior changes.
---

# Review FranAlonso SwiftUI Accessibility

Operate strictly read-only. Do not edit files, change Git, publish, or resolve findings. Read `AGENTS.md`, ADR 0011, ADR
0022, ADR 0029, `docs/accessibility/WCAG22_AA_IOS.md`, the active spec and the exact diff.

## Audit

1. Limit scope to affected Views, ViewModels needed to verify delegation, styles, resources, localization and previews.
2. Verify declarative View boundaries, one `View` type per file, justified composition, scaling and deterministic previews.
3. Declare whether the gate is functional delivery for the demo or integral accessibility validation. Maintain the
   per-criterion and per-flow register; every A/AA row is applicable, conditional or `N/A` with reason. ADR 0029 permits
   deferring execution of exhaustive/manual checks, not changing their applicability or recorded result.
4. Audit names, roles, values, traits, grouping, headings, actions, order, focus, announcements and errors.
5. Audit Dynamic Type through AX 5, contrast/color, 44×44 pt project policy, motion/transparency preferences, orientation,
   window sizes, keyboard, gesture alternatives, localization and RTL.
6. Use Xcode MCP to discover preview overrides and inspect affected screens in supported `Large`, `XXX Large` and
   `AX 5` variants, including for the functional gate under ADR 0011. Use representative states/appearances; complete
   the remaining exhaustive matrix for integral validation. Reuse accepted evidence and retest by impact.
7. Separate static, preview, Inspector and manual runtime evidence. Unexecuted VoiceOver, Voice Control, Switch Control,
   keyboard, focus or announcements remain pending.
8. Do not claim WCAG certification or legal conformity. Audit the project's internal objective and its evidence.

Under ADR 0029, a functional gate may pass with deferred exhaustive/manual checks and known accessibility defects
only when a linked issue records their owner, evidence and recovery after feedback and stabilization of each flow,
before the first candidate for real use. Keep `Falla`, `Pendiente` and `Limitado` unchanged. Verify accessible
construction and static/focused review now; defects preventing operation of the demo still block. A functional pass
never implies integral accessibility passed. Privacy, data integrity and functional regression gates remain mandatory.

Read [references/output.md](references/output.md) before reporting.

## Limits

If no UI surface changed, return `N/A: sin alcance SwiftUI`. Prefer an enforced read-only sandbox. If unavailable, the
owner accepts an operationally read-only review only when a fresh independent agent receives an explicit
no-write/no-publish instruction and the orchestrator proves an identical deterministic digest of every Git tracked and
nonignored untracked file before and after. Any repository change, unreproducible digest or self-review blocks the gate.
