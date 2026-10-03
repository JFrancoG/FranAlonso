import Foundation

/// One complete text field; whitespace and Unicode content are retained without truncation.
struct BillingPDFTextField: Equatable {
    private let storedText: String
    let frame: BillingPDFRectangle
    let fontSize: Double
    let bold: Bool

    var text: String { storedText }
}

extension BillingPDFTextField {
    /// Captures nonempty text and a finite 6...24-point font for subsequent glyph-fit validation.
    init(
        text: String,
        frame: BillingPDFRectangle,
        fontSize: Double = 9,
        bold: Bool = false
    ) throws {
        guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw BillingPDFRenderError.missingContent
        }
        guard text.utf16.count <= 20_000 else { throw BillingPDFRenderError.limitExceeded }
        guard fontSize.isFinite, (6...24).contains(fontSize) else { throw BillingPDFRenderError.invalidLayout }

        self.init(
            storedText: text,
            frame: frame,
            fontSize: fontSize,
            bold: bold
        )
    }
}
