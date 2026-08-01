# Repository Guidelines

## Source of Truth

Read `docs/DEVELOPMENT_GUIDE.md`, `docs/specs/01_constitution.md`, the active phase spec, and applicable accepted ADRs before changing code. `docs/specs/00_index.md` defines phase order. Update `docs/Progress.md` after every subphase with evidence, remaining work, and blockers.

## Evidence and Change Approval

Never propose or implement a technical solution from model memory alone. Inspect the real code and configuration first, then corroborate the proposal with current primary sources: repository specs and accepted ADRs first, followed by official Apple, Swift, Firebase, or other applicable vendor documentation. Cite the evidence used; search snippets, remembered guidance, and unsourced secondary posts are not approval. Before executable code is written, a fresh read-only peer must verify that the cited sources apply and that viable alternatives were considered; this proposal review does not replace the applicable post-implementation specialist audits.

Do not refactor, replace, or otherwise alter known-working code outside the exact change already approved by the owner. First present the concrete change, rationale, behavioral impact, risks, and affected scope, then wait for explicit confirmation. A request that already names and approves that exact change counts as confirmation; a broader task does not authorize opportunistic cleanup.

## Project Structure

- `FranAlonso/`: application source and resources.
- `FranAlonsoTests/`: Swift Testing unit and integration tests.
- `docs/specs/`: executable specifications `00` through `19`; phases 01–18 are the MVP and phase 19 is post-MVP.
- `docs/ADRs/`: proposed and accepted architecture decisions.
- `docs/DEVELOPMENT_GUIDE.md`: mandatory subphase workflow and Definition of Done.
- `docs/PULL_REQUEST_CHECKLIST.md`: delivery checklist.

The template `FranAlonsoUITests` target has been removed. Do not add XCTest or XCUITest coverage.

## Architecture and Naming

Organize by feature, then `Domain`, `Data`, and `Presentation`; compose concrete dependencies in `App`. Domain must not import SwiftUI, SwiftData, Firebase, or UIKit. Every screen keeps an `@Observable @MainActor` ViewModel. Extract an `@Observable @MainActor` Store only for a cohesive responsibility or demonstrated complexity; the ViewModel owns it and must not duplicate its state. Project-owned observable presentation reference types use the `@Observable` macro; do not introduce `ObservableObject`, `@Published`, `@StateObject`, or `@ObservedObject`. A view uses `@State` to own an observable model and `@Bindable` only when it needs a binding projection.

Views are declarative: `body`, modifiers, and action closures render state and make semantic calls to the ViewModel, with no validation, filtering, calculation, persistence, networking, or business decisions. Pure invariants remain in Domain/UseCases and the ViewModel coordinates the screen intent. When an insert, update, or delete uses SwiftData's main context, the View captures `@Environment(\.modelContext)` and passes it to the relevant `@MainActor` ViewModel function. The View never calls context operations or stores the context; the ViewModel treats it as an ephemeral operation parameter and never crosses it to another actor. This is the only permitted SwiftData type at the Presentation boundary. Presentation declares the injected `@MainActor` operation as a closure over a Domain value and `ModelContext`; `App` composes it from a Data adapter, which retains persistent models, mapping, context operations, and local-first policies. Domain never receives the context and Data never imports Presentation.

Whenever semantically possible, base value and Domain models conform to `Identifiable`, `Codable`, and `Equatable`, with stable immutable identity. Internal structs and enums rely on compiler-inferred `Sendable` only when every stored property or associated value permits it. Actors conform implicitly and never repeat `Sendable`. Add an explicit or conditional conformance only when the compiler requires it at a public or generic boundary, document that reason, and never use conformance to hide non-sendable state.

Design project-owned code from Swift's native language constructs, standard library, and API Design Guidelines; never translate ceremonial patterns mechanically from another language. Every abstraction must demonstrate a real responsibility, invariant, boundary, or reuse in its declaration and call sites; prefer the direct Swift construction when it expresses the same contract with less ceremony. In a conformance list, declare only the most specific protocol and do not repeat an inherited protocol such as `Equatable` alongside `Hashable`, unless the compiler requires both at a conditional or generic boundary and the reason is documented.

Keep concrete, deterministic conversions that have no dependencies, configuration, versioning, policy, or interchangeable strategy on extensions of the Data-owned representation. Use `toDomain()` to reconstruct a Domain value and an unlabeled conversion initializer such as `ClientDTO(client)` for the reverse direction. Never add DTO or persistent-model knowledge to a Domain declaration. Introduce a `Mapper` only when the type owns one of those real responsibilities and its call sites demonstrate the need; do not create a stateless mapper merely to group conversion functions.

Do not use a project-owned case-less `enum` merely as a namespace for static members. Treat it as a namespace when the type appears only as the qualifier in `Type.member` calls. Choose the replacement from the semantics: behavior on the type it operates on or an extension of that owner, a real service or value used in composition, or a free function or constant with the narrowest workable access when no type owns it. A case-less enum remains valid when its uninhabited set of values is itself the modeled contract. Do not mechanically replace it with an otherwise unused stateless `struct`; this is a project style rule, not a Swift language restriction.

Keep a struct's primary declaration free of explicit initializers. Use the compiler-generated memberwise initializer when it already expresses the contract, and remove initializers that only assign every argument to its matching stored property. Choose the construction API by meaning: use a named static factory when its name communicates a domain state, preset, or composition more clearly than `init`; otherwise keep meaningful validating, dependency-injection, composition, and `Decodable` initializers in same-file extensions. Do not replace construction-time invariants with a post-construction `isValid` property or `validate()` method. A validating initializer or factory must remain the only accessible construction path for that contract: when synthesis could bypass it, use private backing storage plus read-only computed API. Reviewers must check these tradeoffs in production and test structs rather than flagging every custom initializer mechanically.

Document semantic production APIs with concise English DocC comments regardless of access level. Cover new or modified Domain types, Repository and UseCase contracts, policies, semantic factories, validating initializers, state transitions, and non-obvious throwing, asynchronous, or mutating operations. Explain invariants, units, effects, idempotency, cancellation, parameters, return values, and thrown errors only when they add information beyond the declaration. Do not document obvious stored properties, view boilerplate, mechanical `Codable` implementations, trivial private helpers, or tests merely for coverage. Documentation must agree with the implementation and tests and must not restate symbol names.

Use explicit suffixes: `UseCase`, `Repository`, `DTO`, `Model`, `DataSource`, `Mapper` when justified by an owned responsibility, `PersistenceActor`, `SyncEngine`, `SyncPolicy`, `ViewModel`, `Store`, and `Screen`. Avoid ambiguous `Interactor`, `ModelLogic`, `Manager`, `Helper`, `Utils`, and `Common` types.

## Swift Source Formatting

Use 120 columns, including indentation, as the preferred maximum width. Keep a `func`, `init`, or `subscript` declaration on one line when its complete signature fits within that width and has at most three simple parameters. The complete signature includes attributes, effects such as `async` and `throws`, the return type, and the opening brace when present.

Use vertical formatting when a signature exceeds 120 columns, has four or more parameters, or contains complex parameters such as closures or function types, nested generics or tuples, closure attributes, multiline default values, or generic requirements. In vertical form, place one parameter per line, align the closing delimiter with the declaration, and avoid hybrid wrapping. Apply this rule to new code and touched signatures; keep historical formatting cleanup separate from functional changes.

## SwiftUI Quality and Accessibility

Keep one type conforming to `View` per Swift source file; extracted subviews live in their own files. Use trailing-closure and multiple-trailing-closure syntax for SwiftUI initializers and modifiers whenever the API is unambiguous. Use `@ViewBuilder` only at real composition boundaries with multiple children or heterogeneous branches; never declare it redundantly on `body`, use it for a single expression, or hide an oversized View behind it.

Use `@ScaledMetric(relativeTo:)` for every explicit numeric dimension of significant non-text content that should follow Dynamic Type. Do not double-scale system-adaptive metrics, and document any deliberately fixed size. Every `View` type has at least one `#Preview` in its own file, and every preview applies the shared `PreviewModifier` trait that installs an in-memory test `ModelContainer` with deterministic, idempotent, navigable sample data and no live services. For each affected screen, use Xcode MCP `RenderPreview` to discover supported variants, then render and inspect `Large`, `XXX Large`, and `AX 5` when available. Snapshot validation does not replace semantic accessibility review or a manual VoiceOver pass when required.

Probabilistic assistants return closed Domain proposals and may only read, navigate, or fill reversible drafts. They never receive direct persistence/binding access or invoke mutating UseCases; Fran reviews and saves through the normal visual flow.

## Platform and Tools

Inspect the real deployment target, SDK, Swift version, and concurrency settings before selecting APIs. Use the modern compatible API; do not raise targets or adopt beta-only APIs implicitly. Treat warnings as errors. Do not use APIs deprecated or unavailable in the active SDK. In project-owned code, also do not introduce direct Objective-C runtime or legacy Foundation/Dispatch choices when a compatible Swift-native API exists, including explicit `@objc`, `Selector`/`#selector`, selector-based `NotificationCenter`, direct GCD/`DispatchQueue`, `DateFormatter`, and `NSRegularExpression`. These are project-prohibited legacy or interoperability choices, not necessarily SDK-deprecated symbols. Any unavoidable use requires a source-backed proposal and explicit owner approval before implementation.

Never use `xcodebuild` for builds, tests, previews, or diagnostics. Use Apple's official Xcode MCP and the `xcode-mcp` skill. If unavailable, ask the user to enable it. For preview variants, first use the values returned by `RenderPreview`; do not invent override names. Use Cupertino MCP when Apple API availability or guidance is uncertain.

## Data, Concurrency, and Testing

SwiftData is the local source of truth; Firestore is the temporary remote source. Keep Firebase SDK imports confined to concrete adapters owned by Data; `Infrastructure` is not a required directory name. Auth, Firestore, and Storage must remain replaceable by Vapor; Analytics and Crashlytics stay behind independently replaceable telemetry contracts and must never receive PII or business payloads. Sync must be offline-first, bidirectional, idempotent, conflict-aware, and recoverable. Use `@ModelActor` outside MainActor; never pass live SwiftData models across actors.

All project-owned asynchronous and concurrent code uses Swift Concurrency end to end: `async`/`await`, structured child tasks, actors or global actors, `AsyncSequence`, sendability, cooperative cancellation, and checked continuations only at isolated adapter boundaries. Do not introduce direct GCD, dispatch groups or semaphores, `OperationQueue`, or callback-first concurrency.

Never add explicit `@preconcurrency`, `@unchecked Sendable`, `nonisolated(unsafe)`, or an equivalent unsafe opt-out merely to make strict-concurrency code compile. Safe `nonisolated` remains valid when it accurately describes isolation. If current primary documentation and all statically safe designs still leave no viable solution, stop and propose the exact exception, rejected alternatives, ownership or synchronization invariant, scope, ADR, and focused tests; wait for explicit owner approval before writing it.

The MVP assistant uses stable iOS 26 Apple APIs on-device with no cloud fallback or background listening. Audio, transcripts, prompts, responses, and conversational state are ephemeral and never enter persistence, logs, or telemetry. A remote provider requires its own accepted ADR before executable work.

Use TDD with Swift Testing only. Use deterministic Firebase and telemetry doubles plus in-memory `ModelContainer` instances. Serialize with Codable, never `JSONSerialization`; place visible text in `.xcstrings`.

After each subphase, run validation through Xcode MCP when executable work changed, then launch a read-only `$review-ios-standards` subagent for architecture, data, concurrency, testing, and governance. When the diff affects SwiftUI, visual resources, previews, localization, or accessibility, launch a separate read-only `$review-swiftui-accessibility` subagent in parallel. Fix valid findings and repeat only the specialist audit whose scope changed; repeat both only for cross-scope corrections.
