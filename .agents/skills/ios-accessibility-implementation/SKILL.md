---
name: ios-accessibility-implementation
description: Implement or fix SwiftUI screens and reusable components in FranAlonso so applicable WCAG 2.2 A/AA criteria, WCAG2ICT guidance, Apple accessibility conventions, and ADR 0022 evidence are addressed by construction. Use whenever UI, interaction, visual resources, localization, previews, or accessibility behavior changes.
---

# iOS Accessibility Implementation

Read ADR 0022 and `docs/accessibility/WCAG22_AA_IOS.md`. Apply only criteria relevant to the affected surface, but
classify every conditional criterion instead of silently ignoring it.

## Implement by construction

1. Start from native SwiftUI controls and semantics. Expose accurate label, value, hint only when useful, traits, state,
   actions, grouping and heading structure.
2. Keep the accessible name aligned with visible text so Voice Control can target it. Hide decoration, not information.
3. Define logical reading/focus order and restore focus after navigation, sheets, errors and destructive confirmation.
4. Announce meaningful asynchronous status and validation errors without moving focus unnecessarily.
5. Support Dynamic Type through AX 5 without clipping, overlap or lost actions. Scale significant custom geometry and
   avoid double-scaling system metrics.
6. Verify 44×44 pt interactive targets, contrast, non-color cues and four appearance combinations.
7. Provide simple alternatives to drag, multipoint, path-based, motion-only and time-dependent interactions.
8. Respect Increase Contrast, Differentiate Without Color, Reduce Motion and Reduce Transparency.
9. Support relevant orientations, iPad multitasking/window sizes, keyboard/pointer and RTL/localized long content.
10. Keep validation/business logic outside View and cover extracted behavior with Swift Testing.

## Evidence

- Render Xcode-supported `Large`, `XXX Large` and `AX 5` variants and inspect, not merely generate, each result.
- Use Accessibility Inspector and manual runtime passes for VoiceOver, Voice Control, Switch Control or Full Keyboard
  Access as applicable. Previews cannot prove these behaviors.
- Copy the per-screen evidence template from the matrix into `docs/progress/phase-XX.md`.
- Run the independent `$franalonso-review-accessibility` agent after implementation.

See [references/review-order.md](references/review-order.md) for a fast inspection sequence.
