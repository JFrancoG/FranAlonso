# 13.8 — Ticket and invoice rendering proposal

03/10/2026 owner: «abre issue y rama e implementa13.8». PLU-104 In Progress/Jesus Franco;
branch `codex/plu-104-billing-ticket-invoice-rendering` from clean main/origin/main
`910e3e6dac93308af21e508c2c220ab9810f1213`. No commit/push/PR/merge/Done/live authorization.
Constitution, spec13, ADR0008/0011/0029/0030/0031/0032 and Swift code policy apply.
Maintenance profile; Xcode MCP `workspace-PfnUYLlMzY`, Develop/iPadPro13M5 Simulator27.2,
SDK27.0, app target27/Swift6/strict complete/nonisolated. No new dependency.

## Exact behavior

Domain `BillingDocumentProjection` constructs an immutable transient document/calculation pair,
using only confirmed `document.request.sale`. SaleCalculator calculates the complete sale in EUR,
including captured line promotions/global lineThenGlobalV1. Preserve order, names, quantities,
unit prices including IVA, tax rates, separate discounts, bases, tax amounts and totals. No current
catalog/profile reads; no Codable/persistence of derived totals. Reject unsupported currency,
missing historical invoice recipient and empty service name with neutral recoverable errors.
Mixed-currency/precision errors retain calculator contracts. Negative historical money is retained.

Domain port `BillingDocumentPDFComposer` asynchronously maps this projection, captured template and
optional signature bytes to the existing13.7 request. `RenderBillingDocumentUseCase` constructs the
projection, loads template/optional private signature, composes and invokes BillingPDFRenderer.
Check cancellation around every await before publishing Data; resource failures propagate and nil
signature succeeds. App adds only an inactive concrete factory with caller-provided authorized asset
repositories. No issuance, Storage, email, UI/Store consumer, demo activation, persistence or sale closure.
After composition, reject a substituted document with BillingDocumentError.conflictingDocument;
substituted template/signature or empty renderer output with BillingPDFRenderError.renderingFailed.
An empty CoreText-visible range fails textDoesNotFit; splitting always consumes complete UTF16 content.

Data actor `TemplateBillingDocumentPDFComposer` owns current-template geometry. Catalog labels explicitly
use Spanish to match static Spanish/EUR backgrounds; es/en catalog parity stays complete, but no English
PDF template exists. Ticket client/name/NIF stays blank: no such captured snapshot. Invoice uses all six
captured fiscal fields, never a current profile or invented country. Fiscal values and numeric cells
must fit completely or fail textDoesNotFit. Decimal never passes through Double/NSNumber: canonical
NSDecimalString/POSIX plus decimal-separator/cents padding retains signs, cents and38-digit percentages.
This nondeprecated API is already justified by ADR0031; no financial arithmetic is duplicated.

Table capacity:11 ticket rows/9 invoice rows (header excluded). Description contains the original name
and complete commercial/fiscal breakdown with localized labels. CoreText-visible UTF16 chunks continue
through description cells/pages, without ellipsis, clipping or shrinking. Quantity, unit price(invoice),
combined discount(invoice), IVA amount and total appear on the first row; continuation rows contain only
description. The captured tax percentage and each promotion/global term, including absent versus zero,
are explicit in the description. All lines are mapped in order. Complete-sale totals appear once on the
last page; earlier pages explicitly refer to final-page totals. Aggregate subtotal and separate line/global
discounts occupy the free left summary area. Every page repeats confirmed number/date and invoice recipient,
plus page index/count. Signature is aspect-fit in the final box only; provisional/legal notices remain.

Bounds: input/content≤200,000UTF16, fields≤20,000,1...100pages,≤200fields/page and existing asset budgets.
Check cancellation during splitting/page construction. Table font8pt, header/fiscal/total9pt, no shrinking.
Share Data `BillingPDFTextLayout` with13.7 by extracting its visible-range/glyph containment logic unchanged;
composed chunks must pass the same complete-field check. All CT references remain local within actor
operations. Domain geometry/content invariants and semantic-versus-byte determinism do not change.

## Real resources and alternatives

Both exact13.6 templates were extracted/rasterized120dpi and visually inspected. Ticket grid
x38/82/427/507/595, y588→288,25pt rows; invoice x38/73/338/406/460/515/595, y506→266,24pt.
Both existing grids have only0.2756pt right margin; preserve bytes, inset dynamic cells3pt, record this
editorial limitation. Write number/date below rules in y640…659; invoice fiscal inputs below labels:
name/NIF585…607, street551…573, postal/city/province507…539. Totals/signature/footer remain disjoint.
Ticket SHA2564d4efabdb58501a19274b40794ed3a8fb935112017ba67d1496b3df7d612ad14;
invoice7180f83a5ecdfc1e0126e40f8ac5182e5961405a3f02025360a9e8fd12073b80.

Rejected alternatives: profile enrichment changes history; calculate(lines:) loses global discount;
new financial arithmetic duplicates certified rounding; regenerating templates changes captured assets;
fixed line count drops content; shrinking/ellipsis hides terms; MainActor drawing blocks UI.
Dedicated Data composition with shared13.7 measurement is the smallest change. PDF byte stability is
not promised; Quartz owns metadata/serialization. Existing templates are untagged, without AcroForm.

Primary Apple sources read via Cupertino: CTFrameGetVisibleStringRange returns the fitted range and
supports cascading frames; Decimal.FormatStyle is available, but canonical text avoids implicit precision
choices for long percentages. NSDecimalString authority is ADR0031.
https://developer.apple.com/documentation/coretext/ctframegetvisiblestringrange(_:)
https://developer.apple.com/documentation/foundation/nsdecimalstring(_:_:)

## Files and validation

Domain projection/composer port/UseCase; Data composer/text/layout helpers;13.7 renderer minimal extraction;
inactive App factory; DocumentTemplates.xcstrings es/en labels; Swift Testing projection/pipeline tests
and synthetic fixtures; Progress/phase13/proposal/evidence. No other functional files or template changes.
Independent PRE before executable code. TDD RED→GREEN via Xcode MCP with independent literal oracles:
100/10%/20%/IVA21→72;0.07/50%/50%→0.01; mixed IVA→base17.35/tax2.65;38-digit percentage;
negative prices; absent/zero/100% discounts. Snapshot assertions execute production projection/pipeline.
Real-template PDFs nonempty, full names/terms/fiscal fields, headers every page, page boundaries, many
lines/long Unicode descriptions, large-cell rejection, missing recipient/USD, propagated asset/render
errors and cancellation. Existing13.7 tests guard extraction. Attach actual synthetic pipeline PDFs for
manual ticket/invoice/multipage/signature inspection. Develop/Production builds and affected regressions;
independent standards POST and focused PDF visual review. Native UI/previews/AT N/A: no SwiftUI changes.
No PDF-UA, fiscal validity or physical signature protection claim. PLU-101 Backlog/Jesus, after feedback
and stabilization before first real-use candidate; protection13.6 remains limited/pending separately.
Stock118 historic flake is not fixed. No new accessibility deferral or delivery/live authorization.

PRE independent `billing_13_8_pre`: PASS, no P0–P3 findings, including the communicated boundary
concretions above. Root/reviewer initial/final998-file digest identical
`d1a64f3e6d944e37ef4399d648097cbfeca9bafcc1800aa7c31a2c0365b469da`.
