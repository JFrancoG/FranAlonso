# 13.10 — Billing materialization evidence

## Current delivery gate

04/10/2026: owner subsequently requested “commit, push y entrega”, authorizing the established commit/push,
PR, independent remote review, merge, tracker reconciliation and safe branch cleanup circuit.
Delivery is pending; PLU-106 remains In Progress. All25Swift retain their validated hashes and manifest below;
technical validation is reused by exact source identity. New Xcode validation is N/A for delivery metadata only.
Phase13/project remain open;13.11, active UI/demo integration and live activation remain separate gates.

## Historical local implementation gate

04/10/2026. PLU-106 In Progress/Jesus Franco; branch `codex/plu-106-billing-durable-state`,
base main/origin/main `a6fa3a079b8869e9f507fcc332d556cff7ca4900`.
Owner authorized issue, branch and local implementation only. No commit/push/PR/merge/Done/live.
[Approved proposal](13-10-billing-materialization-proposal.md), [spec13](../specs/13_billing_pdf_email_counters.md).

## Implemented boundaries

- Domain validates one principal-bound delivery: sealed request, numbered document, exact retained PDF,
  attempt count, neutral phase failure and canonical receipt. Receipt must be saved locally before final success.
- One shared Billing ModelActor saves each synchronous checkpoint explicitly and rolls back failures.
  Authorized repository checks captured capability before/after reads, writes and failed operations.
  A committed write can survive cancellation/revocation; this denies publication and requires authorized recovery.
- Materialization calls existing reservation/render/upload motors only after their prerequisite local commit.
  Lost reservation replies reuse the same request. Lost upload replies/receipt-save failures reuse the saved PDF.
  Rerendering is possible only before its local acceptance and before any Storage contact.
- Store owns one delivery in enum state with generation fencing. ViewModel derives its getters from that Store.
  Restart discovery uses sale/family before generating IDs; ambiguous families require explicit selection.
  Configured mode rejects synchronous ephemeral preparation. Closing presentation does not close Sale.
- Inactive App factory accepts caller-shared actor and explicit ports/capability. Current Views and normal/demo
  factories remain unchanged. This does not establish active screen or demo durability.
- Additive schema5.0.0 has36models and a4→5lightweight stage. Historical1/2/3/4 definitions are unchanged.
  Pristine checks now include Billing and all four existing StockSync metadata tables before secure claim.

## TDD and focused validation

Xcode MCP stable `workspace-PfnUYLlMzY`, Develop scheme/test plan, iPad Pro13-inch(M5), runtime27.2.
Actual Swift6/strict complete/defaultnonisolated, target27.0/SDK27.0; `xcodebuild` never used.

- Compiled inert seams24.562s; behavioral RED71cases:70FAIL/1PASS existing unknown-origin rejection.
  Artifact `340CFEBA-DF6F-4BCC-B5F8-4C95551F166A`,04/10 at02:13Europe/Madrid.
- Matrix5/5PASS: raw1/2/3/4→5, full28baseline payloads, client draft/signed PDF/receipt/attempt3,
  stock ledger and all four sync metadata bytes/cursor/retry; second disk reopen; unknown origin remains readable.
  Artifact `7B7A90FE-B02C-4345-BA20-E048AB918EB9`,02:19. Only then schema5 was activated.
- Complete focused98/98PASS,0skip/notRun/expectedFailure, artifact `74B2ED4A-DD49-437B-AE7D-8B59D7BF4DBD`,02:29.
  Includes78new expanded cases across33declarations and existing affected schema/pristine regressions.
  Earlier exact-method selections ran only first parameter values; they are not counted as complete coverage.
- Real CoreGraphics renderer, production SwiftData actor/repository and principal-bound simulated remote Storage
  validate final receipt/replay, lost reservation/Storage replies, cancellation and immutable binary reuse.
  Failure injection at each of5pipeline saves proves no next motor before commit and disk recovery with same binding.
  Persistence adds save rollback at6mutations, corruption/version/index mismatch, principal fences and stale failures.
- Early fixture failures exposed retained SwiftData bridge owners. Autosave is disabled, raw write/read use separate
  frames/autorelease pools, and unknown-origin test permits up to128cooperative yields for internal teardown.
  Required weak-owner nil checks remain before every reopen; exhaustion fails. No sleeps or GCD introduced.

## Reviews and final validation

Independent PRE PASS/noP0–P3 before executable code:1023files, identical root/reviewer initial/final digest
`1aef57f5788e1ad704dfba06294456bfaa994841f28fa558205808ed7066323e`.
Initial independent POST identified oneP2: cancellation during the error-path reread could leave Store busy.
Deterministic regression RED1/1FAIL, artifact `45DAA27B-00E4-4815-8B81-7C25CEA355C1`,02:39;
compiled production21.803s. The generation-owned defer now restores the retained snapshot if still busy,
including cancellation while rereading. A closed/revoked generation is untouched.
GREEN58/58impact cases include that regression and existing Store/ViewModel/selection/navigation tests;
artifact `6C1D871D-B85E-44BE-BE5D-7B5ED4DE6888`,02:46.79new expanded cases/34declarations in final global.
Initial source-style Audit inspected24Swift and found layout issues; Authoring fixes changed13of23owned files,
excluding Store/new cancellation regression.23/23retain identical nonwhitespace contents and exact literals;
recall7remaining candidates are closure/function-type/generic requirements or unchanged historical helpers.
Both independent audits/root before-after:1041files, identical
`3313abb3e09a38b83dcd305afe1944870e6e70ffec4fb8992a6fd2f0d6ad1998`.
Final source-style Audit25Swift PASS/no findings;7recall candidates justified/historical.
Independent POST impact re-audit PASS/noP0–P3: P2 resolved, original Domain/Data/migration audit retained by
independently verified whitespace/literal equality. Reviewer also inspected final build/global artifacts.
Both re-audits/evidence check/root:1042files initial/final identical
`968e3d2c9e4235cd19bf0266658e2d6b6b5d454480b224fe10cf6539aa84eb8e`.
Only documentation/tracker evidence metadata changed afterward; validated Swift sources are identical.

- Final Develop build-for-testing14.033s, Production23.54s,0errors. Develop scheme/test plan/iPad destination restored.
  Logs `BuildProject-Log-20261004-024849.txt` and `BuildProject-Log-20261004-025015.txt` under MCP BuildProject artifacts.
- ONE final global2866/2866PASS,0failed/skipped/notRun/expectedFailure;1717declarations/0disabled.
  Full summary `539D64B2-1068-43D1-A2AC-59113831BCB5`,02:48; all79new expanded results verified in that artifact.
- 25/25changed Swift diagnostics successfully refreshed, each0. Three initial SourceEditorerror5 responses retried
  sequentially and resolved; they are retrieval failures, not a compiler pass.
- Validated25Swift manifestSHA256 `bebb3532da040b657713adbef1812f1be112ea05913f1be159bfdc844302ab56`,
  `/tmp/franalonso-13-10-final-swift-manifest.json`. Build logs retain2/1historic AppIntents metadata notices;
  no new Swift/Clang warnings.619localized entries/0errors, `git diff --check` PASS; governance reports only
  the6known missing Desktop08.3 screenshots, unchanged outside this scope. No secret-sensitive paths added.

PLU-106 and project were reconciled In Progress with this local validation before delivery was requested.

UI/previews/localization/new accessibility evidence: N/A because current visual surfaces, resources and entry points
are unchanged; only inactive presentation contracts are extended/tested. PLU-101 Backlog/Jesus retains manual/integral
checks after flow feedback/stabilization and before first real-use candidate.13.6physical-protection limits remain.
No fiscal/PDF-UA/physical accessibility/Rules/CI/production certification is inferred.

Stock118 was not changed or stabilized. Existing2/1AppIntents notices and6Desktop08.3links remain historical.
Phase13/project remain open. Email13.11, Sale closure13.12 and series13.13 are separate future work.
