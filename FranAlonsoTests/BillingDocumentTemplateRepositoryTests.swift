import CoreGraphics
import Foundation
import PDFKit
import Testing
@testable import FranAlonso

@Suite("Validated billing document templates")
struct BillingDocumentTemplateRepositoryTests {
    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `bundled billing templates retain their exact source bytes`(kind: BillingDocumentKind) async throws {
        let source = try bundledPDF(kind: kind)
        let repository = BundleBillingDocumentTemplateRepository(bundle: .main)

        #expect(try await repository.loadTemplate(for: kind) == source)
    }

    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `missing template produces a recoverable resource error`(kind: BillingDocumentKind) async throws {
        let fixture = try BillingTemplateBundleFixture.empty()
        defer {
            fixture.remove()
        }

        await #expect(throws: BillingAssetError.templateUnavailable) {
            try await BundleBillingDocumentTemplateRepository(bundle: fixture.bundle).loadTemplate(for: kind)
        }
    }

    @Test(arguments: [Data(), Data("This is synthetic non-PDF content.".utf8)])
    func `empty and corrupt resources cannot be returned as templates`(source: Data) async throws {
        let fixture = try BillingTemplateBundleFixture.empty()
        defer {
            fixture.remove()
        }
        try source.write(to: fixture.ticketURL)

        await #expect(throws: BillingAssetError.invalidTemplate) {
            try await BundleBillingDocumentTemplateRepository(bundle: fixture.bundle).loadTemplate(for: .ticket)
        }
    }

    @Test
    func `a corrected resource can be loaded after a recoverable validation failure`() async throws {
        let fixture = try BillingTemplateBundleFixture.empty()
        defer {
            fixture.remove()
        }
        try Data("corrupt synthetic template".utf8).write(to: fixture.ticketURL)
        let repository = BundleBillingDocumentTemplateRepository(bundle: fixture.bundle)
        await #expect(throws: BillingAssetError.invalidTemplate) {
            try await repository.loadTemplate(for: .ticket)
        }

        let valid = try bundledPDF(kind: .ticket)
        try valid.write(to: fixture.ticketURL, options: .atomic)

        #expect(try await repository.loadTemplate(for: .ticket) == valid)
    }

    @Test(arguments: [0, 2])
    func `a template must contain exactly one page`(pageCount: Int) async throws {
        let source = pageCount == 0 ? emptyPDF() : try syntheticPDF(pageCount: pageCount)
        let document = PDFDocument(data: source)
        if pageCount == 0 {
            // PDFKit may reject an empty page tree instead of exposing a zero-page document.
            try #require(document == nil || document?.pageCount == 0)
        } else {
            try #require(document?.pageCount == pageCount)
        }
        try await expectInvalidTemplate(source)
    }

    @Test(arguments: BillingTemplateInvalidGeometry.allCases)
    fileprivate func `wrong paper size orientation or origin is rejected`(
        geometry: BillingTemplateInvalidGeometry
    ) async throws {
        let source = try syntheticPDF(bounds: geometry.bounds)
        try await expectInvalidTemplate(source)
    }

    @Test
    func `encrypted PDF is rejected even when a page can be unlocked`() async throws {
        let source = try syntheticPDF(encrypted: true)
        let document = try #require(PDFDocument(data: source))
        #expect(document.isEncrypted)
        #expect(document.unlock(withPassword: "synthetic-template-password"))

        try await expectInvalidTemplate(source)
    }

    @Test
    func `rotated A4 page is rejected`() async throws {
        let document = try #require(PDFDocument(data: try syntheticPDF()))
        let page = try #require(document.page(at: 0))
        page.rotation = 90
        let source = try #require(document.dataRepresentation())

        try await expectInvalidTemplate(source)
    }

    @Test
    func `PDF parser recovery does not permit a missing final EOF marker`() async throws {
        let valid = try bundledPDF(kind: .invoice)
        let marker = try #require(valid.range(of: Data("%%EOF".utf8), options: .backwards))
        let truncated = Data(valid[..<marker.lowerBound])
        _ = try #require(PDFDocument(data: truncated))

        try await expectInvalidTemplate(truncated)
    }

    @Test
    func `PDF parser recovery does not permit bytes before the PDF header`() async throws {
        var source = Data("synthetic junk before header\n".utf8)
        source.append(try bundledPDF(kind: .ticket))

        try await expectInvalidTemplate(source)
    }

    @Test
    func `a parseable PDF exceeding the one MiB budget is rejected`() async throws {
        var source = try bundledPDF(kind: .ticket)
        source.append(Data(repeating: 0x20, count: 1_048_576))
        _ = try #require(PDFDocument(data: source))

        try await expectInvalidTemplate(source)
    }

    @Test
    func `permitted trailing PDF whitespace preserves the source bytes`() async throws {
        let fixture = try BillingTemplateBundleFixture.empty()
        defer {
            fixture.remove()
        }
        var source = try bundledPDF(kind: .ticket)
        source.append(contentsOf: [0x20, 0x09, 0x0A, 0x0D, 0x0C, 0x00])
        try source.write(to: fixture.ticketURL)
        let repository = BundleBillingDocumentTemplateRepository(bundle: fixture.bundle)

        #expect(try await repository.loadTemplate(for: .ticket) == source)
    }

    @Test
    func `a canceled template request never returns resource bytes`() async throws {
        let gate = BillingTemplateStartGate()
        let repository = BundleBillingDocumentTemplateRepository(bundle: .main)
        let task = Task {
            await gate.wait()
            return try await repository.loadTemplate(for: .ticket)
        }
        await gate.waitUntilBlocked()
        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}

private extension BillingDocumentTemplateRepositoryTests {
    func bundledPDF(kind: BillingDocumentKind) throws -> Data {
        let name = kind == .ticket ? "billing-ticket-a4-template" : "billing-invoice-a4-template"
        let sourceURL = try #require(Bundle.main.url(forResource: name, withExtension: "pdf"))
        return try Data(contentsOf: sourceURL)
    }

    func expectInvalidTemplate(_ source: Data) async throws {
        let fixture = try BillingTemplateBundleFixture.empty()
        defer {
            fixture.remove()
        }
        try source.write(to: fixture.ticketURL)

        await #expect(throws: BillingAssetError.invalidTemplate) {
            try await BundleBillingDocumentTemplateRepository(bundle: fixture.bundle).loadTemplate(for: .ticket)
        }
    }

    func emptyPDF() -> Data {
        var source = Data("%PDF-1.4\n".utf8)
        let catalogOffset = source.count
        source.append(Data("1 0 obj\n<< /Type /Catalog /Pages 2 0 R >>\nendobj\n".utf8))
        let pagesOffset = source.count
        source.append(Data("2 0 obj\n<< /Type /Pages /Kids [] /Count 0 >>\nendobj\n".utf8))
        let crossReferenceOffset = source.count
        let entries = [catalogOffset, pagesOffset].map { offset in
            let digits = String(offset)
            return String(repeating: "0", count: 10 - digits.count) + digits + " 00000 n \n"
        }.joined()
        source.append(Data("xref\n0 3\n0000000000 65535 f \n\(entries)".utf8))
        source.append(Data("trailer\n<< /Size 3 /Root 1 0 R >>\nstartxref\n\(crossReferenceOffset)\n%%EOF\n".utf8))
        return source
    }

    func syntheticPDF(
        bounds: CGRect = CGRect(
            x: 0,
            y: 0,
            width: 595.2756,
            height: 841.8898
        ),
        pageCount: Int = 1,
        encrypted: Bool = false
    ) throws -> Data {
        let output = NSMutableData()
        let consumer = try #require(CGDataConsumer(data: output))
        var mediaBox = bounds
        let metadata: [CFString: Any] = encrypted ? [
            kCGPDFContextUserPassword: "synthetic-template-password",
            kCGPDFContextOwnerPassword: "synthetic-template-owner"
        ] : [:]
        let context = try #require(CGContext(consumer: consumer, mediaBox: &mediaBox, metadata as CFDictionary))
        for _ in 0..<pageCount {
            context.beginPDFPage(nil)
            context.setFillColor(CGColor(gray: 0.4, alpha: 1))
            context.fill(CGRect(
                x: 40,
                y: 40,
                width: 24,
                height: 24
            ))
            context.endPDFPage()
        }
        context.closePDF()
        return output as Data
    }
}

private struct BillingTemplateBundleFixture {
    let directory: URL
    let bundle: Bundle

    var ticketURL: URL {
        directory.appending(path: "billing-ticket-a4-template.pdf")
    }

    static func empty() throws -> Self {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString + ".bundle")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        do {
            return Self(directory: directory, bundle: try #require(Bundle(url: directory)))
        } catch {
            try? FileManager.default.removeItem(at: directory)
            throw error
        }
    }

    func remove() {
        try? FileManager.default.removeItem(at: directory)
    }
}

private enum BillingTemplateInvalidGeometry: CaseIterable {
    case letter
    case landscape
    case offset
    case smaller

    var bounds: CGRect {
        switch self {
        case .letter:
            CGRect(
                x: 0,
                y: 0,
                width: 612,
                height: 792
            )
        case .landscape:
            CGRect(
                x: 0,
                y: 0,
                width: 841.8898,
                height: 595.2756
            )
        case .offset:
            CGRect(
                x: 20,
                y: 30,
                width: 595.2756,
                height: 841.8898
            )
        case .smaller:
            CGRect(
                x: 0,
                y: 0,
                width: 500,
                height: 700
            )
        }
    }
}

private actor BillingTemplateStartGate {
    private var continuation: CheckedContinuation<Void, Never>?
    private var observers: [CheckedContinuation<Void, Never>] = []

    func wait() async {
        await withCheckedContinuation { continuation in
            self.continuation = continuation
            observers.forEach {
                $0.resume()
            }
            observers.removeAll()
        }
    }

    func waitUntilBlocked() async {
        guard continuation == nil else { return }
        await withCheckedContinuation {
            observers.append($0)
        }
    }

    func release() {
        continuation?.resume()
        continuation = nil
    }
}
