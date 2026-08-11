---
name: franalonso-start-subphase
description: Start a FranAlonso phase or subphase by verifying repository instructions, active specs and ADRs, Git and connector state, baseline evidence, Linear scope, primary sources, alternatives, risks, tests, and independent proposal review. Use before any executable implementation for a new phase, subphase, feature, fix, or chore in this repository.
---

# Start FranAlonso Subphase

Prepare an auditable proposal; do not implement product code during this skill.

## Gate

1. Read `AGENTS.md`, `docs/specs/01_constitution.md`, `docs/DEVELOPMENT_GUIDE.md`, the active spec and applicable
   accepted ADRs.
2. Inspect `git status`, branch, recent history and overlapping local changes. Preserve unrelated work.
3. Inspect the real target, SDK, Swift version, concurrency settings and relevant code/configuration.
4. Verify Xcode MCP. Verify Linear and compare its phase/subphase state with `docs/Progress.md`.
5. Establish the latest trustworthy build/test/diagnostic baseline without rerunning irrelevant work.
6. Research only unstable or uncertain technical choices, preferring repository authority and official primary sources.
7. Write the exact proposal: behavior, files/areas, alternatives, risks, TDD plan, validation and explicit exclusions.
8. Launch one fresh read-only proposal reviewer. Resolve valid findings before requesting owner approval.
9. Record blockers. Do not treat connector availability, local tests or scaffolding as live-service readiness.

Use [references/gate-output.md](references/gate-output.md) for the compact handoff shape.

## Stop conditions

Stop for owner direction before code if the proposal requires an unapproved ADR, dependency, unsafe concurrency escape,
target increase, cloud/live activation, destructive Git action or material scope expansion.

Approval authorizes only the presented implementation. Commit, push, PR, merge, Linear completion and the next subphase
remain separate actions.
