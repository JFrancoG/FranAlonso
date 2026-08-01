# Development Guide

This guide is the mandatory execution protocol for every subphase in `docs/specs/`. Architecture and product rules live in [01_constitution.md](specs/01_constitution.md); decisions live in [ADRs](ADRs/README.md); current status lives in [Progress.md](Progress.md).

## 1. Preflight

1. Read `AGENTS.md`, this guide, the constitution, the active phase spec, and applicable accepted ADRs.
2. Inspect the real project structure, targets, deployment targets, SDK, Swift version, concurrency settings, dependencies, tests, and working-tree state.
3. Before proposing or implementing a technical solution, verify it against the inspected project and current primary sources. Use repository specs and accepted ADRs first, then official Apple, Swift, Firebase, or other applicable vendor documentation; cite the evidence instead of relying on model memory or search snippets.
4. Before writing executable code, send the source-backed proposal to a fresh `$review-ios-standards` subagent in read-only mode to verify applicability, alternatives, and risks. If subagents are unavailable, perform the same review as a separate pass and record the lack of multi-agent isolation. This pre-implementation review does not replace the applicable post-implementation specialist audits.
5. Before changing known-working code outside an already exact approved request, present the concrete change, rationale, behavioral impact, risks, affected scope, and alternatives, then wait for explicit owner confirmation. A request naming that exact change is confirmation; it does not authorize adjacent cleanup.
6. Preserve unrelated work and keep the subphase diff narrowly scoped.
7. Use Xcode MCP first for project inspection, builds, tests, previews, and diagnostics. If unavailable, report the limitation and ask the user to enable it; never substitute `xcodebuild` or XcodeBuildMCP silently.
8. Use Cupertino MCP when Apple API availability, Observation, SwiftData, SwiftUI, or concurrency guidance is uncertain.

## 2. TDD

When a subphase changes executable behavior, code, or project configuration:

1. Write the Swift Testing behavior test first.
2. Confirm RED for the expected reason.
3. Implement the minimum change for GREEN.
4. Refactor with the affected suite green only inside the approved scope; propose and await confirmation before any additional cleanup of working code.
5. Use deterministic doubles: no real Firestore or Storage; use an in-memory `ModelContainer` for SwiftData.

Write or update DocC after GREEN and refactoring, when the contract is stable enough to describe accurately. Documentation must not be used to specify behavior that the implementation and tests do not provide.

Record RED and GREEN evidence in the PR or subphase log. Do not create XCTest, XCUITest, or native UI tests.

For documentation-only work, including changes limited to DocC comments, and for manual-QA or distribution subphases, do not create artificial tests. Record `N/A` with a reason and provide proportional evidence such as link validation, documentation diagnostics, representative Quick Help inspection, a manual checklist, configuration inspection, a distributed-build smoke check, or artifact verification. Any executable code fix discovered during those tasks returns to TDD.

## 3. Implementer Validation

- Build every affected target without warnings through Xcode MCP when code or project configuration changed.
- Run new tests and all previously affected tests; use a justified `N/A` only when no executable target changed.
- Verify that the proposal cites applicable current primary sources and that any change to known-working code has exact prior owner approval.
- Review strict concurrency, actor isolation, cancellation, availability, and modern API selection. Internal structs and enums rely on inferred `Sendable` when the compiler can prove it; actors never repeat it; explicit conformances require a demonstrated public or generic boundary.
- Review declarations together with their call sites for native Swift construction. Reject mechanically translated ceremonial patterns and abstractions without a demonstrated responsibility, invariant, boundary, or reuse; prefer a direct Swift form when it expresses the same contract. Keep only the most specific protocol in each conformance list and reject inherited redundancies such as `Equatable` alongside `Hashable`, unless a conditional or generic boundary requires both and documents why.
- Enforce the 120-column Swift signature rule from `AGENTS.md`: keep declarations with at most three simple parameters on one line when the complete signature fits; use one-parameter-per-line vertical formatting for longer, four-or-more-parameter, or complex signatures, without hybrid wrapping. Apply it only to new or touched signatures unless a separate formatting-only cleanup is approved.
- Keep concrete, deterministic, dependency-free Data-to-Domain conversions on extensions of the Data-owned DTO or persistent model. Prefer `toDomain()` for reconstruction and an unlabeled conversion initializer for the reverse direction; never expose Data representations from Domain declarations. Require a `Mapper` to justify owned dependencies, configuration, schema versioning, policy, or interchangeable strategies rather than serving as a stateless function container.
- Reject a project-owned case-less `enum` used only to qualify static members. Select a semantic replacement from the call sites: an operation or extension on its owning type, a real service or value used in composition, or a free declaration with the narrowest workable access when no type owns it. Do not replace the pattern mechanically with an unused stateless `struct`, and preserve case-less enums whose uninhabited value set is the actual modeled contract.
- Reject explicit `@preconcurrency`, `@unchecked Sendable`, `nonisolated(unsafe)`, direct GCD/Dispatch concurrency, callback-first concurrency, and equivalent compiler escape hatches unless the owner approved a source-backed exception before implementation.
- Require project-owned observable presentation reference types to use `@Observable`; reject `ObservableObject`, `@Published`, `@StateObject`, and `@ObservedObject`. Use `@State` for view ownership and `@Bindable` only for binding projections.
- Require Views to render state and call semantic ViewModel actions only. Reject validation, filtering, calculation, persistence, networking, and business decisions in `body`, modifiers, or action closures.
- For a SwiftData insert, update, or delete tied to the main context, require the View to obtain `@Environment(\.modelContext)` and pass it to the relevant `@MainActor` ViewModel function. The View must not invoke context operations or store it; the ViewModel treats it as an ephemeral operation parameter and does not cross it to another actor. Presentation owns only the injected closure signature over a Domain value and `ModelContext`; App composes it from a Data adapter that owns mapping, context operations, and local-first behavior.
- Require one `View`-conforming type per Swift file, trailing-closure syntax for unambiguous SwiftUI APIs, and `@ViewBuilder` only at genuine multi-child or heterogeneous composition boundaries.
- Require `@ScaledMetric(relativeTo:)` for explicit numeric dimensions of significant non-text content that should follow Dynamic Type. Do not double-scale system-adaptive metrics; document deliberately fixed dimensions.
- Reject APIs deprecated by the active SDK and direct project-owned Objective-C/legacy choices such as explicit `@objc`, selectors, selector-based `NotificationCenter`, `DateFormatter`, and `NSRegularExpression` unless a documented lack of a modern compatible alternative was approved in advance.
- Review every struct changed by the subphase: rely on its synthesized memberwise initializer when sufficient; remove assignment-only initializers; use a named static factory only when its name adds domain, preset, or composition meaning; and keep meaningful validating, dependency-injection, composition, and `Decodable` initializers in same-file extensions. Neither an initializer nor a factory may expose a synthesized path that bypasses validation, and post-construction validation is not a substitute for an invariant.
- Review DocC for each new or modified semantic production API regardless of access level. Require concise English documentation for Domain types and contracts, Repository and UseCase requirements, policies, semantic factories, validating initializers, state transitions, and non-obvious throwing, asynchronous, or mutating operations. Include parameters, return values, errors, invariants, units, effects, idempotency, or cancellation only when meaningful; reject comments that restate the declaration, contradict tests, or cover obvious properties, view boilerplate, mechanical `Codable`, trivial private helpers, or tests without adding context.
- Review String Catalog coverage, loading/empty/error states, and deterministic previews for UI work. Every `View` has a same-file `#Preview` using the shared `PreviewModifier` trait with an in-memory test `ModelContainer` and deterministic, idempotent, navigable data.
- For every affected screen, call Xcode MCP `RenderPreview` once to discover supported overrides, then render and inspect `Large`, `XXX Large`, and `AX 5` when available. Record snapshot paths/results and any semantic or manual accessibility validation still pending.
- Follow [LOCALIZATION_GUIDE.md](LOCALIZATION_GUIDE.md) for semantic keys, generated symbols, translator context, and source-language rules.
- Run `git diff --check` when Git is available and inspect the complete diff. Until this directory is initialized as a Git repository, record that limitation in `docs/Progress.md` and the review evidence.
- Update ADRs and documentation whenever contracts or decisions change.

## 4. Specialized Independent Review Gate

After implementer validation:

1. Spawn a fresh subagent with `$review-ios-standards` in read-only mode for architecture, dependencies, Observation, SwiftData/Firestore, concurrency, testing, ADRs, and delivery evidence.
2. If the diff affects Views, Screens, styles, visual resources, String Catalogs, preview fixtures, or accessibility, spawn a second fresh subagent in parallel with `$review-swiftui-accessibility`. If there is no SwiftUI scope, record that gate as `N/A`.
3. Give each reviewer only the repository path, its exact scope, cited primary-source evidence, prior approval, and relevant build/test/preview evidence.
4. Do not let either reviewer edit files, change Git state, commit, push, or resolve its own findings.
5. Require independent verification within each assigned scope. Fix valid findings in the implementer context; reject findings only with evidence, then re-run affected validation.
6. After corrections, repeat only the specialist audit whose scope changed. Repeat both only when a correction crosses architecture and SwiftUI/accessibility boundaries.

Reference prompt:

```text
Act only as an independent read-only reviewer. Use <SKILL> to audit
subphase <ID> in <REPOSITORY> within this scope: <SCOPE>.
Available primary-source, approval and validation evidence: <EVIDENCE>.
Do not modify files or Git. Report severity, file, line, violated rule,
evidence, and remediation direction.
```

If subagents are unavailable, execute each applicable skill as a separate pass and state that multi-agent isolation was unavailable.

## 5. Definition of Done

- [ ] Agreed scope is complete and no hidden work remains.
- [ ] The solution is backed by cited current primary sources rather than model memory, and the reviewer independently verified their applicability.
- [ ] A fresh read-only reviewer audited the source-backed proposal before executable code was written, or unavailable multi-agent isolation is documented.
- [ ] Every modification to known-working code is inside an exact owner-approved proposal; no opportunistic cleanup was added.
- [ ] RED/GREEN evidence exists, or `N/A` is justified for a non-executable subphase.
- [ ] New and previously affected tests pass, or `N/A` is justified.
- [ ] Affected targets build without warnings through Xcode MCP, or `N/A` is justified.
- [ ] Domain/Data/Presentation/App boundaries are respected.
- [ ] Base value and Domain models use `Identifiable`, `Codable`, and `Equatable` whenever semantically possible, with any exception justified.
- [ ] Declarations and call sites use native Swift constructions; abstractions have a demonstrated responsibility, invariant, boundary, or reuse, and conformance lists do not repeat inherited protocols.
- [ ] New and touched Swift signatures follow the 120-column horizontal-first rule, with vertical formatting reserved for long, four-or-more-parameter, or complex declarations.
- [ ] Stateless concrete Data/Domain conversions live on Data-owned representation extensions; any `Mapper` owns a documented dependency, configuration, versioning, policy, or strategy responsibility, and Domain knows no Data type.
- [ ] No project-owned case-less enum is used solely as a static namespace; any uninhabited enum models an actual impossible-value contract, and replacements are semantic rather than mechanical.
- [ ] Structs keep explicit initializers out of the primary declaration; redundant assignment-only initializers are absent; named factories add real semantic meaning; and validating initializers or factories cannot be bypassed through synthesized memberwise construction or replaced by post-construction validation.
- [ ] ViewModels remain screen facades; Stores are justified and do not duplicate state.
- [ ] Views contain no business, persistence, networking, validation, filtering, or calculation; actions only call the ViewModel.
- [ ] SwiftData UI mutations pass the environment `ModelContext` to the relevant `@MainActor` ViewModel function without operating on or storing it in the View, and the context never crosses actors.
- [ ] The contextual mutation uses the App-composed `@MainActor` closure over Domain + `ModelContext`; Data retains mapping, CRUD, local-first behavior, and no dependency on Presentation.
- [ ] Each Swift file declares at most one `View` type; SwiftUI closure syntax and `@ViewBuilder` use follow the project rules.
- [ ] Significant custom non-text dimensions follow Dynamic Type through `@ScaledMetric`, with automatic or deliberately fixed exceptions justified.
- [ ] Every `View` has a same-file `#Preview` using the shared `PreviewModifier` and deterministic in-memory sample data; affected screens were inspected at supported `Large`, `XXX Large`, and `AX 5` variants.
- [ ] Concurrency, cancellation, inferred `Sendable`, availability, and localization are reviewed; actors do not repeat conformance and any explicit value-type conformance is justified by a public or generic boundary.
- [ ] Project-owned concurrent work uses Swift Concurrency with `async`/`await`; no unapproved GCD/callback-first path or strict-concurrency escape hatch was added.
- [ ] Project-owned observable presentation types use `@Observable`; no `ObservableObject`, `@Published`, `@StateObject`, or `@ObservedObject` was added.
- [ ] SwiftData/Firestore invariants and idempotency are covered when applicable.
- [ ] No XCTest, XCUITest, `JSONSerialization`, deprecated API, unapproved Objective-C/legacy choice, or unapproved dependency was added.
- [ ] ADRs and documentation are current.
- [ ] New or modified semantic production APIs have accurate, non-redundant DocC coverage; documented contracts agree with implementation and tests.
- [ ] The final scope contains no accidental changes.
- [ ] The `$review-ios-standards` architecture/data/concurrency audit has no open valid findings.
- [ ] The `$review-swiftui-accessibility` audit has no open valid findings, or is explicitly `N/A` because the diff has no UI scope.
- [ ] Valid corrections were rechecked only by the affected specialist reviewer, with both repeated only for cross-scope changes.
- [ ] `docs/Progress.md` reflects the new state, evidence, next subphase, and blockers.
