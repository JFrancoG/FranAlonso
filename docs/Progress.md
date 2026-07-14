# Project Progress

Last updated: 2026-07-14

## Current Snapshot

- Current gate: phase 01 — review and accept ADR 0001 through 0009.
- Overall status: governance and specifications installed; product implementation has not started.
- Product design status: Ciruela premium is the selected brand palette; navigation uses a simple adaptive tab shell with Jornada as the initial operational screen and Histórico as a separate section.
- Validation status: Xcode MCP builds the app successfully with Firebase 12.16.0 and the Icon Composer document after setting the logical app-icon name to `franalonso` in Debug and Release.
- Repository status: Git is initialized on `main` with the private GitHub `origin` configured over SSH; diff/history-based validation is available.

## Phase Overview

| Phase | Status | Evidence / next action |
|---|---|---|
| 00 — Governance | Complete | `AGENTS.md`, guide, checklist, progress tracker, specs, and ADR drafts installed. |
| 01 — Constitution | Ready | Review and accept ADR 0001–0009; update ADR index states. |
| 02 — Bootstrap | Partial | Xcode project, SwiftUI template, Swift Testing target, and Firebase 12.16.0 package graph exist. Complete configuration, privacy gates, tests, and the remaining bootstrap items below. |
| 03 — Architecture | Not started | Begin only after phase 01 and bootstrap prerequisites. |
| 04 — Domain | Not started | Money, entities, policies, contracts, and UseCases pending. |
| 05 — Data and sync | Not started | SwiftData, Firebase adapters, repositories, and SyncEngines pending. |
| 06 — Authentication | Not started | Pending phase 05 foundations. |
| 07 — Design/navigation | Not started | Pending architecture/bootstrap. |
| 08 — Clients/consent | Not started | ADR 0009 must be accepted first. |
| 09 — Products/stock | Not started | Pending domain/data foundations. |
| 10 — Services | Not started | Pending products and domain/data foundations. |
| 11 — Sales | Not started | Pending clients and services. |
| 12 — Sale/stock | Not started | Pending sales and stock. |
| 13 — Billing | Not started | ADR 0008 must be accepted first. |
| 14 — Reports | Not started | Pending completed sales. |
| 15 — Appointments demo | Not started | Local-only demo scope. |
| 16 — Hardening | Not started | Pending MVP features. |
| 17 — QA/release | Not started | Pending hardening. |

## Observed Bootstrap Gaps

- Deployment targets currently differ between build configurations/targets (`26.0` and `26.5`) and must be reconciled deliberately.
- App target uses Swift 6.0 and `SWIFT_DEFAULT_ACTOR_ISOLATION = nonisolated`; target-specific concurrency settings still need review and documentation.
- Warning-as-error settings were not found in `project.pbxproj`.
- The template `FranAlonsoUITests` target and its XCTest/XCUITest sources have been removed.
- `FranAlonsoTests` uses Swift Testing but currently contains only the empty template test.
- Firebase 12.16.0 resolves the direct products `FirebaseCore`, Auth, Firestore, Storage, Analytics Core, and Crashlytics; app bootstrap, adapters, telemetry allowlists/consent gates, Crashlytics dSYM upload, and tests remain pending.
- Shared `Package.resolved` exists and is eligible for version control; `GoogleService-Info.plist` remains local, ignored, and untracked.
- No String Catalog, SwiftData container, or dependency composition root was found.
- The app still displays the default `Hello, world!` screen.
- Xcode still reports one project-level `Update to recommended settings` warning; it is a bootstrap follow-up independent of the icon configuration.

## Latest Evidence

- Documentation-only design pass: `docs/design/brand-palettes.md` records the selected palette and retained alternatives; `docs/design/navigation.md` records the adaptive shell and the immediate Jornada-to-Histórico closure rule. No executable target changed, so build/test evidence is `N/A`. Validation: `git diff --check` clean; 37 Markdown files checked with 0 broken local links; 60 palette contrast pairs checked with 0 failures. Two independent `$review-ios-standards` audits completed; all findings were incorporated, including terminal `voided` operations remaining visible and differentiated in Histórico.
- Icon Composer RED: Xcode MCP failed because `ASSETCATALOG_COMPILER_APPICON_NAME` passed `franalonso.icon` as the logical `--app-icon` name.
- Icon Composer GREEN: the `.icon` document remained an asset-catalog input, Debug and Release now use the extensionless logical name `franalonso`, and Xcode MCP completed a clean app build with no errors.
- TDD evidence for this configuration repair: the failing build was the RED check and the successful rebuild was the GREEN check; no artificial Swift test was added for an asset-compiler setting.
- The only existing Swift Testing case, `FranAlonsoTests/example()`, passed through Xcode MCP after the configuration repair.
- Project management is connected through the [FranAlonso Linear project](https://linear.app/plusprojects/project/franalonso-ced946bf6e7e) and an Obsidian project dashboard; this repository remains the source of truth.
- Review evidence: two isolated read-only reviewer attempts did not return a result, so the documented fallback review corrected stale UITest-removal and ATT wording; a second full-diff read-only pass found no remaining issue in this repair scope. The project-level recommended-settings warning remains an explicit bootstrap gap.

## Immediate Next Actions

1. Execute phase 01 and accept/reject each proposed ADR explicitly.
2. Continue phase 02 through its table, starting with a verified Xcode MCP project snapshot.
3. Update this file after each subphase with evidence, reviewer outcome, blockers, and the next action.

## Blockers

- No executable build blocker remains. The phase 01 ADR review is still the governance gate before implementation proceeds.
