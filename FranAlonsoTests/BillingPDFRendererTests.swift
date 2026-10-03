import CoreGraphics
import Foundation
import PDFKit
import Testing
@testable import FranAlonso

@Suite("Complete deterministic billing PDF rendering")
struct BillingPDFRendererTests {
    @Test
    func `planned pages retain backgrounds confirmed headers and complete ordered Unicode text`() async throws {
        let pageTexts = [
            ["PRIMERA LÍNEA: niño, café y €.", "SEGUNDA LÍNEA: revisión mañana — 21 %.", "TERCERA LÍNEA completa."],
            ["ÚLTIMA PÁGINA: datos sintéticos.", "FIN DEL CONTENIDO SIN TRUNCAR."]
        ]
        let request = try billingPDFRequest(pages: pageTexts.map { try billingPDFPage($0) })
        let bytes = try await CoreGraphicsBillingPDFRenderer().render(request)
        let pdf = try #require(PDFDocument(data: bytes))

        #expect(pdf.pageCount == 2)
        #expect(pdf.documentAttributes?[PDFDocumentAttribute.titleAttribute] as? String == "Synthetic render plan")
        for index in pageTexts.indices {
            let page = try #require(pdf.page(at: index))
            let content = try #require(page.string)
            #expect(content.contains("SYNTHETIC BACKGROUND 13.7"))
            #expect(content.contains("41"))
            #expect(content.contains("1970-01-01"))
            #expect(abs(page.bounds(for: .mediaBox).width - 595.2756) < 0.01)
            #expect(abs(page.bounds(for: .mediaBox).height - 841.8898) < 0.01)
            var nextOffset = content.startIndex
            for expectedText in pageTexts[index] {
                let range = try #require(content.range(of: expectedText, range: nextOffset..<content.endIndex))
                nextOffset = range.upperBound
            }
        }
    }

    @Test
    func `same captured plan yields identical semantic snapshots across calls and renderer actors`() async throws {
        let request = try billingPDFRequest(pages: [billingPDFPage(["Fijo: áéíóú, €.", "Orden inmutable."])])
        let renderer = CoreGraphicsBillingPDFRenderer()
        let first = try billingPDFSnapshot(await renderer.render(request))
        let repeated = try billingPDFSnapshot(await renderer.render(request))
        let independent = try billingPDFSnapshot(await CoreGraphicsBillingPDFRenderer().render(request))

        #expect(first == repeated)
        #expect(first == independent)
        #expect(first.texts.count == 1)
        #expect(first.texts[0].contains("Orden inmutable."))
    }

    @Test(arguments: [
        (-62_135_596_800.0, "0001-01-01"),
        (86_399.0, "1970-01-01"),
        (86_400.0, "1970-01-02"),
        (253_402_300_799.5, "9999-12-31")
    ])
    func `issue date uses complete UTC calendar bounds and the confirmed number`(
        seconds: Double,
        expectedDate: String
    ) async throws {
        let document = try billingPDFDocument(issuedAt: Date(timeIntervalSince1970: seconds), number: 73)
        let request = try billingPDFRequest(document: document)
        let snapshot = try billingPDFSnapshot(await CoreGraphicsBillingPDFRenderer().render(request))

        #expect(snapshot.texts[0].contains("73"))
        #expect(snapshot.texts[0].contains(expectedDate))
    }

    @Test
    func `one hundred explicit pages are all published without implicit pagination or page loss`() async throws {
        let pages = try (1...100).map { index in
            try billingPDFPage(["PAGE \(index) OF 100"])
        }
        let request = try billingPDFRequest(pages: pages)
        let pdf = try #require(PDFDocument(data: await CoreGraphicsBillingPDFRenderer().render(request)))

        #expect(pdf.pageCount == 100)
        #expect(pdf.page(at: 0)?.string?.contains("PAGE 1 OF 100") == true)
        #expect(pdf.page(at: 99)?.string?.contains("PAGE 100 OF 100") == true)
    }

    @Test(arguments: ["", " \n\t "])
    func `missing visible field and title content is rejected before rendering`(text: String) throws {
        #expect(throws: BillingPDFRenderError.missingContent) {
            try BillingPDFTextField(text: text, frame: billingPDFRectangle())
        }
        #expect(throws: BillingPDFRenderError.missingContent) {
            try billingPDFRequest(title: text)
        }
    }

    @Test
    func `empty pages and empty page lists cannot be published`() throws {
        #expect(throws: BillingPDFRenderError.missingContent) {
            try BillingPDFPage(fields: [])
        }
        #expect(throws: BillingPDFRenderError.missingContent) {
            try billingPDFRequest(pages: [])
        }
    }

    @Test(arguments: BillingPDFInvalidRectangle.allCases)
    func `nonfinite empty negative and off paper rectangles are rejected`(geometry: BillingPDFInvalidRectangle) throws {
        #expect(throws: BillingPDFRenderError.invalidLayout) {
            try geometry.make()
        }
    }

    @Test(arguments: [Double.nan, .infinity, 5.99, 24.01])
    func `font sizes outside the finite supported range are rejected`(size: Double) throws {
        #expect(throws: BillingPDFRenderError.invalidLayout) {
            try BillingPDFTextField(text: "Visible", frame: billingPDFRectangle(), fontSize: size)
        }
    }

    @Test(arguments: [6.0, 24.0])
    func `both supported font endpoints preserve their complete text`(size: Double) async throws {
        let field = try BillingPDFTextField(text: "FONT BOUNDARY", frame: billingPDFRectangle(), fontSize: size)
        let request = try billingPDFRequest(pages: [BillingPDFPage(fields: [field])])
        let snapshot = try billingPDFSnapshot(await CoreGraphicsBillingPDFRenderer().render(request))

        #expect(snapshot.texts[0].contains("FONT BOUNDARY"))
    }

    @Test(arguments: BillingPDFInvalidBudget.allCases)
    func `content page and UTF16 budgets reject excess instead of truncating`(budget: BillingPDFInvalidBudget) throws {
        #expect(throws: BillingPDFRenderError.limitExceeded) {
            try budget.make()
        }
    }

    @Test(arguments: [-62_135_596_801.0, 253_402_300_800.0])
    func `issue dates outside years one through nine thousand nine hundred ninety nine are rejected`(
        seconds: Double
    ) throws {
        let document = try billingPDFDocument(issuedAt: Date(timeIntervalSince1970: seconds))
        #expect(throws: BillingPDFRenderError.invalidDate) {
            try billingPDFRequest(document: document)
        }
    }

    @Test(arguments: BillingPDFOverlap.allCases)
    func `headers body fields and final signature must not obscure one another`(overlap: BillingPDFOverlap) throws {
        #expect(throws: BillingPDFRenderError.invalidLayout) {
            try overlap.make()
        }
    }

    @Test
    func `touching field edges remain valid and retain both complete fields`() async throws {
        let first = try BillingPDFTextField(text: "TOP FIELD", frame: billingPDFRectangle(y: 650))
        let second = try BillingPDFTextField(text: "BOTTOM FIELD", frame: billingPDFRectangle(y: 610))
        let request = try billingPDFRequest(pages: [BillingPDFPage(fields: [first, second])])
        let snapshot = try billingPDFSnapshot(await CoreGraphicsBillingPDFRenderer().render(request))

        #expect(snapshot.texts[0].contains("TOP FIELD"))
        #expect(snapshot.texts[0].contains("BOTTOM FIELD"))
    }

    @Test(arguments: BillingPDFOverflow.allCases)
    func `glyph and header overflow throws rather than clipping or returning partial data`(
        overflow: BillingPDFOverflow
    ) async throws {
        let request = try overflow.request()
        await #expect(throws: BillingPDFRenderError.textDoesNotFit) {
            try await CoreGraphicsBillingPDFRenderer().render(request)
        }
    }

    @Test
    func `a failed text layout does not poison a following valid operation`() async throws {
        let renderer = CoreGraphicsBillingPDFRenderer()
        let overflow = try BillingPDFOverflow.unbreakableWord.request()
        await #expect(throws: BillingPDFRenderError.textDoesNotFit) {
            try await renderer.render(overflow)
        }
        let valid = try billingPDFRequest()
        let snapshot = try billingPDFSnapshot(await renderer.render(valid))

        #expect(snapshot.texts[0].contains("Contenido sintético completo."))
    }

    @Test(arguments: [Data(), Data("synthetic non-PDF resource".utf8)])
    func `invalid background bytes fail with the reusable asset validation error`(template: Data) async throws {
        let request = try billingPDFRequest(template: template)
        await #expect(throws: BillingAssetError.invalidTemplate) {
            try await CoreGraphicsBillingPDFRenderer().render(request)
        }
    }

    @Test(arguments: [1, 2])
    func `a background must be a single portrait A4 page`(variant: Int) async throws {
        let template: Data
        if variant == 1 {
            template = try billingPDFTemplate(bounds: CGRect(
                x: 0,
                y: 0,
                width: 612,
                height: 792
            ))
        } else {
            template = try billingPDFTemplate(pageCount: 2)
        }
        let request = try billingPDFRequest(template: template)
        await #expect(throws: BillingAssetError.invalidTemplate) {
            try await CoreGraphicsBillingPDFRenderer().render(request)
        }
    }

    @Test(arguments: [Data(), Data("synthetic invalid signature".utf8)])
    func `invalid optional image bytes fail without publishing a PDF`(image: Data) async throws {
        let signature = try BillingPDFSignature(data: image, frame: billingPDFRectangle(y: 60))
        let request = try billingPDFRequest(signature: signature)
        await #expect(throws: BillingAssetError.invalidSignature) {
            try await CoreGraphicsBillingPDFRenderer().render(request)
        }
    }

    @Test
    func `signature preserves its image proportions inside the final page frame only`() async throws {
        let signature = try BillingPDFSignature(
            data: billingPDFSignatureImage(),
            frame: billingPDFRectangle(
                x: 400,
                y: 60,
                width: 100,
                height: 100
            )
        )
        let request = try billingPDFRequest(
            pages: [billingPDFPage(["FIRST PAGE"]), billingPDFPage(["LAST PAGE"])],
            signature: signature
        )
        let bytes = try await CoreGraphicsBillingPDFRenderer().render(request)
        let provider = try #require(CGDataProvider(data: bytes as CFData))
        let pdf = try #require(CGPDFDocument(provider))
        let first = try #require(pdf.page(at: 1))
        let last = try #require(pdf.page(at: 2))
        Attachment.record(signature.data, named: "synthetic-source-signature.png")
        Attachment.record(bytes, named: "synthetic-final-render.pdf")
        let expected = try billingPDFSignatureOracleBounds()
        let actual = try #require(try billingPDFMagentaBounds(last))

        #expect(try billingPDFMagentaBounds(first) == nil)
        #expect(abs(actual.minX - expected.minX) < 2)
        #expect(abs(actual.minY - expected.minY) < 2)
        #expect(abs(actual.width - expected.width) < 2)
        #expect(abs(actual.height - expected.height) < 2)
    }

    @Test
    func `a missing signature succeeds and leaves no image footprint`() async throws {
        let request = try billingPDFRequest()
        let bytes = try await CoreGraphicsBillingPDFRenderer().render(request)
        let provider = try #require(CGDataProvider(data: bytes as CFData))
        let pdf = try #require(CGPDFDocument(provider))
        let page = try #require(pdf.page(at: 1))

        #expect(try billingPDFMagentaBounds(page) == nil)
        #expect(try billingPDFSnapshot(bytes).texts[0].contains("Contenido sintético completo."))
    }

    @Test
    func `a request canceled before actor work never returns PDF bytes`() async throws {
        let request = try billingPDFRequest()
        let renderer = CoreGraphicsBillingPDFRenderer()
        let gate = RecoveryOperationGate()
        let task = Task {
            await gate.enter()
            return try await renderer.render(request)
        }
        try #require(await gate.waitForEntry())
        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }

    @MainActor
    @Test
    func `a MainActor caller receives the complete PDF through the actor port`() async throws {
        let renderer: any BillingPDFRenderer = CoreGraphicsBillingPDFRenderer()
        let request = try billingPDFRequest()
        let bytes = try await renderer.render(request)
        let snapshot = try billingPDFSnapshot(bytes)

        #expect(snapshot.texts[0].contains("41"))
        #expect(snapshot.texts[0].contains("1970-01-01"))
        #expect(snapshot.texts[0].contains("Contenido sintético completo."))
    }
}
