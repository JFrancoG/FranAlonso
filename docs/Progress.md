# Project Progress

Last updated: 2026-07-15

## Current Snapshot

- Current gate: phase 02, subphase 02.5 — inventory visible strings and create the base String Catalog.
- Overall status: phase 01 and bootstrap subphases 02.1–02.4 are complete; phase 02 continues with localization resources.
- Product design status: Ciruela premium is the selected brand palette; navigation uses a simple adaptive tab shell with Jornada as the initial operational screen and Histórico as a separate section.
- Validation status: Xcode MCP builds the app successfully with 0 warnings; the Swift Testing plan passes 2/2 under Swift 6 and complete strict-concurrency checking.
- Repository status: Git is initialized on `main` with the private GitHub `origin` configured over SSH; diff/history-based validation is available.

## Phase Overview

| Phase | Status | Evidence / next action |
|---|---|---|
| 00 — Governance | Complete | `AGENTS.md`, guide, checklist, progress tracker, specs, and ADR drafts installed. |
| 01 — Constitution | Complete | ADR 0001–0009 accepted and indexed; both independent audit passes completed with no open valid findings. |
| 02 — Bootstrap | In progress | Subphases 02.1–02.4 are complete. The project has a Swift Testing-only test target, no XCTest/XCUITest target or source, clean Xcode MCP validation, and both 02.4 review gates closed. Start 02.5. |
| 03 — Architecture | Not started | Begin only after phase 01 and bootstrap prerequisites. |
| 04 — Domain | Not started | Money, entities, policies, contracts, and UseCases pending. |
| 05 — Data and sync | Not started | SwiftData, Firebase adapters, repositories, and SyncEngines pending. |
| 06 — Authentication | Not started | Pending phase 05 foundations. |
| 07 — Design/navigation | Not started | Pending architecture/bootstrap. |
| 08 — Clients/consent | Not started | ADR 0009 accepted; pending domain, data/sync, authentication, and design-system foundations. |
| 09 — Products/stock | Not started | Pending domain/data foundations. |
| 10 — Services | Not started | Pending products and domain/data foundations. |
| 11 — Sales | Not started | Pending clients and services. |
| 12 — Sale/stock | Not started | Pending sales and stock. |
| 13 — Billing | Not started | ADR 0008 accepted; pending domain, data/sync, sales, and stock-integration foundations. |
| 14 — Reports | Not started | Pending completed sales. |
| 15 — Appointments demo | Not started | Local-only demo scope. |
| 16 — Hardening | Not started | Pending MVP features. |
| 17 — QA/release | Not started | Pending hardening. |

## Verified Bootstrap Baseline

- Host: macOS 26.6 (`25G5065a`). Xcode: 26.6 (`17F112`). Active scheme/test plan: `FranAlonso`.
- The validated Debug build uses the iPhone Simulator 26.5 SDK. Project, app, and test Debug/Release deployment targets are aligned to iOS 26.0 without raising the app minimum.
- App and test targets use Swift language mode 6.0, `SWIFT_STRICT_CONCURRENCY = complete`, and `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated` in Debug and Release. This keeps Domain/Data actor-neutral by default while UI-owned types remain explicitly `@MainActor`.
- The app supports iPhone and iPad, with Mac Catalyst, Designed for iPhone/iPad on Mac, and Designed for iPhone/iPad on visionOS disabled.
- Firebase 12.16.0 is resolved through the shared `Package.resolved` file.
- Xcode recommended settings were accepted manually before 02.1; the resulting `LastUpgradeCheck` and String Catalog symbol-generation settings build without warnings.
- Project Debug and Release configurations enable `SWIFT_TREAT_WARNINGS_AS_ERRORS` and `GCC_TREAT_WARNINGS_AS_ERRORS`; the app and test targets inherit both settings.
- The project contains one application target and one Swift Testing unit/integration target. Xcode discovers two enabled `@Test` cases under `FranAlonsoTests`; there is no UI-test target, native UI-test source, or XCTest/XCUITest import.

## Observed Bootstrap Gaps

- Firebase 12.16.0 resolves the direct products `FirebaseCore`, Auth, Firestore, Storage, Analytics Core, and Crashlytics; app bootstrap, adapters, telemetry allowlists/consent gates, Crashlytics dSYM upload, and tests remain pending.
- Shared `Package.resolved` exists and is eligible for version control; `GoogleService-Info.plist` remains local, ignored, and untracked.
- No String Catalog, SwiftData container, or dependency composition with `AppDependencies`/`AppEnvironment` was found; these belong to later phase 02 subphases.
- The app still displays the default `Hello, world!` screen.

## Latest Evidence

- Subphase 02.4 required no executable or project-setting change: the repository already contained only the application target and `FranAlonsoTests`, with `import Testing`, `@Suite`, `@Test`, and `#expect`; no XCTest/XCUITest import, UI-test API, source, target, scheme entry, or test-plan entry was found. A new RED is `N/A` because there was no behavior to implement and the development guide forbids artificial tests for verification-only work; the existing concurrency case supplies the required minimal `@Test`/`#expect` acceptance fixture. Xcode MCP lists exactly 2 enabled tests in the `FranAlonso` plan, the full plan passes 2/2, the app build succeeds in 3.223 seconds, and both the warning-level build log and Issue Navigator contain 0 entries. The `.xctest` product suffix is the normal unit-test bundle and does not imply an XCTest import. No ADR change is required because the final state implements accepted ADR 0003 without an exception. Both independent read-only audits returned no findings; they confirmed target membership, active scheme/test-plan coverage, the `N/A` justification, and the clean full diff. Their only residual note was that Release was inspected rather than compiled separately, which is not a 02.4 requirement or blocker.
- Subphase 02.3 first RED: the Swift 6 compile guard in `ProjectSanityTests.swift` stopped the test build because `FranAlonsoTests` still used Swift 5 (`FranAlonsoTests must compile in Swift 6 language mode`). Second RED: after aligning settings, a temporary isolation violation was rejected because a `@MainActor` property could not be mutated from a nonisolated context. GREEN: the violation was removed; a permanent Swift Testing case now verifies that default isolation remains `nonisolated`, the full plan passes 2/2, and Xcode MCP builds successfully in 6.737 seconds with 0 build-log warnings and 0 warning-level Navigator issues. App and tests declare Swift 6, complete strict concurrency, and `nonisolated` default isolation in every Debug/Release target configuration; no unsafe concurrency escape hatch was introduced. Both independent read-only audits returned no findings. Their only residual notes were that the executable fixture directly exercises the test module while the app setting is covered by configuration inspection and build, and that Release was inspected rather than compiled separately; neither is a 02.3 requirement or blocker.
- Subphase 02.2 RED: with `SWIFT_TREAT_WARNINGS_AS_ERRORS = YES` and `GCC_TREAT_WARNINGS_AS_ERRORS = YES` in both project configurations, a temporary deprecated-call fixture in `AppRoot.swift` made the Xcode MCP build fail in 8.102 seconds for the expected reason (`controlledWarningFixture()` is deprecated). GREEN: after removing the fixture completely, Xcode MCP built successfully in 5.925 seconds; the full Swift Testing plan passed 1/1, the warning-level build log contained 0 entries, the Issue Navigator contained 0 warnings, and `git diff --check` was clean. The compiler log confirms `-warnings-as-errors` for both app and test Swift compilation; Clang warnings-as-errors is configured by the inherited project-level setting. No artificial test or warning fixture remains. Both independent read-only audits returned no findings; their only residual note was that reproducing the historical RED would require mutating the project, so they verified the recorded diagnosis and the clean final state instead.
- Subphase 02.1 RED: Xcode MCP could not compile `ProjectSanityTests/compositionRootCanBeCreated()` because `AppRoot` did not exist (`Cannot find 'AppRoot' in scope`). GREEN: after adding the minimal SwiftUI `AppRoot` under `App/` and connecting `FranAlonsoApp`, the targeted test passed 1/1. Final implementer validation after the structural cleanup: Xcode MCP app build succeeded in 6.361 seconds with 0 warnings, 0 errors, and 0 Navigator issues; `git diff --check` is clean. The deployment target is iOS 26.0 in every project, app, and test configuration. Runtime smoke validation through the Xcode interface succeeded on iPhone 17 and iPad (A16), both using iOS 26.5 and displaying the expected initial `ContentView`. The official 21-tool Xcode MCP surface used for this project exposes build and test actions but no Run action, so the 02.1 validation wording records that executable launch fallback explicitly. The first independent audit raised only the missing runtime evidence; after the two launches, the same reviewer confirmed the finding resolved with no residual risks, and the second independent full-diff audit returned no findings or residual risks in the 01.9/02.1 scope.
- Phase 01 acceptance: the product owner reviewed and accepted ADR 0001–0009 on 2026-07-14. This subphase is documentation-only, so build/tests are `N/A`. Implementer validation: `git diff --check` clean; 37 Markdown files checked with 0 broken local links; 9 ADR files and 9 index rows checked with 0 status-consistency failures. The first independent audit produced two documentation-state findings and both were incorporated; the second full-diff audit confirmed both resolutions and returned no findings or residual risks in the 01.9 scope.
- Documentation-only design pass: `docs/design/brand-palettes.md` records the selected palette and retained alternatives; `docs/design/navigation.md` records the adaptive shell and the immediate Jornada-to-Histórico closure rule. No executable target changed, so build/test evidence is `N/A`. Validation: `git diff --check` clean; 37 Markdown files checked with 0 broken local links; 60 palette contrast pairs checked with 0 failures. Two independent `$review-ios-standards` audits completed; all findings were incorporated, including terminal `voided` operations remaining visible and differentiated in Histórico.
- Icon Composer RED: Xcode MCP failed because `ASSETCATALOG_COMPILER_APPICON_NAME` passed `franalonso.icon` as the logical `--app-icon` name.
- Icon Composer GREEN: the `.icon` document remained an asset-catalog input, Debug and Release now use the extensionless logical name `franalonso`, and Xcode MCP completed a clean app build with no errors.
- TDD evidence for this configuration repair: the failing build was the RED check and the successful rebuild was the GREEN check; no artificial Swift test was added for an asset-compiler setting.
- The former empty `FranAlonsoTests/example()` template has been replaced by `ProjectSanityTests/compositionRootCanBeCreated()`.
- Project management is connected through the [FranAlonso Linear project](https://linear.app/plusprojects/project/franalonso-ced946bf6e7e) and an Obsidian project dashboard; this repository remains the source of truth.
- Review evidence for the earlier Firebase/icon repair: two isolated read-only reviewer attempts did not return a result, so the documented fallback review corrected stale UITest-removal and ATT wording; a second full-diff read-only pass found no remaining issue in that repair scope. The recommended-settings warning has since been resolved and validated during 02.1.

## Immediate Next Actions

1. Inventory visible strings, existing resources, and critical localization keys for 02.5.
2. Create `Localizable.xcstrings`, replace bootstrap hardcoded text, and validate the resource behavior.
3. Run Xcode MCP validation and both independent 02.5 audit passes.

## Blockers

- No external blocker.
