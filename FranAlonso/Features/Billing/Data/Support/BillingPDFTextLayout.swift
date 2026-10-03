import CoreGraphics
import CoreText
import Foundation

/// Measures complete fields with the same glyph policy used for PDF drawing.
/// CoreText objects remain local to the caller's isolated operation.
struct BillingPDFTextLayout {
    let field: BillingPDFTextField

    /// Returns a complete frame only when its UTF-16 range and actual glyph bounds fit.
    /// - Throws: `BillingPDFRenderError.textDoesNotFit` rather than clipping any content.
    func makeFrame() throws -> CTFrame {
        let text = Self.attributed(field.text, fontSize: field.fontSize, bold: field.bold)
        let bounds = CGRect(
            x: 0,
            y: 0,
            width: field.frame.width,
            height: field.frame.height
        )
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let frame = CTFramesetterCreateFrame(
            framesetter,
            CFRange(location: 0, length: text.length),
            CGPath(rect: bounds, transform: nil),
            nil
        )
        let visible = CTFrameGetVisibleStringRange(frame)
        guard visible.location == 0, visible.length == text.length else {
            throw BillingPDFRenderError.textDoesNotFit
        }
        try requireContainedGlyphs(frame, in: bounds)
        return frame
    }

    /// Cascades complete UTF-16 content into bounded cells without removing characters.
    /// An empty range or a chunk that cannot be redrawn completely is a recoverable failure.
    static func chunks(_ text: String, in rectangle: BillingPDFRectangle) throws -> [String] {
        guard text.utf16.count <= 200_000 else { throw BillingPDFRenderError.limitExceeded }
        var remaining = text
        var result: [String] = []
        while !remaining.isEmpty {
            try Task.checkCancellation()
            guard result.count < 1_100 else { throw BillingPDFRenderError.limitExceeded }
            let attributed = attributed(remaining, fontSize: 8, bold: false)
            let framesetter = CTFramesetterCreateWithAttributedString(attributed)
            let bounds = CGRect(
                x: 0,
                y: 0,
                width: rectangle.width,
                height: rectangle.height
            )
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: 0, length: attributed.length),
                CGPath(rect: bounds, transform: nil),
                nil
            )
            let visible = CTFrameGetVisibleStringRange(frame)
            guard visible.location == 0, visible.length > 0,
                  let range = Range(NSRange(location: 0, length: visible.length), in: remaining)
            else { throw BillingPDFRenderError.textDoesNotFit }
            let chunk = String(remaining[range])
            let field = try BillingPDFTextField(text: chunk, frame: rectangle, fontSize: 8)
            _ = try BillingPDFTextLayout(field: field).makeFrame()
            result.append(chunk)
            remaining = String(remaining[range.upperBound...])
        }
        return result
    }
}

private extension BillingPDFTextLayout {
    static func attributed(_ text: String, fontSize: Double, bold: Bool) -> NSAttributedString {
        let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, fontSize, nil)
        let attributes: [NSAttributedString.Key: Any] = [
            .init(kCTFontAttributeName as String): font,
            .init(kCTForegroundColorAttributeName as String): CGColor(gray: 0.08, alpha: 1)
        ]
        return NSAttributedString(string: text, attributes: attributes)
    }

    func requireContainedGlyphs(_ frame: CTFrame, in bounds: CGRect) throws {
        guard let lines = CTFrameGetLines(frame) as? [CTLine], !lines.isEmpty else {
            throw BillingPDFRenderError.textDoesNotFit
        }
        var origins = [CGPoint](repeating: .zero, count: lines.count)
        CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &origins)
        for (line, origin) in zip(lines, origins) {
            if CTLineGetGlyphCount(line) == 0 {
                continue
            }
            let glyphs = CTLineGetBoundsWithOptions(line, .useGlyphPathBounds)
            guard !glyphs.isNull else { throw BillingPDFRenderError.textDoesNotFit }
            let placed = glyphs.offsetBy(dx: origin.x, dy: origin.y)
            guard placed.minX >= -0.01, placed.minY >= -0.01,
                  placed.maxX <= bounds.width + 0.01, placed.maxY <= bounds.height + 0.01
            else { throw BillingPDFRenderError.textDoesNotFit }
        }
    }
}
