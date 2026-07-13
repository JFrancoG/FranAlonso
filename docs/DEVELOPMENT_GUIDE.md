# Development Guide

This guide is the mandatory execution protocol for every subphase in `docs/specs/`. Architecture and product rules live in [01_constitution.md](specs/01_constitution.md); decisions live in [ADRs](ADRs/README.md); current status lives in [Progress.md](Progress.md).

## 1. Preflight

1. Read `AGENTS.md`, this guide, the constitution, the active phase spec, and applicable accepted ADRs.
2. Inspect the real project structure, targets, deployment targets, SDK, Swift version, concurrency settings, dependencies, tests, and working-tree state.
3. Preserve unrelated work and keep the subphase diff narrowly scoped.
4. Use Xcode MCP first for project inspection, builds, tests, previews, and diagnostics. If unavailable, report the limitation and ask the user to enable it; never substitute `xcodebuild` or XcodeBuildMCP silently.
5. Use Cupertino MCP when Apple API availability, Observation, SwiftData, SwiftUI, or concurrency guidance is uncertain.

## 2. TDD

When a subphase changes executable behavior, code, or project configuration:

1. Write the Swift Testing behavior test first.
2. Confirm RED for the expected reason.
3. Implement the minimum change for GREEN.
4. Refactor with the affected suite green.
5. Use deterministic doubles: no real Firestore or Storage; use an in-memory `ModelContainer` for SwiftData.

Record RED and GREEN evidence in the PR or subphase log. Do not create XCTest, XCUITest, or native UI tests.

For documentation-only, manual-QA, or distribution subphases, do not create artificial tests. Record `N/A` with a reason and provide proportional evidence such as link validation, a manual checklist, configuration inspection, a distributed-build smoke check, or artifact verification. Any code fix discovered during those tasks returns to TDD.

## 3. Implementer Validation

- Build every affected target without warnings through Xcode MCP when code or project configuration changed.
- Run new tests and all previously affected tests; use a justified `N/A` only when no executable target changed.
- Review strict concurrency, actor isolation, `Sendable`, cancellation, availability, and deprecated APIs.
- Review String Catalog coverage, loading/empty/error states, and deterministic previews for UI work.
- Run `git diff --check` when Git is available and inspect the complete diff. Until this directory is initialized as a Git repository, record that limitation in `docs/Progress.md` and the review evidence.
- Update ADRs and documentation whenever contracts or decisions change.

## 4. Independent Review Gate

After implementer validation:

1. Spawn a fresh subagent and require `$review-ios-standards` in read-only mode.
2. Give it only the repository path, exact scope, and build/test evidence.
3. Do not let the reviewer edit files, change Git state, commit, push, or resolve its own findings.
4. Fix valid findings in the implementer context; reject findings only with evidence.
5. Re-run affected validation.
6. Request a second independent audit of the complete diff.

Reference prompt:

```text
Act only as an independent read-only reviewer. Use $review-ios-standards
to audit subphase <ID> in <REPOSITORY>. Available evidence: <EVIDENCE>.
Do not modify files or Git. Report severity, file, line, violated rule,
evidence, and remediation direction.
```

If subagents are unavailable, execute the same skill as a separate pass and state that multi-agent isolation was unavailable.

## 5. Definition of Done

- [ ] Agreed scope is complete and no hidden work remains.
- [ ] RED/GREEN evidence exists, or `N/A` is justified for a non-executable subphase.
- [ ] New and previously affected tests pass, or `N/A` is justified.
- [ ] Affected targets build without warnings through Xcode MCP, or `N/A` is justified.
- [ ] Domain/Data/Presentation/App boundaries are respected.
- [ ] ViewModels remain screen facades; Stores are justified and do not duplicate state.
- [ ] Concurrency, cancellation, `Sendable`, availability, and localization are reviewed.
- [ ] SwiftData/Firestore invariants and idempotency are covered when applicable.
- [ ] No XCTest, XCUITest, `JSONSerialization`, deprecated API, or unapproved dependency was added.
- [ ] ADRs and documentation are current.
- [ ] The final scope contains no accidental changes.
- [ ] First independent audit completed.
- [ ] Valid findings were resolved and the second audit has no open valid findings.
- [ ] `docs/Progress.md` reflects the new state, evidence, next subphase, and blockers.
