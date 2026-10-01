# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Added

- 2026-10-01 | ✨ feat(assistant): add on-device service drafts
  Adds local Foundation Models classification and literal extraction for the isolated Develop service demo.
  Keeps proposals reversible, absent fields unchanged and persistence behind the existing visual Save action.

- 2026-09-30 | ✨ feat(services): prepare sale selection
  Filters active offerings and selects immutable commercial snapshots from the current local catalogue.

- 2026-09-30 | ✨ feat(services): select linked products
  Adds native type and active-product selection with recoverable drafts and contextual save validation.

- 2026-09-30 | ✨ feat(services): add catalogue screens
  Adds searchable commercial services, localized forms and repeatable linked-product demo data.

- 2026-09-29 | ✨ feat(services): coordinate list and form state
  Adds complete commercial drafts, exact localized decimals and protected contextual form sessions.

- 2026-09-29 | ✨ feat(services): validate linkable products
  Filters active products and rejects stale commercial links while preserving historical services.

- 2026-09-29 | ✨ feat(services): add catalogue commands
  Validates editable commercial profiles and preserves exact prices, current state and causal local acceptance.

- 2026-09-29 | ✨ feat(stock): observe local low-stock state
  Derives low-stock and recovery from an explicit minimum, sharing committed changes with catalogue observation.

- 2026-09-29 | ✨ feat(stock): add adjustment screens
  Adds contextual stock entry and withdrawal, protected retry sessions and repeatable demo balances.

- 2026-09-29 | ✨ feat(stock): add durable idempotent adjustments
  Preserves append-only movements across migration and restart, derives exact balances and protects unbound stores.

- 2026-09-29 | ✨ feat(products): add catalogue and product forms
  Adds searchable product screens, protected drafts, deactivation and an isolated demo catalogue.

- 2026-09-29 | ✨ feat(products): coordinate list and form state
  Adds observable list/form state, stable sessions and caller-context mutations with cancellation protection.
- 2026-09-29 | ✨ feat(products): add CRUD and local search
  Validates editable names, preserves inactive profiles and accepts causal local writes without restoring tombstones.
- 2026-09-29 | ✨ feat(demo): add reusable isolated client demo
  Includes repeatable in-memory clients, real consent flows, lost-response recovery and a localized demo marker.
- 2026-09-29 | ✨ feat(clients): add recoverable client activation
  Activates only from a retained initial-document receipt and preserves recovery, retries and concurrent edits.
- 2026-09-29 | ✨ feat(clients): integrate consent review flow
  Includes recoverable signing, concurrent-edit protection and progressive accessibility validation under ADR 0029.
- 2026-09-13 | ✨ feat(clients): persist signed documents
- 2026-09-13 | ✨ feat(clients): add versioned signed documents
- 2026-09-13 | ✨ feat(clients): add ephemeral signature capture

### Maintenance

- 2026-09-30 | 📦 build(xcode): apply recommended settings
  Records Xcode 27.2 upgrade checks and enables the nonlocalized-text analyzer in all four configurations.

- 2026-09-30 | 🔧 chore(app): organize files and update Firebase
  Groups App composition, startup, persistence, presentation and demo sources by responsibility.
  Updates the existing Firebase dependency to resolved 12.19.2 and its compatible transitive versions.

- 2026-09-10 | 📦 build(config): move app metadata to build settings

### Fixed

- 2026-09-30 | 🐛 fix(localization): complete English coverage
  Completes English translations and checks all 409 translatable entries in English and Spanish.
  Adds compiled-resource regression tests, preserves app identity per environment and aligns targets to iOS 27.

- 2026-09-10 | 🐛 fix(clients): improve confirmation and retry controls

### Documentation

- 2026-09-30 | 📝 docs(delivery): close App maintenance
  Records PR31, PLU-69 completion and verified branch cleanup after the App and Firebase delivery.

- 2026-09-30 | 📝 docs(delivery): close service selection
  Records PR30 delivery and the remaining phase10 accessibility gate.

- 2026-09-30 | 📝 docs(delivery): close linked product selector
  Records PR29 delivery and retained accessibility debt before service selection work.

- 2026-09-30 | 📝 docs(delivery): close service screens
  Records PR28, verified merge and branch cleanup before the linked-product selector.

- 2026-09-29 | 📝 docs(delivery): close service view models
  Records PR27, verified merge and branch cleanup before service screens.

- 2026-09-29 | 📝 docs(delivery): close linked-product contracts
  Records PR26, verified merge and branch cleanup before service view models.

- 2026-09-29 | 📝 docs(delivery): close service sync integration
  Records PR25, verified merge and branch cleanup before linked-product contracts.

- 2026-09-29 | 📝 docs(delivery): close service contracts
  Records PR24, verified merge, branch cleanup and the separate 10.2 integration gate.

- 2026-09-29 | 📝 docs(delivery): close low-stock observation

- 2026-09-29 | 📝 docs(delivery): close stock adjustment screens

- 2026-09-29 | 📝 docs(delivery): close stock adjustments

- 2026-09-29 | 📝 docs(delivery): close product screens
  Records PR20, functional closure and retained accessibility debt before stock adjustments.

- 2026-09-29 | 📝 docs(delivery): close product view models
- 2026-09-29 | 📝 docs(delivery): close product data subphases
- 2026-09-29 | 📝 docs(delivery): close PLU-46 after merge
- 2026-09-29 | 📝 docs(plan): publish the approved demo sequence
  Records ADR 0030, the reusable demo base, early Foundation Models Service draft and deferred optional-photo flow.
- 2026-09-29 | 📝 docs(delivery): close PLU-42 after merge
- 2026-09-29 | 📝 docs(delivery): record activation smoke
  Records the isolated activation/retry walkthrough, exact harness removal and PR #15 validation.
- 2026-09-29 | 📝 docs(delivery): close PLU-41 after merge
- 2026-09-13 | 📝 docs(delivery): close PLU-40 after merge
- 2026-09-13 | 📝 docs(delivery): close PLU-39 after merge

- 2026-09-13 | 📝 docs(delivery): record PLU-39 reviews

- 2026-09-13 | 📝 docs(delivery): record PLU-39 push
- 2026-09-13 | 📝 docs(delivery): record PLU-38 draft PR

- 2026-09-10 | 📝 docs(delivery): close PLU-37 after merge

- 2026-09-08 | 📝 docs(delivery): close PLU-33 after merge
- 2026-09-08 | 📝 docs(delivery): close PLU-32 after merge
- 2026-08-30 | 📝 docs(delivery): close PLU-31 after merge
- 2026-08-29 | 📝 docs(delivery): close PLU-30 after merge
- 2026-08-29 | 📝 docs(scope): defer stock confirmation to phase 12
- 2026-08-24 | 📝 docs(delivery): close PLU-29 after merge
- 2026-08-24 | 📝 docs(delivery): record PLU-29 review handoff

### Tests

- 2026-09-29 | ✅ test(services): verify CRUD sync and recovery
  Covers exact commercial snapshots, causal ACK, conflicts, tombstones and durable offline recovery.

- 2026-09-29 | ✅ test(products): verify CRUD sync and recovery
  Covers causal commands, conflicts, tombstones and durable retry across two store reopenings.
- 2026-08-29 | ✅ test(suite): remove low-value tests

### Changed

- 2026-09-08 | 🔧 chore(swift): remove redundant annotations and wrapping
- 2026-08-24 | 📦 build(config): limit iPhone to portrait while preserving adaptive iPad orientations
- 2026-08-24 | ♿ fix(clients): present loading failures without moving accessibility focus
- 2026-08-23 | ♿ fix(auth): apply semantic status inks for accessible text contrast
- 2026-08-23 | 💄 style(auth): unify native primary actions as large capsule buttons
- 2026-08-23 | ♿ fix(auth): coordinate Login focus and biometric announcements with native accessibility
- 2026-08-23 | ♿ fix(auth): add field labels, password reveal semantics, and adaptive localized Session actions
- 2026-08-02 | 💄 style(swift): complete signature normalization
- 2026-08-02 | 💄 style(swift): normalize source formatting
- 2026-07-30 | ♻️ refactor(sync): share pure retry scheduling
- 2026-07-25 | ♻️ refactor(app): clarify isolation boundaries
- 2026-07-24 | ♻️ refactor(data): move stateless Clients mapping onto Data-owned types
- 2026-07-24 | ♻️ refactor(swift): replace case-less enum namespaces with semantic APIs
- 2026-07-23 | ♻️ refactor(swift): simplify protocol conformances
- 2026-07-23 | ♻️ refactor(domain): name draft client construction

### Added

- 2026-09-08 | ✨ feat(clients): implement phase 08.3 list, search and client form screens; accessibility validation remains partial
- 2026-09-08 | ✨ feat(clients): coordinate client list and form state
- 2026-09-08 | ✨ feat(clients): add client CRUD and local search
- 2026-08-29 | ✨ feat(navigation): add adaptive authenticated app shell
- 2026-08-29 | ✨ feat(navigation): add typed app-shell selection state
- 2026-08-24 | ✨ feat(auth): add develop-only root error fixtures
- 2026-08-24 | ✨ feat(ui): add reusable loading and unavailable state views
- 2026-08-23 | ✨ feat(auth): add reusable auth controls
- 2026-08-21 | ✨ feat(clients): add develop-only error fixture
- 2026-08-21 | ✨ feat(auth): add develop-only auth fixture
- 2026-08-21 | ✨ feat(design-system): add semantic color tokens
- 2026-08-02 | ✨ feat(auth): compose protected application root
- 2026-08-01 | ✨ feat(auth): add authentication screens
- 2026-08-01 | ✨ feat(auth): add authentication presentation models
- 2026-08-01 | ✨ feat(auth): add local biometric session unlock
- 2026-07-31 | ✨ feat(auth): add Firebase authentication adapter
- 2026-07-31 | ✨ feat(auth): add authentication Data seam
- 2026-07-30 | ✨ feat(auth): define authentication Domain contracts
- 2026-07-30 | ✨ feat(data): adopt the versioned SwiftData baseline
- 2026-07-30 | ✨ feat(data): add Sales sync vertical
- 2026-07-30 | ✨ feat(data): add Services sync vertical
- 2026-07-27 | ✨ feat(data): add Products sync vertical
- 2026-07-26 | ✨ feat(data): add durable sync retry scheduling
- 2026-07-26 | ✨ feat(data): add durable tombstones and incremental cursor
- 2026-07-26 | ✨ feat(data): add causal sync and scoped rules
- 2026-07-25 | ✨ feat(data): add local-first Clients repository
- 2026-07-24 | ✨ feat(data): add Firestore client adapter
- 2026-07-24 | ✨ feat(data): define Clients remote contract
- 2026-07-24 | ✨ feat(data): isolate Clients persistence with a model actor
- 2026-07-24 | ✨ feat(data): add local Clients persistence and shared previews
- 2026-07-24 | ✨ feat(data): add the Clients DTO conversion boundary
- 2026-07-23 | ✨ feat(domain): define feature repository contracts
- 2026-07-23 | ✨ feat(domain): model appointment lifecycle
- 2026-07-23 | ✨ feat(domain): model billing document sequences
- 2026-07-23 | ✨ feat(domain): add stock warning policy
- 2026-07-23 | ✨ feat(domain): add deterministic sale calculator
- 2026-07-23 | ✨ feat(domain): model sale lifecycle
- 2026-07-22 | ✨ feat(domain): model client and catalog entities
- 2026-07-22 | ✨ feat(domain): add foundational value types
- 2026-07-22 | ✨ feat(clients): add observable client list
- 2026-07-22 | ✨ feat(architecture): add client DI vertical

### Documentation

- 2026-08-24 | 📝 docs(architecture): record the accepted iPhone orientation exception
- 2026-08-23 | 📝 docs(delivery): close PLU-28 after merge
- 2026-08-23 | 📝 docs(delivery): record PLU-28 review handoff
- 2026-08-11 | 📝 docs(governance): streamline project rules
- 2026-08-02 | 📝 docs(delivery): record formatting pull request
- 2026-08-02 | 📝 docs(delivery): record phase six integration
- 2026-08-02 | 📝 docs(delivery): record auth root checkpoint
- 2026-08-01 | 📝 docs(delivery): record auth screens checkpoint
- 2026-08-01 | 📝 docs(delivery): record auth presentation checkpoint
- 2026-08-01 | 📝 docs(delivery): reconcile biometric delivery
- 2026-08-01 | 📝 docs(governance): define Swift signature formatting
- 2026-08-01 | 📝 docs(delivery): record biometric unlock checkpoint
- 2026-07-31 | 📝 docs(delivery): record Firebase auth checkpoint
- 2026-07-31 | 📝 docs(delivery): record auth Data checkpoint
- 2026-07-30 | 📝 docs(delivery): record authentication checkpoint
- 2026-07-30 | 📝 docs(code): backfill semantic DocC coverage
- 2026-07-30 | 📝 docs(delivery): record phase five integration
- 2026-07-30 | 📝 docs(delivery): record Sales checkpoint
- 2026-07-30 | 📝 docs(delivery): record Services checkpoint
- 2026-07-27 | 📝 docs(delivery): record Products checkpoint
- 2026-07-26 | 📝 docs(progress): record published phase 05.8
- 2026-07-25 | 📝 docs(delivery): record phase 05.6 delivery
- 2026-07-24 | 📝 docs(delivery): record phase 05.5 delivery
- 2026-07-24 | 📝 docs(delivery): record phase 05.4 delivery
- 2026-07-24 | 📝 docs(delivery): record phase 05.3 delivery
- 2026-07-24 | 📝 docs(progress): record phase 05.3 closure
- 2026-07-24 | 📝 docs(progress): record phase 05.2 delivery
- 2026-07-23 | 📝 docs(governance): split review gates
- 2026-07-23 | 📝 docs(delivery): record phase four integration
- 2026-07-23 | 📝 docs(governance): enforce modern Swift review gates
- 2026-07-23 | 📝 docs(domain): add semantic DocC coverage
- 2026-07-23 | 📝 docs(roadmap): plan local MVP assistant and post-MVP Luna
- 2026-07-22 | 📝 docs(delivery): record phase three integration
- 2026-07-22 | 📝 docs(architecture): close phase three
- 2026-07-22 | 📝 docs(architecture): define Store extraction
- 2026-07-14 | 📝 docs(design): define brand and workday navigation

### Maintenance

- 2026-09-08 | 🔧 chore(localization): remove unused welcome key
- 2026-07-24 | 📦 build(config): add develop app variant
- 2026-07-22 | 📦 build(bootstrap): complete project foundations
- 2026-07-15 | 📦 build(bootstrap): add localization and Firebase
- 2026-07-15 | 📦 build(bootstrap): align Swift test settings
- 2026-07-15 | 📦 build(bootstrap): complete baseline gates
- 2026-07-14 | 📦 build(bootstrap): configure Firebase setup
- 2026-07-13 | 🔧 chore(repository): bootstrap project

### Delivery evidence

- 2026-09-09 | 📝 docs(clients): record phase 08.3 publication
