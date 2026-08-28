# Changelog

All notable changes to this project are documented in this file.

## [Unreleased]

### Documentation

- 2026-08-29 | 📝 docs(delivery): close PLU-30 after merge
- 2026-08-29 | 📝 docs(scope): defer stock confirmation to phase 12
- 2026-08-24 | 📝 docs(delivery): close PLU-29 after merge
- 2026-08-24 | 📝 docs(delivery): record PLU-29 review handoff

### Tests

- 2026-08-29 | ✅ test(suite): remove low-value tests

### Changed

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

- 2026-07-24 | 📦 build(config): add develop app variant
- 2026-07-22 | 📦 build(bootstrap): complete project foundations
- 2026-07-15 | 📦 build(bootstrap): add localization and Firebase
- 2026-07-15 | 📦 build(bootstrap): align Swift test settings
- 2026-07-15 | 📦 build(bootstrap): complete baseline gates
- 2026-07-14 | 📦 build(bootstrap): configure Firebase setup
- 2026-07-13 | 🔧 chore(repository): bootstrap project
