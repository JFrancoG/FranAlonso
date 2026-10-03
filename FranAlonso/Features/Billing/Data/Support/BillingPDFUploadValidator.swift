import Foundation
import PDFKit

/// Applies a bounded structural policy to prepared PDFs without changing their bytes.
///
/// Complete readable, unencrypted PDFs of 1–100 pages and at most 32 MiB are accepted.
/// This does not certify fiscal content, accessibility or authenticity. PDFKit state stays local
/// to the repository's isolated operation outside MainActor.
struct BillingPDFUploadValidator {
    static let maximumByteCount = 33_554_432

    static func validate(_ data: Data) throws {
        try Task.checkCancellation()
        guard !data.isEmpty, data.count <= maximumByteCount,
              data.starts(with: "%PDF-".utf8), try hasCompleteTerminator(data)
        else { throw BillingPDFStorageError.invalidPDF }
        guard let document = PDFDocument(data: data), !document.isEncrypted, !document.isLocked,
              (1...100).contains(document.pageCount)
        else { throw BillingPDFStorageError.invalidPDF }
        try Task.checkCancellation()
        for index in 0..<document.pageCount {
            try Task.checkCancellation()
            guard let page = document.page(at: index) else { throw BillingPDFStorageError.invalidPDF }
            let bounds = page.bounds(for: .mediaBox)
            guard bounds.origin.x.isFinite, bounds.origin.y.isFinite,
                  bounds.width.isFinite, bounds.height.isFinite, bounds.width > 0, bounds.height > 0
            else { throw BillingPDFStorageError.invalidPDF }
        }
        try Task.checkCancellation()
    }
}

private extension BillingPDFUploadValidator {
    static func hasCompleteTerminator(_ data: Data) throws -> Bool {
        var end = data.endIndex
        var scanned = 0
        while end > data.startIndex {
            let previous = data.index(before: end)
            switch data[previous] {
            case 0, 9, 10, 12, 13, 32:
                end = previous
                scanned += 1
                if scanned % 65_536 == 0 {
                    try Task.checkCancellation()
                }
            default:
                return data[..<end].suffix(5).elementsEqual("%%EOF".utf8)
            }
        }
        return false
    }
}
