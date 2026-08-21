---
name: franalonso-review-accessibility
description: Independently audit FranAlonso SwiftUI changes without editing for declarative boundaries, previews, Dynamic Type, localization, adaptive layout, and the criterion-by-criterion native accessibility objective accepted in ADR 0022. Use after UI, interaction, visual resources, String Catalogs, previews, or accessibility behavior changes.
---

# Review FranAlonso SwiftUI Accessibility

Operate strictly read-only. Do not edit files, change Git, publish, or resolve findings. Read `AGENTS.md`, ADR 0011, ADR
0022, `docs/accessibility/WCAG22_AA_IOS.md`, the active spec and the exact diff.

## Audit

1. Limit scope to affected Views, ViewModels needed to verify delegation, styles, resources, localization and previews.
2. Verify declarative View boundaries, one `View` type per file, justified composition, scaling and deterministic previews.
3. Require a complete per-criterion and per-flow register; every A/AA row is applicable, conditional or `N/A` with reason.
4. Audit names, roles, values, traits, grouping, headings, actions, order, focus, announcements and errors.
5. Audit Dynamic Type through AX 5, contrast/color, 44×44 pt project policy, motion/transparency preferences, orientation,
   window sizes, keyboard, gesture alternatives, localization and RTL.
6. Use Xcode MCP to discover preview overrides and inspect supported `Large`, `XXX Large` and `AX 5` renders.
7. Separate static, preview, Inspector and manual runtime evidence. Unexecuted VoiceOver, Voice Control, Switch Control,
   keyboard, focus or announcements remain pending.
8. Do not claim WCAG certification or legal conformity. Audit the project's internal objective and its evidence.

Read [references/output.md](references/output.md) before reporting.

## Limits

If no UI surface changed, return `N/A: sin alcance SwiftUI`. Prefer an enforced read-only sandbox. If unavailable, the
owner accepts an operationally read-only review only when a fresh independent agent receives an explicit
no-write/no-publish instruction and the orchestrator proves an identical deterministic digest of every Git tracked and
nonignored untracked file before and after. Any repository change, unreproducible digest or self-review blocks the gate.
