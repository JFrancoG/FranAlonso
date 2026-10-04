# 13.10 — Durable billing materialization proposal

## Authority, approval and baseline

Delivery authority was subsequently extended on04/10/2026 by “commit, push y entrega” to the established
commit/push, reviewed PR, merge, tracker reconciliation and safe branch cleanup circuit. Technical scope is unchanged.
The initial implementation authorization and source-backed proposal below are historical; no live gate is opened.

04/10/2026: owner requests “abre issue y rama e implementa13.10”. PLU-106 In Progress/Jesus Franco;
branch `codex/plu-106-billing-durable-state` from clean main/origin/main `a6fa3a0`, zero divergence.
[Spec13](../specs/13_billing_pdf_email_counters.md)13.10: materialize final state in SwiftData,
restart at every flow boundary; presentation projects local state. ADR0002/0008/0011/0018/0021 govern
local authority, stable remote requests, layer/actor boundaries, additive migration and principal access.
This follows those accepted decisions; no new architecture, migration policy or ADR exception is proposed.
ADR0029/0030 and PLU-101 retain functional/integral/demo distinctions.

Maintenance profile. Xcode MCP stable `workspace-PfnUYLlMzY` matches this repo; actual app settings:
Swift6/strict complete/defaultnonisolated, deployment27.0/SDK27.0. Recent exact baseline13.9:
43new/181focused/one global2787 PASS, Develop/Production builds,10Swift0diagnostics, PRE/POST/style PASS.
2/1known AppIntents notices,6historical Desktop08.3 links, Stock118 not fixed/stabilized.
Current schema4.0.0 has35models; historical1/2/3/4 shapes remain untouched.

## Observable behavior and durable boundaries

Add a validated `BillingDocumentDelivery` Domain snapshot: principal, existing allocation/request,
optional exact prepared PDF, upload attempt count, optional correlated receipt and neutral phase failure.
`isFinal` requires a durable confirmed document, exact PDF and receipt; numbered alone is not final.
No second PDF copy or receipt payload is put in an outbox. Codable decoding enforces stage/ID/principal
correlation, PDF size bounds, nonnegative attempts and impossible-state rejection; Data also checks PDF structure.
Domain retains no SwiftData/PDFKit types. Receipt paths remain opaque and private as in13.9.

One `BillingDocumentLocalRepository` exposes prepare, discover by sale, recover by requestID,
accept numbered result, accept prepared PDF, begin upload, complete receipt and record neutral failure.
The Data implementation wraps one shared `@ModelActor` with BillingAssetAccess checks before/after every operation.
Known UID alone never authorizes a read/write; snapshots/receipts retain their principal and fail closed.
Each synchronous actor mutation uses explicit save and rollback, with cancellation before/after the commit.
No live ModelContext/model crosses the actor boundary; renderer and network never run inside the persistence actor.

1. Persist the complete paid request before contacting reservation. Discover retained requests by sale before
   generating new IDs. A local principal/sale/kind admits one sealed request; competing IDs/bindings conflict.
   Ticket and invoice remain distinct families. If discovery contains multiple families, require explicit kind
   rather than silently taking the first UUID. The backend only guarantees request/document idempotency, not sale uniqueness.
2. Recover the same request through existing ReserveBillingDocumentUseCase. Save its exact confirmed result
   before rendering. Remote success followed by local save failure retains the request for idempotent remote replay.
3. Render only while no PDF is accepted. Save complete bytes before upload. Before that local commit a retry may
   render again because no remote PDF was contacted; after acceptance every retry uses those identical bytes.
4. Save/increment an upload attempt before network contact. Run existing UploadBillingDocumentPDFUseCase with
   those persisted bytes. Lost acknowledgement, cancellation or receipt-save failure may follow remote acceptance;
   a new owner recovers the same path/receipt without another number or renderer call.
5. Save the correlated receipt before reporting final success. Identical document/PDF/receipt replay is a no-op;
   changed content never overwrites the accepted binding. Stale phase/attempt failures cannot demote later progress/final.
   A final replay contacts no reservation/render/upload engine. Sale remains paid/awaitingDocument until13.12.

An explicit `MaterializeBillingDocumentUseCase` orchestrates those existing motors and local checkpoints, validates
capability across suspension and maps failures neutrally without retry loops. Store owns operation generations,
not a second durable state. Store/VM expose recover/prepare/materialize methods and read one local delivery snapshot;
remote return values cannot become final presentation before persistence. After errors the active uncancelled caller
re-reads local state; cancellation/revocation never fabricates failure or final and requires explicit recovery.
Closing presentation does not discard durable work or close Sale. A later facade recovers using sale identity.

## Exact scope and integration

- Billing Domain: delivery snapshot/invariants/errors, local repository and materialization UseCase.
- Billing Data: one versioned Codable envelope model, persistence actor and authorized repository.
- App: additive `BillingDocumentsSchema`5.0.0(36models),4→5 lightweight stage, active schema after migration matrix passes;
  inactive materialization factory accepting explicit ports/capability and a caller-shared actor. No live consumer activation.
- Authentication pristine guard includes the Billing table and the four published StockSync metadata tables currently
  missing from its explicit inventory. This is the same ADR0021 all-published-tables boundary, not a new claim policy.
  Tests prove a sole row in each newly covered table prevents claim; historical model definitions stay unchanged.
- Existing BillingDocumentStore/ViewModel: optional configured durable mode, one snapshot in its enum state,
  generation fencing and semantic asynchronous recovery/materialization facade. Preserve existing ephemeral reservation
  API for legacy inactive form/previews/tests. Configured durable mode rejects synchronous ephemeral preparation.
  The current visual selection screen and normal/demo entry points remain unchanged; no new UI text/layout/preview/AT
  claim. A configured facade reads the durable snapshot through its existing observable getters. End-to-end screen
  activation belongs to later integration; this subphase provides and tests durable presentation contracts.
- Tests: production persistence/recovery/pipeline/presentation and raw schema migration, existing affected suites.
  Docs Progress/phase13/proposal/evidence and Linear maintain local In Progress. No Git delivery in this request.

## Alternatives and risks

Rejected: memory-only snapshots lose recovery; recipe-only persistence/rerender breaks binary idempotency;
separate sidecar/PDF queue requires a second commit; direct UI upload bypasses local authority;
mutating historical models/schema loses supported migration identity. Adding one envelope table preserves historical data
and avoids relations to mutable Sale models. State changes require one actor owner per container, composed/shared by App;
no cross-process/distributed SwiftData-writer atomicity is claimed. Explicit Sale/kind conflicts prevent local duplicate
requests; no global cross-device sale uniqueness is inferred. Receipt cannot establish fiscal validity or backend Rules.
Revocation after an already-authorized commit can deny publication but does not undo the durable principal-bound write.

## TDD and validation

Behavioral RED first with compiled inert seams, then GREEN:
- Disk-backed release/reopen at pending request, numbered, PDF accepted, upload attempt/remote accepted with lost reply,
  receipt-save failure and final. Same sale request/number/bytes/receipt; no renderer after PDF acceptance.
- Independent-context reads, save rollback at every mutation, authorization/revocation/cancellation, duplicate/conflicting
  request/document/PDF/receipt, impossible/corrupt/unknown-version envelopes, stale failure and attempt races.
- Raw1/2/3/4→5 migration with representative baseline/client/stock/sync metadata bytes; second reopen;
  unknown origins fail closed and remain readable with their origin. Do not activate schema5 before this matrix passes.
- Store/VM only publish local snapshots, restart discovery and explicit family ambiguity, errors after local/remote commit,
  closed/cancelled generations cannot publish late success or mutate another presentation session.
- Targeted regression + one complete suite because active schema/pristine guard/presentation contracts change;
  Develop/Production builds and changed-Swift diagnostics through Xcode MCP. Source-style Audit before final validation.
- Independent PRE before executable code, POST standards and source-style read-only with all-file identical digests.
  New SwiftUI/accessibility/previews N/A without changed visual surfaces. Existing PLU-101/13.6 limits remain.

## Primary sources read

Cupertino MCP full Apple docs checked04/10, not search snippets:
[SchemaMigrationPlan](https://developer.apple.com/documentation/swiftdata/schemamigrationplan),
[lightweight migration](https://developer.apple.com/documentation/swiftdata/migrationstage/lightweight(fromversion:toversion:)),
[ModelContext rollback](https://developer.apple.com/documentation/swiftdata/modelcontext/rollback()).
Concrete pattern: ClientDocumentPersistenceActor/Delivery, DefaultClientDocumentRepository and08.6 recovery tests;
current PhaseFiveSchemaMigrationPlan/StockSyncSchemaMigrationTests;13.9 Storage proposal and exact prepared-byte contract.

## Exclusions

No new dependency/unsafe/target change, new ADR exception, FirebaseStorage adapter/Rules/deploy/live,
remote change feed, UI activation, visual PDF/renderer change, email13.11, sale close13.12, series administration13.13,
manual fiscal/legal/PDF-UA/physical-protection certification, demo durability or phase/project closure.
No commit/push/PR/merge/Done authorized. Independent PRE `billing_13_10_pre` PASS/noP0–P3 on04/10 before code;1023files root/reviewer initial/final
digest1aef57f5788e1ad704dfba06294456bfaa994841f28fa558205808ed7066323e identical.
Local implementation completed and validated; see [evidence](13-10-billing-materialization-evidence.md).
