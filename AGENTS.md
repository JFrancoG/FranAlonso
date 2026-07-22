# Repository Guidelines

## Source of Truth

Read `docs/DEVELOPMENT_GUIDE.md`, `docs/specs/01_constitution.md`, the active phase spec, and applicable accepted ADRs before changing code. `docs/specs/00_index.md` defines phase order. Update `docs/Progress.md` after every subphase with evidence, remaining work, and blockers.

## Project Structure

- `FranAlonso/`: application source and resources.
- `FranAlonsoTests/`: Swift Testing unit and integration tests.
- `docs/specs/`: executable specifications `00` through `17`.
- `docs/ADRs/`: proposed and accepted architecture decisions.
- `docs/DEVELOPMENT_GUIDE.md`: mandatory subphase workflow and Definition of Done.
- `docs/PULL_REQUEST_CHECKLIST.md`: delivery checklist.

The template `FranAlonsoUITests` target has been removed. Do not add XCTest or XCUITest coverage.

## Architecture and Naming

Organize by feature, then `Domain`, `Data`, and `Presentation`; compose concrete dependencies in `App`. Domain must not import SwiftUI, SwiftData, Firebase, or UIKit. Every screen keeps an `@Observable @MainActor` ViewModel. Extract an `@Observable @MainActor` Store only for a cohesive responsibility or demonstrated complexity; the ViewModel owns it and must not duplicate its state.

Whenever semantically possible, base value and Domain models conform to `Identifiable`, `Codable`, and `Equatable`, with stable immutable identity. Internal model structs rely on inferred `Sendable` when all stored properties are sendable; declare it explicitly only when required by a public API boundary.

Keep a struct's primary declaration free of explicit initializers. Use the compiler-generated memberwise initializer when it already expresses the contract, and remove initializers that only assign every argument to its matching stored property. Choose the construction API by meaning: use a named static factory when its name communicates a domain state, preset, or composition more clearly than `init`; otherwise keep meaningful validating, dependency-injection, composition, and `Decodable` initializers in same-file extensions. Do not replace construction-time invariants with a post-construction `isValid` property or `validate()` method. A validating initializer or factory must remain the only accessible construction path for that contract: when synthesis could bypass it, use private backing storage plus read-only computed API. Reviewers must check these tradeoffs in production and test structs rather than flagging every custom initializer mechanically.

Use explicit suffixes: `UseCase`, `Repository`, `DTO`, `Model`, `DataSource`, `Mapper`, `PersistenceActor`, `SyncEngine`, `SyncPolicy`, `ViewModel`, `Store`, and `Screen`. Avoid ambiguous `Interactor`, `ModelLogic`, `Manager`, `Helper`, `Utils`, and `Common` types.

## Platform and Tools

Inspect the real deployment target, SDK, Swift version, and concurrency settings before selecting APIs. Use the modern compatible API; do not raise targets or adopt beta-only APIs implicitly. Treat warnings as errors.

Never use `xcodebuild` for builds, tests, previews, or diagnostics. Use Apple's official Xcode MCP and the `xcode-mcp` skill. If unavailable, ask the user to enable it. Use Cupertino MCP when Apple API availability or guidance is uncertain.

## Data, Concurrency, and Testing

SwiftData is the local source of truth; Firestore is the temporary remote source. Keep Firebase SDK imports inside Data/Infrastructure. Auth, Firestore, and Storage must remain replaceable by Vapor; Analytics and Crashlytics stay behind independently replaceable telemetry contracts and must never receive PII or business payloads. Sync must be offline-first, bidirectional, idempotent, conflict-aware, and recoverable. Use `@ModelActor` outside MainActor; never pass live SwiftData models across actors. Apply `Sendable`, cancellation, and structured concurrency. `@unchecked Sendable` requires an accepted ADR and tests.

Use TDD with Swift Testing only. Use deterministic Firebase and telemetry doubles plus in-memory `ModelContainer` instances. Serialize with Codable, never `JSONSerialization`; place visible text in `.xcstrings`.

After each subphase, run validation through Xcode MCP when executable work changed, then launch a read-only subagent with `$review-ios-standards`. Fix valid findings and request a second full-diff audit before marking the subphase complete.
