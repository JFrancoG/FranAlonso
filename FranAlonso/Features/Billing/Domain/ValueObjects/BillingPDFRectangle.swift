import Foundation

/// A positive rectangle contained in portrait A4, measured in PDF points from the bottom-left.
struct BillingPDFRectangle: Equatable {
    static let pageWidth = 595.2756
    static let pageHeight = 841.8898

    private let storedX: Double
    private let storedY: Double
    let width: Double
    let height: Double

    var x: Double { storedX }
    var y: Double { storedY }
}

extension BillingPDFRectangle {
    /// Rejects nonfinite, empty or out-of-page geometry rather than clipping content.
    init(
        x: Double,
        y: Double,
        width: Double,
        height: Double
    ) throws {
        guard x.isFinite, y.isFinite, width.isFinite, height.isFinite,
              x >= 0, y >= 0, width > 0, height > 0,
              x + width <= Self.pageWidth, y + height <= Self.pageHeight
        else { throw BillingPDFRenderError.invalidLayout }

        self.init(
            storedX: x,
            storedY: y,
            width: width,
            height: height
        )
    }

    func overlaps(_ other: BillingPDFRectangle) -> Bool {
        x < other.x + other.width && other.x < x + width &&
            y < other.y + other.height && other.y < y + height
    }
}
