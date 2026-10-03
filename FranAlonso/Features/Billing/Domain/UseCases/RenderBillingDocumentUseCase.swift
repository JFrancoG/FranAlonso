import Foundation

/// Produces complete PDF bytes for an already numbered paid document without mutating its lifecycle.
///
/// Resource repositories supply a validated template and optional authenticated private signature.
/// Rendering does not reserve numbers, store PDF bytes, materialize state, email or close a sale.
struct RenderBillingDocumentUseCase {
    private let templateRepository: any BillingDocumentTemplateRepository
    private let signatureRepository: any BillingBusinessSignatureRepository
    private let pdfComposer: any BillingDocumentPDFComposer
    private let pdfRenderer: any BillingPDFRenderer

    /// Rejects invalid captured snapshots before asset access and preserves cancellation across every boundary.
    ///
    /// A composer must retain the confirmed document and exact resource bytes. A different document
    /// is a conflict; substituted assets or empty renderer output cannot be published as success.
    /// - Throws: Projection, asset, composition or render failures, BillingDocumentError.conflictingDocument
    ///   for a substituted record, or cancellation, which prevails over late provider errors.
    func callAsFunction(_ document: BillingDocument) async throws -> Data {
        do {
            try Task.checkCancellation()
            let projection = try BillingDocumentProjection(document: document)
            try Task.checkCancellation()
            let template = try await templateRepository.loadTemplate(for: document.kind)
            try Task.checkCancellation()
            let signature = try await signatureRepository.loadSignature()
            try Task.checkCancellation()
            let request = try await pdfComposer.compose(projection, template: template, signature: signature)
            try Task.checkCancellation()
            guard request.document == document else { throw BillingDocumentError.conflictingDocument }
            guard request.template == template, request.signature?.data == signature else {
                throw BillingPDFRenderError.renderingFailed
            }
            let output = try await pdfRenderer.render(request)
            try Task.checkCancellation()
            guard !output.isEmpty else { throw BillingPDFRenderError.renderingFailed }
            return output
        } catch {
            try Task.checkCancellation()
            throw error
        }
    }
}

extension RenderBillingDocumentUseCase {
    init(
        templates: any BillingDocumentTemplateRepository,
        signatures: any BillingBusinessSignatureRepository,
        composer: any BillingDocumentPDFComposer,
        renderer: any BillingPDFRenderer
    ) {
        self.init(
            templateRepository: templates,
            signatureRepository: signatures,
            pdfComposer: composer,
            pdfRenderer: renderer
        )
    }
}
