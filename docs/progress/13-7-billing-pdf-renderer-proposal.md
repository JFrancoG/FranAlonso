# 13.7 — Billing PDF renderer proposal

## Authority and authorization

Owner: «abre issue y rama e implementa13.7»,03/10/2026. PLU-103 In Progress;
branch `codex/plu-103-billing-pdf-renderer` from clean main/origin/main
`7db053d6cdb8cc072c9aece387c1bee4cd61744f`. No delivery Git, completion, live or13.8 authorization.
This records the implementation gate. Subsequent «commit, push y entrega» authorizes the established
Git/PR/merge/issue-closeout path; delivery state is recorded in phase-13.md. Live and13.8 remain separate.
Constitution, spec13 table49–50, ADR0008/0011/0029/0030 and Swift code policy apply.
Maintenance profile; existing iOS27/Swift6 strict isolation retained. Xcode MCP workspace
`workspace-PfnUYLlMzY`, Develop active; Linear project In Progress, no phase13 parent/milestone.
Previous13.6 evidence:52new/181affected cases PASS and Develop/Production builds; global2633/2634
with pre-existing StockSyncDurabilityTests118 failure, unchanged. Signature physical protection remains pending.

## Exact behavior

Implement Domain `BillingPDFRenderer: Sendable` with async throwing `render(_ request) -> Data`.
Request is an immutable, ephemeral render plan: confirmed `BillingDocument`, template bytes,
nonempty document title, number/date rectangles, ordered pages of positioned text fields, optional
signature image and rectangle. No persistence/Codable contract is introduced for this transient plan.
Rectangles use Double points in A4 PDF coordinates (bottom-left origin), not framework objects.
Text fields carry nonempty text, rectangle, font size6...24pt and regular/bold emphasis.
Construction guarantees pure geometry/content/page-count invariants with private storage and validating
factories/initializers; Data additionally checks template/image validity and actual glyph layout.

The motor always draws the definitive document.number.value and issuedAt UTC ISO date from the confirmed
record on every page; callers cannot provide conflicting number/date strings. Headers must fit entirely.
All explicit pages are rendered in order, reusing the single-page A4 background; no line/field/page is
silently dropped. Each page requires at least one content field. Each text field must fit completely in its
rectangle according to CoreText's visible UTF-16 range; overflow throws a neutral recoverable error.
No ellipsis, clipping, implicit shrinking or partial Data is returned. Geometry must be finite, positive,
inside canonical A4; number/date/content rectangles may not overlap, and optional signature must not
cover content on the final page. Text remains selectable/extractable; Helvetica/CoreText fallback is used.
Template retains all provisional/legal notices. Signature is aspect-fit on the last page only;
absence succeeds without image decoding. Image validation reuses13.6 policy; private bytes never enter
bundle/repository/logs. Renderer performs no repository, filesystem, network, auth or clock access.

Bounds:1...100pages,1...200fields/page,≤20,000UTF-16 units/field,≤200,000total;
template≤1MiB per13.6, signature≤2MiB and≤4,194,304pixels per13.6.
Date must be representable in years0001...9999. These are rejection boundaries, not silent truncation.
The drawing operation is synchronous within a dedicated actor, not MainActor. Check cancellation before
preparation, per page/field and before publishing; close the PDF context in defer on failure.
All CGContext/CGPDFDocument/CoreText/ImageIO references remain operation-local within actor isolation.
App adds only a concrete renderer factory; no UI/Store pipeline activation.

Determinism means identical extracted content, page order/count, coordinates, sizes and chosen metadata
for identical plan and toolchain. It does NOT mean byte-for-byte identical PDFs: Quartz owns creation
metadata/font serialization and documents no stable-byte guarantee. Never rewrite raw PDF bytes to mask
that. Tests compare semantic/page snapshots; persisted original bytes belong to later subphases.

## Files and boundaries

- Domain/Repositories/BillingPDFRenderer.swift: port and neutral errors.
- Domain/ValueObjects/BillingPDFRenderRequest.swift plus geometry/text/page value files as needed.
- Data/Support/BillingPDFTemplateValidator.swift: extract13.6 template validation unchanged for reuse.
- Data/Repositories/BundleBillingDocumentTemplateRepository.swift: delegate existing checks only.
- Data/Documents/CoreGraphicsBillingPDFRenderer.swift and directly owned drawing helpers as needed.
- App/Composition/Dependencies/AppDependencies+BillingPDF.swift: inactive concrete factory.
- FranAlonsoTests/BillingPDFRendererTests.swift and deterministic synthetic fixtures as needed.
- Progress/phase13/proposal: gates, evidence and current state. No historical PDF, catalog or UI edits.

## Alternatives and sources

Reuse existing Clients actor pattern, but do not modify that renderer or its consent/signature pipeline.
MainActor UIKit PDF rendering would put heavy work on UI isolation; direct raw-PDF writing adds unsupported
serialization/font complexity; PDFKit annotations/export alone do not guarantee complete text fit.
CoreGraphics/CoreText is existing Apple-only infrastructure with isolated state and no new dependency.
Explicit pages keep13.7 a motor:13.8 owns financial/fiscal formatting, business labels, template coordinates,
partitioning all sale lines/totals and visual validation. No generic auto-layout/table framework is introduced.
Ticket has no historical fiscal/name snapshot; invoice historical recipient may be nil.13.8 must define
these cases from frozen requests, never read current client profiles. Current templates say euros;
13.8 must reject/choose appropriate currency rather than label USD as EUR. Motor does not calculate tax.

Apple docs consulted through Cupertino MCP:
- [PDF consumer context](https://developer.apple.com/documentation/coregraphics/cgcontext/init(consumer:mediabox:_:))
- [PDF page drawing](https://developer.apple.com/documentation/coregraphics/cgcontext/drawpdfpage(_:))
- [CoreText visible range](https://developer.apple.com/documentation/coretext/ctframegetvisiblestringrange(_:)):
  actual visible range, also suitable for cascading; engine rejects incomplete positioned fields.
- [Auxiliary keys](https://developer.apple.com/documentation/coregraphics/auxiliary-dictionary-keys):
  explicit title/creator/subject; no documented deterministic-byte promise.
Sources are current indexed Apple docs; compile API availability against active SDK. No deprecated/unsafe API.

## TDD and validation

After independent PRE only: compilable renderer stub and tests first, behavior RED, then implementation.
Tests run production renderer against synthetic independent text/PDF/image fixtures via PDFKit parsing:
required confirmed number/UTC date on every page, complete Unicode ordered text, exact planned page count,
repeated-background preservation, deterministic semantic output across actors/repeated calls, rejection
of absent pages/content, invalid bounds/overlap/overflow/date/template/signature, final-page aspect-fit
signature and absence, pre-cancellation and rendering invoked from MainActor with drawing off it.
No tests for stored-value copies or compiler-guaranteed conformances. No sleeps/XCTest/UI tests/live.
Use Xcode MCP: focused RED/GREEN, affected Billing/template/Clients regression, Develop-for-testing and
Production build, complete logs and source diagnostics. Exact parameter coverage checked in native result
bundle if MCP selects partial arguments. Governance/diff/secret-sensitive checks. Global retest only if
impact warrants; pre-existing Stock118 remains visible and never re-run merely to obtain green.
Independent standards POST and Swift style audit; PDF output/resources audit when applicable.
UI/previews/manual assistive-technology testing N/A for this scope because no screens change;
no tagged-PDF/PDF-UA/fiscal/legal claim. Final real ticket/invoice layout review remains13.8.

## Risks and reversibility

Explicit positioning rejects unrepresentable long content, enabling13.8 to repaginate rather than lose data.
Completeness of this plan is not completeness of a sale snapshot;13.8 must test the mapping independently.
CoreText layout/fonts may vary across OS versions; same-toolchain semantic determinism only.
Local validation does not prove live reservation, physical file protection, fiscal validity or accessibility.
No mutable renderer cache, detached tasks, GCD, opt-outs, ADR change, dependency or target migration.
Reversible new port/values/adapter and validation extraction; no persisted schema or existing UI behavior change.

## Independent PRE

PRE independiente `billing_13_7_pre`: PASS, sin hallazgosP0–P3. Operacional read-only,987archivos;
root/revisor inicial/final idénticos `adb894bc623af15d0e27ecbe74f8d076881f2e1274de1b77657e4d3331cf76af`.
No excepción/ADR/dependencia necesaria. Se continúa bajo autorización explícita de implementación13.7.
No código ejecutable ni tests añadidos antes de este dictamen.

## Corrección focal — fecha gregoriana completa

RED original51/51, GREEN focal33/35 expone bug real del formato elegido: en SDK27.0/runtime27.2,
Date.ISO8601FormatStyle y Date.FormatStyle/Calendar Gregorian/ISO8601 representan el instante sintético
-62135596800 como0001-01-03. Oráculo independiente exige0001-01-01 gregoriano proleptico UTC.
Evidencia: adjunto synthetic-year-one-diagnostics en xcresult20:44:30; expectativas intactas.
La API FormatStyle no expone corte gregoriano. Alternativa compatible Apple no deprecada:
DateFormatter local a la operación del actor, locale en_US_POSIX, calendario gregoriano, timezone GMT,
patrón fijo yyyy-MM-dd y gregorianStartDate explícito en el primer instante admitido0001-01-01.
No reloj/caché/sharedmutable/opt-out ni objetos de Foundation cruzando actores. Evita inventar un
algoritmo de calendario o reducir el rango aprobado. La propiedad es API vigente sin reemplazo
FormatStyle equivalente para este corte; su necesidad está probada por el fallo, no por preferencia.
[Apple gregorianStartDate](https://developer.apple.com/documentation/foundation/dateformatter/gregorianstartdate)
documenta el cambio del calendario juliano al gregoriano. Compilar/ejecutar mismos límites y UTC;
registrar la razón específica de DateFormatter en DocC.

PRE focal independiente `billing_13_7_pre` PASS antes de la corrección, sin hallazgosP0–P3;
997archivos, huella inicial/final/root idéntica
`af57e491442f5732a5dd170c6dad70b9b96e20e0b5114579b2a2368063440868`.
GREEN posterior fecha/firma5/5; el oráculo sigue exigiendo0001-01-01, UTC y todos los límites.
La fixture magenta/oráculo raster usaban RGB calibrado: en DeviceRGB el verde era64, fuera del umbral40.
El rectángulo independiente también fallaba. Se fijó DeviceRGB explícito en ambos colores sintéticos;
expectativas de presencia/página/proporciones permanecen iguales. Firma1/1 PASS antes de corregir fecha.

## Implementación y evidencia

Contrato, invariantes y actor implementados según la propuesta. CoreText verifica rango visible íntegro y
bounds reales de glifos; no publica bytes parciales. Shared validator conserva las reglas13.6 sin modificar
assets privados/bundle. Factory concreta inactiva. Sin schema, dependencias, Views ni configuración nuevos.
RED compilable51/51FAIL; GREEN completo22declaraciones/51casos,12grupos parametrizados completos.
RunAllTests20:51:45:2685/2685PASS; Billing+AuthenticationRoot+ClientSignedDocument138/238PASS.
Tras esa ejecución solo cambió el wrapping de una llamada CTFontCreateWithName, sin argumentos/behavior:
buildsDevelop/Production y focalUnicode/firma/callerMainActor3/3PASS sobre fuente final.
Logs completos sin diagnósticoSwift/Clang;2/1avisosAppIntents previos. Artefactos, cobertura y límites en
[phase13](phase-13.md). POST funcional independiente sin hallazgosP0–P2; P3 de tres llamadas con
cuatro argumentos corregido únicamente con wrapping vertical. Reauditoría de estilo independiente PASS.
Revisión focal PDF PASS y puertaUI N/A: sin alcanceSwiftUI; no AT manual/previews ejecutados.
Plantillas reales/partición comercial/fiscal/revisión visual corresponden a13.8; no PDF-UA ni uso real.
