import Foundation

/// Loads immutable billing template bytes from an explicitly selected resource bundle.
///
/// Only complete, unencrypted, unrotated single-page A4 portrait PDFs are accepted.
/// The resource bytes are preserved for the document renderer; this validation does
/// not certify editorial content, fiscal sufficiency or PDF accessibility.
/// Reads are bounded to one MiB and keep PDFKit state within this actor's operation.
actor BundleBillingDocumentTemplateRepository: BillingDocumentTemplateRepository {
    private let bundle: Bundle

    init(bundle: Bundle) {
        self.bundle = bundle
    }

    /// Returns the original bytes after checking the complete PDF envelope and A4 page policy.
    ///
    /// - Throws: `BillingAssetError.templateUnavailable` for missing or unreadable resources,
    ///   `BillingAssetError.invalidTemplate` for rejected bytes, or `CancellationError`.
    func loadTemplate(for kind: BillingDocumentKind) async throws -> Data {
        try Task.checkCancellation()
        let resource: DocumentTemplateResource
        switch kind {
        case .ticket:
            resource = .billingTicketA4
        case .invoice:
            resource = .billingInvoiceA4
        }
        guard let url = resource.url(in: bundle) else { throw BillingAssetError.templateUnavailable }

        let data: Data
        do {
            data = try BillingAssetFileReader.read(url, maximumByteCount: BillingPDFTemplateValidator.maximumByteCount)
        } catch {
            try Task.checkCancellation()
            throw BillingAssetError.templateUnavailable
        }
        try Task.checkCancellation()
        try BillingPDFTemplateValidator.validate(data)

        try Task.checkCancellation()
        return data
    }
}
