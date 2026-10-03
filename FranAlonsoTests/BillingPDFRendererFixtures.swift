import CoreGraphics
import CoreText
import Foundation
import ImageIO
import PDFKit
import Testing
import UniformTypeIdentifiers
@testable import FranAlonso

func billingPDFTemplate(
    pageCount: Int = 1,
    bounds: CGRect = CGRect(
        x: 0,
        y: 0,
        width: 595.2756,
        height: 841.8898
    )
) throws -> Data {
    let data = NSMutableData()
    let consumer = try #require(CGDataConsumer(data: data))
    var mediaBox = bounds
    let context = try #require(CGContext(consumer: consumer, mediaBox: &mediaBox, nil))
    let font = CTFontCreateWithName("Helvetica" as CFString, 12, nil)
    let attributes = [NSAttributedString.Key(kCTFontAttributeName as String): font]
    let marker = CTLineCreateWithAttributedString(NSAttributedString(
        string: "SYNTHETIC BACKGROUND 13.7",
        attributes: attributes
    ))
    for _ in 0..<pageCount {
        context.beginPDFPage(nil)
        context.textPosition = CGPoint(x: 40, y: 805)
        CTLineDraw(marker, context)
        context.endPDFPage()
    }
    context.closePDF()
    return data as Data
}

func billingPDFRectangle(
    x: Double = 40,
    y: Double = 650,
    width: Double = 500,
    height: Double = 40
) throws -> BillingPDFRectangle {
    try BillingPDFRectangle(
        x: x,
        y: y,
        width: width,
        height: height
    )
}

func billingPDFPage(_ texts: [String]) throws -> BillingPDFPage {
    let fields = try texts.enumerated().map { index, text in
        try BillingPDFTextField(
            text: text,
            frame: billingPDFRectangle(y: 650 - Double(index) * 80),
            fontSize: 11,
            bold: index == 0
        )
    }
    return try BillingPDFPage(fields: fields)
}

func billingPDFRequest(
    pages: [BillingPDFPage]? = nil,
    template: Data? = nil,
    document: BillingDocument? = nil,
    title: String = "Synthetic render plan",
    numberFrame: BillingPDFRectangle? = nil,
    dateFrame: BillingPDFRectangle? = nil,
    signature: BillingPDFSignature? = nil
) throws -> BillingPDFRenderRequest {
    try BillingPDFRenderRequest(
        document: document ?? billingPresentationDocument(billingTransactionRequest()),
        template: template ?? billingPDFTemplate(),
        title: title,
        numberFrame: numberFrame ?? billingPDFRectangle(
            x: 40,
            y: 740,
            width: 100,
            height: 24
        ),
        dateFrame: dateFrame ?? billingPDFRectangle(
            x: 200,
            y: 740,
            width: 150,
            height: 24
        ),
        pages: pages ?? [billingPDFPage(["Contenido sintético completo."])],
        signature: signature
    )
}

func billingPDFDocument(issuedAt: Date, number: Int = 41) throws -> BillingDocument {
    let request = try billingTransactionRequest()
    return try BillingDocument.numbered(
        request: request,
        number: BillingDocumentNumber(series: .ticket, value: number),
        issuedAt: issuedAt
    )
}

func billingPDFSignatureImage() throws -> Data {
    let context = try billingPDFBitmap(width: 80, height: 40)
    let magenta = try #require(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1, 0, 1, 1]))
    context.setFillColor(magenta)
    context.fill(CGRect(
        x: 0,
        y: 0,
        width: 80,
        height: 40
    ))
    let image = try #require(context.makeImage())
    let data = NSMutableData()
    let destination = try #require(CGImageDestinationCreateWithData(
        data,
        UTType.png.identifier as CFString,
        1,
        nil
    ))
    CGImageDestinationAddImage(destination, image, nil)
    try #require(CGImageDestinationFinalize(destination))
    return data as Data
}

func billingPDFMagentaBounds(_ page: CGPDFPage) throws -> CGRect? {
    let context = try billingPDFBitmap(width: 596, height: 842)
    context.drawPDFPage(page)
    return try billingPDFMagentaBounds(context)
}

func billingPDFSignatureOracleBounds() throws -> CGRect {
    let context = try billingPDFBitmap(width: 596, height: 842)
    let magenta = try #require(CGColor(colorSpace: CGColorSpaceCreateDeviceRGB(), components: [1, 0, 1, 1]))
    context.setFillColor(magenta)
    // The 80:40 source must occupy this centered 100:50 rectangle inside the 100:100 frame.
    context.fill(CGRect(
        x: 400,
        y: 85,
        width: 100,
        height: 50
    ))
    return try #require(try billingPDFMagentaBounds(context))
}

private func billingPDFBitmap(width: Int, height: Int) throws -> CGContext {
    try #require(CGContext(
        data: nil,
        width: width,
        height: height,
        bitsPerComponent: 8,
        bytesPerRow: width * 4,
        space: CGColorSpaceCreateDeviceRGB(),
        bitmapInfo: CGBitmapInfo.byteOrder32Big.rawValue | CGImageAlphaInfo.premultipliedLast.rawValue
    ))
}

private func billingPDFMagentaBounds(_ context: CGContext) throws -> CGRect? {
    let image = try #require(context.makeImage())
    let provider = try #require(image.dataProvider)
    let bytes = try #require(provider.data)
    let pointer = try #require(CFDataGetBytePtr(bytes))
    var minimumX = image.width
    var minimumY = image.height
    var maximumX = -1
    var maximumY = -1
    for y in 0..<image.height {
        for x in 0..<image.width {
            let offset = y * image.bytesPerRow + x * 4
            if pointer[offset] > 200 && pointer[offset + 1] < 40 && pointer[offset + 2] > 200 {
                minimumX = min(minimumX, x)
                minimumY = min(minimumY, y)
                maximumX = max(maximumX, x)
                maximumY = max(maximumY, y)
            }
        }
    }
    guard maximumX >= 0 else { return nil }
    return CGRect(
        x: Double(minimumX),
        y: Double(minimumY),
        width: Double(maximumX - minimumX + 1),
        height: Double(maximumY - minimumY + 1)
    )
}

struct BillingPDFSemanticSnapshot: Equatable {
    let texts: [String]
    let bounds: [CGRect]
    let title: String?
    let creator: String?
    let subject: String?
}

func billingPDFSnapshot(_ bytes: Data) throws -> BillingPDFSemanticSnapshot {
    let pdf = try #require(PDFDocument(data: bytes))
    let pages = try (0..<pdf.pageCount).map { index in
        try #require(pdf.page(at: index))
    }
    return BillingPDFSemanticSnapshot(
        texts: pages.map { $0.string ?? "" },
        bounds: pages.map { $0.bounds(for: .mediaBox) },
        title: pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String,
        creator: pdf.documentAttributes?[PDFDocumentAttribute.creatorAttribute] as? String,
        subject: pdf.documentAttributes?[PDFDocumentAttribute.subjectAttribute] as? String
    )
}

enum BillingPDFInvalidRectangle: CaseIterable {
    case nonfiniteOrigin, nonfiniteExtent, negativeOrigin, zeroWidth, negativeHeight, outsideWidth, outsideHeight

    func make() throws -> BillingPDFRectangle {
        try billingPDFRectangle(
            x: self == .nonfiniteOrigin ? .nan : self == .negativeOrigin ? -1 : 40,
            y: 40,
            width: self == .nonfiniteExtent ? .infinity : self == .zeroWidth ? 0 : self == .outsideWidth ? 600 : 50,
            height: self == .negativeHeight ? -1 : self == .outsideHeight ? 842 : 50
        )
    }
}

enum BillingPDFInvalidBudget: CaseIterable {
    case field, page, pages, totalText, title

    func make() throws {
        switch self {
        case .field:
            _ = try BillingPDFTextField(text: String(repeating: "😀", count: 10_001), frame: billingPDFRectangle())
        case .page:
            let field = try BillingPDFTextField(text: "Synthetic", frame: billingPDFRectangle())
            _ = try BillingPDFPage(fields: Array(repeating: field, count: 201))
        case .pages:
            _ = try billingPDFRequest(pages: Array(repeating: billingPDFPage(["Synthetic"]), count: 101))
        case .totalText:
            let pages = try (0..<11).map { _ in
                try billingPDFPage([String(repeating: "a", count: 19_000)])
            }
            _ = try billingPDFRequest(pages: pages)
        case .title:
            _ = try billingPDFRequest(title: String(repeating: "t", count: 2_001))
        }
    }
}

enum BillingPDFOverlap: CaseIterable {
    case headers, bodyHeader, bodyFields, finalSignature

    func make() throws -> BillingPDFRenderRequest {
        switch self {
        case .headers:
            return try billingPDFRequest(dateFrame: billingPDFRectangle(
                x: 80,
                y: 740,
                width: 150,
                height: 24
            ))
        case .bodyHeader:
            let field = try BillingPDFTextField(
                text: "Must not cover the number",
                frame: billingPDFRectangle(
                    x: 45,
                    y: 735,
                    width: 50,
                    height: 30
                )
            )
            return try billingPDFRequest(pages: [BillingPDFPage(fields: [field])])
        case .bodyFields:
            let first = try BillingPDFTextField(text: "First", frame: billingPDFRectangle())
            let second = try BillingPDFTextField(text: "Second", frame: billingPDFRectangle(y: 660))
            return try billingPDFRequest(pages: [BillingPDFPage(fields: [first, second])])
        case .finalSignature:
            let signature = try BillingPDFSignature(data: billingPDFSignatureImage(), frame: billingPDFRectangle())
            return try billingPDFRequest(signature: signature)
        }
    }
}

enum BillingPDFOverflow: CaseIterable {
    case height, unbreakableWord, narrowGlyph, number, date

    func request() throws -> BillingPDFRenderRequest {
        switch self {
        case .height:
            let field = try BillingPDFTextField(text: "Complete text", frame: billingPDFRectangle(height: 1))
            return try billingPDFRequest(pages: [BillingPDFPage(fields: [field])])
        case .unbreakableWord:
            let field = try BillingPDFTextField(
                text: String(repeating: "W", count: 120),
                frame: billingPDFRectangle(width: 12, height: 30)
            )
            return try billingPDFRequest(pages: [BillingPDFPage(fields: [field])])
        case .narrowGlyph:
            let field = try BillingPDFTextField(text: "W", frame: billingPDFRectangle(width: 1), fontSize: 24)
            return try billingPDFRequest(pages: [BillingPDFPage(fields: [field])])
        case .number:
            return try billingPDFRequest(numberFrame: billingPDFRectangle(
                x: 40,
                y: 740,
                width: 1,
                height: 24
            ))
        case .date:
            return try billingPDFRequest(dateFrame: billingPDFRectangle(
                x: 200,
                y: 740,
                width: 1,
                height: 24
            ))
        }
    }
}
