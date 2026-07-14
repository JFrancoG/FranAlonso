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

Use explicit suffixes: `UseCase`, `Repository`, `DTO`, `Model`, `DataSource`, `Mapper`, `PersistenceActor`, `SyncEngine`, `SyncPolicy`, `ViewModel`, `Store`, and `Screen`. Avoid ambiguous `Interactor`, `ModelLogic`, `Manager`, `Helper`, `Utils`, and `Common` types.

## Platform and Tools

Inspect the real deployment target, SDK, Swift version, and concurrency settings before selecting APIs. Use the modern compatible API; do not raise targets or adopt beta-only APIs implicitly. Treat warnings as errors.

Never use `xcodebuild` for builds, tests, previews, or diagnostics. Use Apple's official Xcode MCP and the `xcode-mcp` skill. If unavailable, ask the user to enable it. Use Cupertino MCP when Apple API availability or guidance is uncertain.

## Data, Concurrency, and Testing

SwiftData is the local source of truth; Firestore is the temporary remote source. Keep Firebase SDK imports inside Data/Infrastructure. Auth, Firestore, and Storage must remain replaceable by Vapor; Analytics and Crashlytics stay behind independently replaceable telemetry contracts and must never receive PII or business payloads. Sync must be offline-first, bidirectional, idempotent, conflict-aware, and recoverable. Use `@ModelActor` outside MainActor; never pass live SwiftData models across actors. Apply `Sendable`, cancellation, and structured concurrency. `@unchecked Sendable` requires an accepted ADR and tests.

Use TDD with Swift Testing only. Use deterministic Firebase and telemetry doubles plus in-memory `ModelContainer` instances. Serialize with Codable, never `JSONSerialization`; place visible text in `.xcstrings`.

After each subphase, run validation through Xcode MCP when executable work changed, then launch a read-only subagent with `$review-ios-standards`. Fix valid findings and request a second full-diff audit before marking the subphase complete.
