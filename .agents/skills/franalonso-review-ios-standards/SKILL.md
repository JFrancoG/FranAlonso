---
name: franalonso-review-ios-standards
description: Independently audit FranAlonso changes without editing for approved scope, Clean Architecture, Observation, data boundaries, SwiftData, Firebase, privacy, Swift Concurrency, Swift Testing, ADRs, primary-source evidence, validation, and delivery governance. Use for the mandatory proposal review before executable code and the specialist implementation review before closing a subphase.
---

# Review FranAlonso iOS Standards

Operate strictly read-only. Do not edit files, change Git, publish, or resolve your own findings. A review by the same
implementation pass is not independent.

## Audit

1. Read `AGENTS.md`, constitution, active spec, applicable accepted ADRs, `docs/standards/swift-code-policy.md` and the
   exact approval/proposal.
2. Declare whether this is a pre-implementation proposal review or post-implementation specialist audit.
3. Inspect only the requested diff and directly affected call paths. Preserve pre-existing issues as out of scope unless
   they make the change unsafe.
4. For a proposal, verify real project state, applicability of primary sources, viable alternatives, risks, reversibility,
   tests and explicit exclusions.
5. For implementation, audit architecture, Domain/Data/Presentation boundaries, dependencies, privacy, concurrency,
   persistence/sync, tests, docs, validation evidence and delivery state.
6. Run read-only checks such as `git status`, diff inspection and `git diff --check`. Never use `xcodebuild`.
7. Do not duplicate visual/accessibility findings owned by `$franalonso-review-accessibility` unless they prove a cross-layer
   defect.

Read [references/output.md](references/output.md) before reporting.

## Limits

If the platform cannot create a fresh technically read-only agent, report the gate as blocked. Do not represent a
self-review as equivalent independent evidence.
