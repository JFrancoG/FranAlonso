import Foundation
import PDFKit

/// Loads immutable billing template bytes from an explicitly selected resource bundle.
///
/// Only complete, unencrypted, unrotated single-page A4 portrait PDFs are accepted.
/// The resource bytes are preserved for the document renderer; this validation does
/// not certify editorial content, fiscal sufficiency or PDF accessibility.
/// Reads are bounded to one MiB and keep PDFKit state within this actor's operation.
actor BundleBillingDocumentTemplateRepository: BillingDocumentTemplateRepository {
    private let bundle: Bundle
    private static let maximumByteCount = 1_048_576

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
            data = try BillingAssetFileReader.read(url, maximumByteCount: Self.maximumByteCount)
        } catch {
            try Task.checkCancellation()
            throw BillingAssetError.templateUnavailable
        }
        try Task.checkCancellation()
        guard !data.isEmpty, data.count <= Self.maximumByteCount else { throw BillingAssetError.invalidTemplate }
        guard data.starts(with: "%PDF-".utf8), hasCompleteTerminator(data) else {
            throw BillingAssetError.invalidTemplate
        }
        guard let document = PDFDocument(data: data), !document.isEncrypted, !document.isLocked,
              document.pageCount == 1, let page = document.page(at: 0), page.rotation == 0
        else { throw BillingAssetError.invalidTemplate }

        let bounds = page.bounds(for: .mediaBox)
        guard bounds.origin.x.isFinite, bounds.origin.y.isFinite, bounds.width.isFinite, bounds.height.isFinite,
              bounds.origin == .zero, abs(bounds.width - 595.2756) <= 0.5, abs(bounds.height - 841.8898) <= 0.5
        else { throw BillingAssetError.invalidTemplate }

        try Task.checkCancellation()
        return data
    }
}

private extension BundleBillingDocumentTemplateRepository {
    func hasCompleteTerminator(_ data: Data) -> Bool {
        var end = data.endIndex
        while end > data.startIndex {
            let previous = data.index(before: end)
            guard [0, 9, 10, 12, 13, 32].contains(data[previous]) else { break }
            end = previous
        }
        return data[..<end].suffix(5).elementsEqual("%%EOF".utf8)
    }
}
