#if FRANALONSO_AUTH_FIXTURE
import Foundation

/// Marks every real rendered page as a synthetic demonstration without introducing private signatures.
actor DevelopDemoBillingPDFComposer: BillingDocumentPDFComposer {
    private let base: TemplateBillingDocumentPDFComposer
    private let bundle: Bundle

    init(bundle: Bundle = .main) {
        base = TemplateBillingDocumentPDFComposer(bundle: bundle)
        self.bundle = bundle
    }

    func compose(
        _ projection: BillingDocumentProjection,
        template: Data,
        signature: Data?
    ) async throws -> BillingPDFRenderRequest {
        let plan = try await base.compose(projection, template: template, signature: nil)
        let marker = try BillingPDFTextField(
            text: String(localized: "billing.demo.pdf.mark", bundle: bundle, locale: Locale(identifier: "es")),
            frame: BillingPDFRectangle(
                x: 41,
                y: 58,
                width: 510,
                height: 16
            ),
            fontSize: 10,
            bold: true
        )
        let pages = try plan.pages.map {
            try BillingPDFPage(fields: $0.fields + [marker])
        }
        return try BillingPDFRenderRequest(
            document: plan.document,
            template: plan.template,
            title: String(localized: "billing.demo.pdf.mark", bundle: bundle, locale: Locale(identifier: "es")) +
                " — " + plan.title,
            numberFrame: plan.numberFrame,
            dateFrame: plan.dateFrame,
            pages: pages,
            signature: nil
        )
    }
}
#endif
