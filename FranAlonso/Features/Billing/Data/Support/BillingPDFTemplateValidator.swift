import Foundation
import PDFKit

/// Shares the immutable, complete single-page A4 background policy across loading and rendering.
///
/// Parser recovery does not accept incomplete envelopes. Validation keeps all PDFKit state local
/// and does not certify editorial content, fiscal sufficiency or tagged-PDF accessibility.
struct BillingPDFTemplateValidator {
    static let maximumByteCount = 1_048_576

    static func validate(_ data: Data) throws {
        guard !data.isEmpty, data.count <= maximumByteCount,
              data.starts(with: "%PDF-".utf8), hasCompleteTerminator(data)
        else { throw BillingAssetError.invalidTemplate }
        guard let document = PDFDocument(data: data), !document.isEncrypted, !document.isLocked,
              document.pageCount == 1, let page = document.page(at: 0), page.rotation == 0
        else { throw BillingAssetError.invalidTemplate }
        let bounds = page.bounds(for: .mediaBox)
        guard bounds.origin.x.isFinite, bounds.origin.y.isFinite, bounds.width.isFinite, bounds.height.isFinite,
              bounds.origin == .zero, abs(bounds.width - 595.2756) <= 0.5, abs(bounds.height - 841.8898) <= 0.5
        else { throw BillingAssetError.invalidTemplate }
    }
}

private extension BillingPDFTemplateValidator {
    static func hasCompleteTerminator(_ data: Data) -> Bool {
        var end = data.endIndex
        while end > data.startIndex {
            let previous = data.index(before: end)
            guard [0, 9, 10, 12, 13, 32].contains(data[previous]) else { break }
            end = previous
        }
        return data[..<end].suffix(5).elementsEqual("%%EOF".utf8)
    }
}
