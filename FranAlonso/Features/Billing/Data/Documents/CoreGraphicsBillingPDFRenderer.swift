import CoreGraphics
import CoreText
import Foundation
import ImageIO

/// Serializes complete PDF drawing operations on a dedicated actor outside MainActor.
///
/// Graphics, font and image state never cross isolation. The caller supplies captured resources
/// and an explicit page plan; financial projection, persistence and tagged-PDF semantics are separate.
actor CoreGraphicsBillingPDFRenderer: BillingPDFRenderer {
    func render(_ request: BillingPDFRenderRequest) async throws -> Data {
        try Task.checkCancellation()
        try BillingPDFTemplateValidator.validate(request.template)
        guard let provider = CGDataProvider(data: request.template as CFData),
              let template = CGPDFDocument(provider), let background = template.page(at: 1)
        else { throw BillingAssetError.invalidTemplate }
        let image = try signatureImage(request.signature)
        try Task.checkCancellation()
        let output = NSMutableData()
        guard let consumer = CGDataConsumer(data: output) else { throw BillingPDFRenderError.renderingFailed }
        var mediaBox = CGRect(
            x: 0,
            y: 0,
            width: BillingPDFRectangle.pageWidth,
            height: BillingPDFRectangle.pageHeight
        )
        let metadata: [CFString: Any] = [
            kCGPDFContextTitle: request.title,
            kCGPDFContextCreator: "FranAlonso",
            kCGPDFContextSubject: request.document.id.rawValue.uuidString
        ]
        guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, metadata as CFDictionary) else {
            throw BillingPDFRenderError.renderingFailed
        }
        var closed = false
        defer {
            if !closed {
                context.closePDF()
            }
        }
        let date = issueDate(request.document.issuedAt)
        for (index, page) in request.pages.enumerated() {
            try Task.checkCancellation()
            context.beginPDFPage(nil)
            context.saveGState()
            let transform = background.getDrawingTransform(
                .mediaBox,
                rect: mediaBox,
                rotate: 0,
                preserveAspectRatio: true
            )
            context.concatenate(transform)
            context.drawPDFPage(background)
            context.restoreGState()
            try draw(
                BillingPDFTextField(text: String(request.document.number.value), frame: request.numberFrame),
                in: context
            )
            try draw(BillingPDFTextField(text: date, frame: request.dateFrame), in: context)
            for field in page.fields {
                try Task.checkCancellation()
                try draw(field, in: context)
            }
            if index == request.pages.count - 1, let image, let signature = request.signature {
                draw(image, in: signature.frame, context: context)
            }
            context.endPDFPage()
        }
        try Task.checkCancellation()
        context.closePDF()
        closed = true
        try Task.checkCancellation()
        return output as Data
    }
}

private extension CoreGraphicsBillingPDFRenderer {
    /// Uses the proleptic Gregorian calendar for the complete admitted year range.
    /// FormatStyle has no Gregorian-cutover setting and shifts year 0001 by two days on
    /// the current SDK. This nondeprecated formatter stays local to the isolated operation.
    func issueDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.timeZone = .gmt
        formatter.gregorianStartDate = Date(timeIntervalSince1970: -62_135_596_800)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    func signatureImage(_ signature: BillingPDFSignature?) throws -> CGImage? {
        guard let signature else { return nil }
        try BillingSignatureImageValidator.validate(signature.data)
        let options = [
            kCGImageSourceShouldCache: true,
            kCGImageSourceShouldCacheImmediately: true
        ] as CFDictionary
        guard let source = CGImageSourceCreateWithData(signature.data as CFData, nil),
              let image = CGImageSourceCreateImageAtIndex(source, 0, options)
        else { throw BillingAssetError.invalidSignature }
        return image
    }

    func draw(_ field: BillingPDFTextField, in context: CGContext) throws {
        let frame = try BillingPDFTextLayout(field: field).makeFrame()
        context.saveGState()
        defer {
            context.restoreGState()
        }
        context.translateBy(x: field.frame.x, y: field.frame.y)
        context.textMatrix = .identity
        CTFrameDraw(frame, context)
    }

    func draw(_ image: CGImage, in frame: BillingPDFRectangle, context: CGContext) {
        let scale = min(frame.width / Double(image.width), frame.height / Double(image.height))
        let width = Double(image.width) * scale
        let height = Double(image.height) * scale
        let bounds = CGRect(
            x: frame.x + (frame.width - width) / 2,
            y: frame.y + (frame.height - height) / 2,
            width: width,
            height: height
        )
        context.saveGState()
        defer {
            context.restoreGState()
        }
        context.draw(image, in: bounds)
    }
}
