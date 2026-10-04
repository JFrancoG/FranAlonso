# 13.11 — Manual billing email proposal

## Authority and verified baseline

04/10/2026: owner requests «abre issue y rama e implementa13.11». PLU-107/Jesus Franco In Progress;
branch`codex/plu-107-billing-email-composition` from clean main/origin/main`8639a87`, zero divergence.
Owner authorizes this exact local implementation; commit/push/PR/merge/Done and13.12 remain separate gates.
[Spec13](../specs/13_billing_pdf_email_counters.md)13.11 requires recipient, subject, body, attachment and manual sending.
ADRs0002/0008/0011/0021 govern local authority, final correlation, layers and captured revocable capability.
ADR0029/0030 preserve phase/accessibility debt and prohibit real email from the demo. No ADR exception is proposed.

Maintenance profile; Xcode MCP stable`workspace-PfnUYLlMzY` points to this project. Develop active;
app target27.0/SDK27.0, Swift6/strict complete/defaultnonisolated, Swift/Clang warnings as errors.
Recent13.10 baseline:79new/98focused/one global2866 PASS; both builds,25Swift0diagnostics,
PRE/POST/style/delivery audits PASS. Source identity and source/configuration baseline unchanged.
2/1AppIntents notices,8external historical/temporary links, Stock118 and physical13.6 limits retained.
Linear project In Progress; no phase13 parent/milestone. Search all102project issues: no existing13.11 item.

## Exact behavior and boundaries

Client/ClientProfile have no email. Accept one explicit recipient; never infer it from the authenticated account,
change Client/schema or send silently. Basic single-mailbox validation rejects empty sides, whitespace/control/header
injection and recipient-list delimiters; no RFC/DNS/deliverability certification. Native Mail retains editable validation.

`EmailDraft` is an immutable, validated Domain value (Identifiable/Codable/Equatable). It captures principal, confirmed
document/request, canonical receipt, exact PDF and explicit recipient with already-resolved subject/plain-text body.
Construction requires a final13.10 delivery; decoded values recheck correlation, bounded bytes and content invariants.
Attachment MIME is application/pdf; filename is family plus opaque document UUID.pdf, without PII or local/Storage paths.
It is ephemeral: Codable is the value contract, not permission to persist/log drafts or recipient/content.

`PrepareBillingEmailDraftUseCase(requestID:recipient:)` reads the existing local repository only. It checks captured
BillingAssetAccess before/after read/publication/errors; request ID and principal must match. Reject absent/nonfinal
checkpoints. Repeated preparation reads the same receipt/bytes, allocating no identities, numbers or upload attempts.
`BillingEmailContentBuilder` is a pure Domain port; Data resolves four localized subject/body entries in Localizable
with explicit bundle/locale. Ticket/invoice use their own localized name and confirmed number. Update LocalizationInventory.

`BillingEmailComposing` is a Domain MainActor async port for the inevitable main-actor platform UI boundary.
Results are cancelled/saved/queued/failed. Queued means the Mail outbox accepted the person's action, never recipient delivery.
`AppleBillingEmailComposer` Data adapter wraps MessageUI's delegate boundary in one checked async continuation.
It owns one operation token before any await, rejects overlapping compose calls, checks cancellation/capability before
presentation and after completion/errors, and dismisses on cancellation. Every continuation completes at most once;
stale callbacks/cancellation cannot finish or dismiss a later operation. Errors are neutral; no SDK payload logging.

Data-owned `AppleMailCompositionDriver` isolates platform presentation and deterministic testing. Its native
`MessageUIMailCompositionDriver` owns a weak explicit UIViewController presenter and one composer/delegate lifetime.
It checks canSendMail before creation and presentation, presenter attachment/free modal state, configures recipient,
subject, plain-text body and exact in-memory PDF once before presenting, and dismisses on every terminal outcome.
It never mutates the native hierarchy, supplies a From address, requests a mailto fallback, or calls any sending API.
There is no @objc/selector/GCD/unsafe escape; the SDK delegate is contained behind the async Domain boundary.

Only App composes the read-only preparer and Apple composer from the caller's shared persistence actor,
captured BillingAssetAccess, bundle/locale and explicit presenter. Factories remain inactive. No new screen/SwiftUI View,
existing BillingViewModel/Store change or normal/demo entrypoint activation is required for this component subphase.
Native composition has no active consumer until a later explicitly approved integration gate.

## Alternatives and risks

- mailto: does not carry the required retained PDF attachment; rejected.
- ShareLink/activity sheet: cannot guarantee this typed recipient/subject/body/manual Mail contract; rejected.
- Own email transport/server or automatic sending: violates manual sending and live/demo limits; rejected.
- New custom email form/wrapper screen now: expands13.12 navigation/UI integration; defer until its exact gate.
- Native MessageUI through a replaceable Data driver and async port: fits actual Apple API and isolates callback lifetime.

No new third-party dependency, target increase, unsafe concurrency, persisted model, schema or business write.
PDF validation/read work stays on existing Data actor/concurrent boundaries; UI operations alone use MainActor.
Explicit recipient/basic syntax is documented, not an invented customer field. Drafts contain sensitive business bytes:
keep them in memory only, remove adapter/controller references on completion, never log/persist/telemetry or real-email test.
Native Mail can save/queue after manual human approval; task cancellation cannot retract a queued message. This limit
must not be represented as transactional rollback or Sale closure. Capability checks cannot prove backend freshness.

## Planned files and TDD

New Billing Domain Entities/EmailDraft.swift, Services/BillingEmailContentBuilder.swift,
Services/BillingEmailComposing.swift and UseCases/PrepareBillingEmailDraftUseCase.swift.
New Data/Email localized content builder, async Apple composer/driver contract, native MessageUI driver;
App/Composition/Dependencies/AppDependencies+BillingEmail.swift. Only localization catalog/inventory plus tests/docs
outside these additions; all prior functional Swift remains untouched unless a valid in-scope finding requires it.

Behavioral RED with compiled inert seams, then implementation/GREEN through Xcode MCP and Swift Testing:
- Real local final ticket/invoice -> localized draft with fixture recipient, exact retained PDF/receipt and safe filename.
  Reopen disk owner and prepare again; unchanged persisted checkpoints/attempts, no new motors or writes.
- Every nonfinal checkpoint, missing/wrong request/principal, revocation/read error/cancellation denies publication.
- Reject header injection/invalid recipient/content and corrupted decoded final binding; not trivial field round-trips.
- Controlled platform driver proves no presentation when unavailable/unauthorized/cancelled, single manual presentation,
  each neutral result, thrown/inline/duplicate/stale callback, overlapping calls, cancellation dismiss and later retry.
  Production adapter and localized content execute; mocked SDK boundary is not a real native Mail send.
- Native driver real unavailable guard on Simulator; no composer initialization if canSendMail is false.

Focused Billing/email/localization tests, Develop and Production builds, diagnostics, one final global run if impact
warrants; independent POST and source-style audit. Accessibility reviewer for localized native composition semantics.
No custom SwiftUI screen means representative previews N/A; active UI/resources outside these strings remain unchanged.
Real configured Mail editing/attachment/dismissal and native accessibility remain Limited/Pending until explicitly
approved active integration on an appropriate device, before any real-use candidate. No test sends real email.
Record these limits on PLU-107; PLU-101 keeps its own13.5 debt without automatic transfer or invented PASS.

## Primary sources

Cupertino full Apple documentation read; installed SDK/build is final compatibility authority. Online Apple endpoint
verified current; its markdown endpoint is unsupported by web ingestion, so detailed text comes from Cupertino.
- [MFMailComposeViewController](https://developer.apple.com/documentation/messageui/mfmailcomposeviewcontroller):
  configure before presentation, human editing/approval, no delivery guarantee, no native hierarchy alteration.
- [canSendMail](https://developer.apple.com/documentation/messageui/mfmailcomposeviewcontroller/cansendmail()):
  do not create/present the composition interface without configured Mail.
- [Attachment](https://developer.apple.com/documentation/messageui/mfmailcomposeviewcontroller/addattachmentdata(_:mimetype:filename:)):
  in-memory bytes, MIME/filename and configuration before presentation.
- [Delegate](https://developer.apple.com/documentation/messageui/mfmailcomposeviewcontrollerdelegate) and
  [Results](https://developer.apple.com/documentation/messageui/mfmailcomposeresult): terminal dismissal and queued semantics.

PRE independent read-only`billing_13_11_pre` PASS/SinP0–P3 before executable code.1043files,
reviewer/root initial/final identical`ec4e5f1d51a5a3fd3aecf9c3f243938a9ec9cba1514b3977d02ed3e1349bc0b9`.
No exception requiring further owner approval is inferred; the owner's implementation request remains applicable.
