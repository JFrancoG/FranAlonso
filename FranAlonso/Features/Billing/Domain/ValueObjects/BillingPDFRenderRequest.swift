import Foundation

/// An immutable, bounded render plan for one already numbered paid document.
///
/// Number and UTC issue date are derived from the record on every page, never supplied as free text.
/// Every page uses the captured background. The caller owns complete financial/fiscal projection;
/// this plan does not certify that all sale data was mapped, nor fiscal validity or PDF accessibility.
struct BillingPDFRenderRequest: Equatable {
    let document: BillingDocument
    let template: Data
    let title: String
    let numberFrame: BillingPDFRectangle
    let dateFrame: BillingPDFRectangle
    let signature: BillingPDFSignature?
    private let storedPages: [BillingPDFPage]

    var pages: [BillingPDFPage] { storedPages }
}

extension BillingPDFRenderRequest {
    /// Validates required content, representable UTC date, budgets and nonoverlapping fields.
    ///
    /// A plan contains 1...100 pages and at most 200,000 UTF-16 content units. Images and
    /// the PDF envelope are validated by Data; text must also fit its frame during rendering.
    init(
        document: BillingDocument,
        template: Data,
        title: String,
        numberFrame: BillingPDFRectangle,
        dateFrame: BillingPDFRectangle,
        pages: [BillingPDFPage],
        signature: BillingPDFSignature? = nil
    ) throws {
        guard !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty, !pages.isEmpty else {
            throw BillingPDFRenderError.missingContent
        }
        guard title.utf16.count <= 2_000, pages.count <= 100 else { throw BillingPDFRenderError.limitExceeded }
        let seconds = document.issuedAt.timeIntervalSince1970
        guard seconds.isFinite, seconds >= -62_135_596_800, seconds < 253_402_300_800 else {
            throw BillingPDFRenderError.invalidDate
        }
        let contentUnits = pages.reduce(0) { count, page in
            count + page.fields.reduce(0) { $0 + $1.text.utf16.count }
        }
        guard contentUnits <= 200_000 else { throw BillingPDFRenderError.limitExceeded }
        for (index, page) in pages.enumerated() {
            var frames = [numberFrame, dateFrame] + page.fields.map(\.frame)
            if index == pages.count - 1, let signature {
                frames.append(signature.frame)
            }
            try Self.requireDisjoint(frames)
        }

        self.init(
            document: document,
            template: template,
            title: title,
            numberFrame: numberFrame,
            dateFrame: dateFrame,
            signature: signature,
            storedPages: pages
        )
    }
}

private extension BillingPDFRenderRequest {
    static func requireDisjoint(_ frames: [BillingPDFRectangle]) throws {
        for (index, frame) in frames.enumerated() {
            guard !frames.dropFirst(index + 1).contains(where: frame.overlaps) else {
                throw BillingPDFRenderError.invalidLayout
            }
        }
    }
}
