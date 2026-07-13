# Project Progress

Last updated: 2026-07-13

## Current Snapshot

- Current gate: phase 01 — review and accept ADR 0001 through 0009.
- Overall status: governance and specifications installed; product implementation has not started.
- Validation status: documentation and repository hygiene inspected on disk. No Xcode MCP build or test run was required for this documentation-only repository bootstrap.
- Repository status: Git is initialized on `main` with the private GitHub `origin` configured over SSH; diff/history-based validation is available.

## Phase Overview

| Phase | Status | Evidence / next action |
|---|---|---|
| 00 — Governance | Complete | `AGENTS.md`, guide, checklist, progress tracker, specs, and ADR drafts installed. |
| 01 — Constitution | Ready | Review and accept ADR 0001–0009; update ADR index states. |
| 02 — Bootstrap | Partial | Xcode project, SwiftUI template, and Swift Testing target exist. Complete the pending bootstrap items below. |
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
- `FranAlonsoUITests` still imports XCTest/XCUITest and remains in the project; phase 02 removes the template target.
- `FranAlonsoTests` uses Swift Testing but currently contains only the empty template test.
- No String Catalog, Firebase package products, SwiftData container, or dependency composition root was found.
- The app still displays the default `Hello, world!` screen.

## Immediate Next Actions

1. Execute phase 01 and accept/reject each proposed ADR explicitly.
2. Continue phase 02 through its table, starting with a verified Xcode MCP project snapshot.
3. Update this file after each subphase with evidence, reviewer outcome, blockers, and the next action.

## Blockers

- No implementation blocker has been established yet; Xcode MCP availability must be checked when phase 02 begins.
