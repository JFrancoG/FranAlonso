import Foundation

extension AppDependencies {
    /// Creates an inactive PDF motor; no assets, identities or live services are accessed.
    static func billingPDFRenderer() -> CoreGraphicsBillingPDFRenderer {
        CoreGraphicsBillingPDFRenderer()
    }
    /// Composes an inactive confirmed-document pipeline with caller-authorized resource ports.
    /// Construction performs no asset reads, reservation, persistence or live activation.
    static func renderBillingDocumentUseCase(
        templates: any BillingDocumentTemplateRepository,
        signatures: any BillingBusinessSignatureRepository,
        bundle: Bundle = .main
    ) -> RenderBillingDocumentUseCase {
        RenderBillingDocumentUseCase(
            templates: templates,
            signatures: signatures,
            composer: TemplateBillingDocumentPDFComposer(bundle: bundle),
            renderer: billingPDFRenderer()
        )
    }
}
