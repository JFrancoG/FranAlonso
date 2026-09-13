import CoreGraphics
import CoreText
import Foundation

/// Serializes PDF exports away from MainActor, keeping all drawing state local to one synchronous operation.
/// Exports real text and vector ink; it does not claim to produce a tagged accessible PDF.
actor CoreGraphicsClientDocumentRenderer: ClientDocumentRenderer {
    func render(binding: ClientDocumentSignature, signedAt: Date) async throws -> Data {
        try Task.checkCancellation()
        let seconds = signedAt.timeIntervalSince1970
        guard seconds.isFinite, (-62_135_596_800...253_402_300_799).contains(seconds) else {
            throw ClientDocumentError.invalidDate
        }
        let output = NSMutableData()
        guard let consumer = CGDataConsumer(data: output) else { throw ClientDocumentError.renderingFailed }
        var mediaBox = CGRect(x: 0, y: 0, width: 595.28, height: 841.89)
        let metadata: [CFString: Any] = [
            kCGPDFContextTitle: binding.snapshot.fields.content.fields.title,
            kCGPDFContextCreator: "FranAlonso",
            kCGPDFContextSubject: binding.snapshot.id.uuidString
        ]
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, metadata as CFDictionary) else {
            throw ClientDocumentError.renderingFailed
        }
        var closed = false
        defer {
            if !closed {
                context.closePDF()
            }
        }
        let text = attributedText(binding: binding, signedAt: signedAt)
        let framesetter = CTFramesetterCreateWithAttributedString(text)
        let textRect = CGRect(x: 40, y: 205, width: mediaBox.width - 80, height: mediaBox.height - 245)
        var offset = 0
        while offset < text.length {
            try Task.checkCancellation()
            let frame = CTFramesetterCreateFrame(
                framesetter,
                CFRange(location: offset, length: 0),
                CGPath(rect: textRect, transform: nil),
                nil
            )
            let visible = CTFrameGetVisibleStringRange(frame)
            guard visible.length > 0 else { throw ClientDocumentError.renderingFailed }
            context.beginPDFPage(nil)
            context.saveGState()
            context.textMatrix = .identity
            CTFrameDraw(frame, context)
            context.restoreGState()
            offset += visible.length
            if offset == text.length {
                let count = CFArrayGetCount(CTFrameGetLines(frame))
                var origins = [CGPoint](repeating: .zero, count: count)
                CTFrameGetLineOrigins(frame, CFRange(location: 0, length: 0), &origins)
                guard let lastOrigin = origins.last else { throw ClientDocumentError.renderingFailed }
                drawSignature(binding.signature, below: textRect.minY + lastOrigin.y - 24, in: context)
            }
            context.endPDFPage()
        }
        try Task.checkCancellation()
        context.closePDF()
        closed = true
        return output as Data
    }
}

private extension CoreGraphicsClientDocumentRenderer {
    func attributedText(binding: ClientDocumentSignature, signedAt: Date) -> NSAttributedString {
        let snapshot = binding.snapshot.fields
        let content = snapshot.content.fields
        let labels = content.labels
        let result = NSMutableAttributedString(string: "")
        func append(_ text: String, size: CGFloat = 10, bold: Bool = false) {
            let font = CTFontCreateWithName((bold ? "Helvetica-Bold" : "Helvetica") as CFString, size, nil)
            let attributes: [NSAttributedString.Key: Any] = [
                .init(kCTFontAttributeName as String): font,
                .init(kCTForegroundColorAttributeName as String): CGColor(gray: 0.08, alpha: 1)
            ]
            result.append(NSAttributedString(string: text + "\n\n", attributes: attributes))
        }
        append(content.reviewNotice, size: 9, bold: true)
        append(content.title, size: 15, bold: true)
        let purpose = snapshot.context.purpose == .initialInformation ?
            labels.initialPurpose : labels.subsequentPurpose
        append("\(labels.purpose): \(purpose)", bold: true)
        for section in content.sections {
            if !section.heading.isEmpty {
                append(section.heading, bold: true)
            }
            append(section.body)
        }
        if let authorization = content.photoAuthorization {
            append("\(labels.authorized): \(authorization)", bold: true)
        }
        append(content.signatureNotice)
        append("\(labels.clientName): \(snapshot.clientName)")
        append("\(labels.clientID): \(snapshot.clientID.rawValue.uuidString)", size: 8)
        append("\(labels.documentID): \(snapshot.id.uuidString)", size: 8)
        append("\(labels.version): \(content.version) · \(labels.language): \(content.language)", size: 8)
        append("\(labels.date): \(signedAt.ISO8601Format())", size: 8)
        append(labels.signature, bold: true)
        return result
    }

    func drawSignature(_ signature: ClientSignature, below top: CGFloat, in context: CGContext) {
        let rect = CGRect(x: 40, y: top - 100, width: 300, height: 100)
        context.saveGState()
        defer { context.restoreGState() }
        context.setStrokeColor(CGColor(gray: 0.1, alpha: 1))
        context.setLineWidth(1.5)
        context.setLineCap(.round)
        context.setLineJoin(.round)
        context.clip(to: rect)
        for stroke in signature.strokes {
            guard let first = stroke.first else { continue }
            context.beginPath()
            context.move(to: CGPoint(x: rect.minX + first.x * rect.width, y: rect.maxY - first.y * rect.height))
            for point in stroke.dropFirst() {
                context.addLine(to: CGPoint(x: rect.minX + point.x * rect.width, y: rect.maxY - point.y * rect.height))
            }
            context.strokePath()
        }
    }
}
