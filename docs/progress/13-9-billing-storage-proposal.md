# 13.9 — PDF Storage repository proposal

## Authority and authorization

03/10/2026: «abre issue y rama e implementa 13.9» authorizes the issue, branch, local implementation and validation.
Commit, push, PR, merge, Done, live activation and 13.10 remain separate gates.
[PLU-105](https://linear.app/plusprojects/issue/PLU-105/139-store-billing-pdfs-through-an-idempotent-repository),
In Progress / Jesus Franco; branch `codex/plu-105-billing-pdf-storage`, clean base `b12ca46`.

Authority: constitution, spec13 row13.9, ADR0008/0011/0021/0029/0030 and Swift code policy.
Actual Xcode settings: Swift6, strict concurrency complete, nonisolated default, deployment iOS27;
stable SDK27.0, Develop/Production schemes. Existing Clients08.6 provides the neutral Storage precedent.

## Exact implementation

- Domain `BillingDocumentPDFStorageRepository`: one asynchronous upload of a confirmed `BillingDocument`, the
  already prepared immutable PDF bytes and the existing revocable `BillingAssetAccess` capability.
  The complete document (request, paid-sale snapshot, fiscal snapshot, number, issue time) and exact PDF bytes are
  bound to `(principalID, documentID)`. Acceptance must atomically create or compare, return the original receipt for
  an identical replay, and reject a different binding with `conflict` without overwriting the first value.
- Domain `BillingPDFUploadReceipt`: document ID, principal ID and stable private object path. The canonical path is
  `billing-pdfs/<SHA256(UTF8 principalID)>/<lowercase document UUID>.pdf`; no fiscal fields, PII or download URL.
  A pure Apple CryptoKit hash derives an opaque bounded namespace, not authorization. Receipt matching verifies
  identity and that exact path; the port's atomic contract protects the complete document/PDF binding.
- Domain `UploadBillingDocumentPDFUseCase`: one attempt, checks cancellation and capability before/after suspension,
  rejects empty bytes, correlates the returned receipt and maps failures to neutral unavailable/permissionDenied/
  conflict/invalidPDF/invalidReceipt. `CancellationError` stays cancellation. Unknown provider details never escape.
  The caller retains and retries the same prepared bytes; no automatic retries, reservation or re-rendering.
- Data `InMemoryBillingDocumentPDFStorageRepository`: actor, injectable offline/permission/lost-response/early- and
  late-cancellation failures; independently owned shared `RemoteStore`. Atomic acceptance has no suspension between
  reading and creating an entry. It compares the full immutable document and exact bytes; repository recreation
  recovers the original receipt from the same simulated remote. This proves fake behavior only.
- Data `BillingPDFUploadValidator`: bounded parsing off MainActor, nonempty complete `%PDF-`/`%%EOF` envelope,
  maximum32MiB, PDFKit readable, unencrypted/unlocked, 1–100 readable pages with finite positive media boxes.
  Multi-page PDFs are accepted without altering bytes. This is a resource/structural policy, not fiscal, editorial,
  accessibility or cryptographic authenticity certification. PDFKit instances never leave the local actor operation.
- Data unavailable repository plus an inactive App factory accepting an injected repository; default fails closed.
  Neither normal UI nor demo consumes it; constructors start no I/O. Existing authenticated shell capability is
  reused; logout/replacement/re-authorization invalidates earlier capabilities even for the same UID.

Authorization rechecked after remote completion prevents publishing a success through a revoked capability.
Cancellation or revocation after acceptance does not imply rollback; a newly authorized retry can recover the receipt.
No promise of atomicity between session revocation and remote acceptance is made.

## Alternatives and boundaries

The neutral atomic fake follows `ClientDocumentStorage` and `InMemoryClientDocumentStorage`, already accepted in08.6.
A Firebase SDK read-metadata/overwrite adapter cannot prove create-or-compare atomicity under races. Implementing
conditional creation/Rules/backend deployment is a separate live gate, as recorded in the08.6 proposal. No actual
Storage adapter or deployed Storage Rules exists today; this subphase does not claim production storage.
Random upload paths are rejected because retries could duplicate PDFs. Hashing only the PDF as identity is rejected
because it would lose the stable confirmed document identity. Re-rendering on retry is rejected: renderer determinism
is semantic and does not guarantee byte-identical output. Durable prepared bytes, upload attempts and receipt/state
materialization after process restart belong to13.10, without changing SwiftData, Store or ViewModel here.

No Sale closure, number allocation, EmailDraft, UI/resources/localization, signature cache, demo/live integration,
SDK/dependency/target changes, unsafe concurrency or opportunistic refactor. No telemetry, document logging or PII
fixtures. Existing PLU-101 accessibility debt,13.6 physical protection limits and Stock118 intermittency are unchanged.
No new ADR: this applies existing Storage and authorization boundaries rather than creating a new architecture.

## TDD and validation

Meaningful Swift Testing RED before the minimal implementation, through Xcode MCP:
identical replay and repository recreation; concurrent identical and divergent uploads; complete binding mutations;
different principals; exact original bytes retained; stable literal path oracle; offline and permission before
acceptance; lost response and late cancellation after acceptance recover without a second object; malformed/empty/
truncated/oversized/multi-page PDFs; forged foreign receipts; cancellation and capability revocation at suspension;
production renderer output uploaded unchanged; inactive default composition. No behavior is inferred from compilation.

Discover native test identifiers, GREEN and affected regression; Develop build-for-testing and Production build,
Swift file diagnostics, source-style audit, governance/diff and fresh independent read-only POST.
SwiftUI/accessibility/previews/manual PDF visuals are N/A: no UI or renderer output changes. Reuse accepted13.8 evidence
only for unchanged sources. No claims about actual Firebase Storage, physical assistive technologies or durable restart.

## Primary sources

Read full current Cupertino documents, not search snippets:
- [Apple SHA256](https://developer.apple.com/documentation/cryptokit/sha256): stable Apple hashing API; iOS13+.
- [Apple PDFDocument init(data:)](https://developer.apple.com/documentation/pdfkit/pdfdocument/init(data:)):
  failable initialization from PDF bytes; iOS11+. Envelope and budget limits are project policy, not Apple guarantees.

Repository sources: `docs/progress/08-6-document-persistence-proposal.md`, Clients Storage contract/fake,
`BillingAssetAccess`, `AuthenticationRootViewModel.makeBillingAssetAccess`, confirmed BillingDocument and13.8 renderer.

## Review gate

PRE `billing_13_9_pre`: PASS, Sin hallazgos P0–P3, before executable13.9 changes. Independent operational read-only
review,1011tracked/nonignored untracked files; reviewer/root initial/final digest identical:
`b8f43f97cd0608ad26dcc702a2dd366ac5753c04433033b868776604ce7a79d1`.
Confirmed pure CryptoKit Domain policy, full binding atomicity, revocable capability and neutral/fake boundaries.
32MiB is a structural admission budget; unchanged13.8 fixtures are24,765–67,292bytes for1–12pages.
100pages matches the existing render-plan budget. No fiscal, live or durable-restart certification.
