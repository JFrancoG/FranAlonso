import CoreGraphics
import Foundation
import PDFKit
import Testing
@testable import FranAlonso

@Suite("Confirmed ticket and invoice PDF composition")
struct BillingDocumentPDFComposerTests {
    @Test("Real template pipeline publishes captured fiscal and commercial terms", arguments: [
        BillingDocumentKind.ticket, .invoice
    ])
    func realTemplateSnapshots(kind: BillingDocumentKind) async throws {
        let line = try billingRenderingLine(name: "MUESTRA: corte histórico, café y niño.", lineDiscount: "10")
        let document = try billingRenderingDocument(kind: kind, lines: [line], globalDiscount: "20")
        let bytes = try await billingRenderingPipeline()(document)
        let pdf = try #require(PDFDocument(data: bytes))
        let content = billingRenderingCompact(try #require(pdf.string))
        #expect(!bytes.isEmpty)
        for expected in [
            "PLANTILLAPROVISIONAL", "MUESTRA:cortehistórico,caféyniño.", "Preciounitario:100,00",
            "TipoIVA:21%", "Promocióndelínea:10%", "Descuentoglobal:20%", "Base:59,50",
            "IVAcalculado:12,50", "Dto.línea:10,00", "Dto.global:18,00", "72,00"
        ] {
            #expect(content.contains(expected))
        }
        if kind == .invoice {
            let fiscal = try billingRenderingFiscalRecipient()
            for field in BillingFiscalField.allCases {
                #expect(content.contains(billingRenderingCompact(fiscal.input[field])))
            }
        }
        Attachment.record(bytes, named: kind == .ticket ? "13-8-ticket-sample.pdf" : "13-8-invoice-sample.pdf")
    }

    @Test("PDF preserves exact cents signs and captured percentage digits", arguments: [
        ("0.07", "50", "50", "0", "0,01", "0,04", "0,02"),
        ("-100", "10", "20", "21", "-72,00", "-10,00", "-18,00"),
        ("19.99", "12.5", "12.345678901234567890123456789012345678", "21", "15,33", "2,50", "2,16")
    ])
    func exactHistoricalTerms(
        price: String,
        promotion: String,
        global: String,
        tax: String,
        total: String,
        lineAmount: String,
        globalAmount: String
    ) async throws {
        let line = try billingRenderingLine(price: price, tax: tax, lineDiscount: promotion)
        let document = try billingRenderingDocument(lines: [line], globalDiscount: global)
        let pdf = try #require(PDFDocument(data: await billingRenderingPipeline()(document)))
        let content = billingRenderingCompact(try #require(pdf.string))
        #expect(content.contains(total))
        #expect(content.contains("Dto.línea:" + lineAmount))
        #expect(content.contains("Dto.global:" + globalAmount))
        #expect(content.contains("Descuentoglobal:" + global.replacingOccurrences(of: ".", with: ",") + "%"))
    }

    @Test("All lines survive all pages and complete sale totals appear once", arguments: [
        BillingDocumentKind.ticket, .invoice
    ])
    func manyLinesAndFinalTotals(kind: BillingDocumentKind) async throws {
        let lines = try (1...20).map {
            try billingRenderingLine(
                name: "MUESTRA-ÚNICA-\($0)-FIN",
                price: "10",
                tax: "0",
                index: $0
            )
        }
        let document = try billingRenderingDocument(kind: kind, lines: lines)
        let bytes = try await billingRenderingPipeline(signature: billingPDFSignatureImage())(document)
        let pdf = try #require(PDFDocument(data: bytes))
        #expect(pdf.pageCount == (kind == .ticket ? 10 : 12))
        let text = billingRenderingCompact(try #require(pdf.string))
        for index in 1...20 {
            #expect(text.components(separatedBy: "MUESTRA-ÚNICA-\(index)-FIN").count == 2)
        }
        for index in 0..<pdf.pageCount {
            let content = billingRenderingCompact(try #require(pdf.page(at: index)?.string))
            #expect(content.contains("PLANTILLAPROVISIONAL"))
            #expect(content.contains(String(document.number.value)))
            #expect(content.contains("2025-10-03"))
            #expect(content.contains("Página\(index + 1)/\(pdf.pageCount)"))
            if index < pdf.pageCount - 1 {
                #expect(content.contains("Totalesdelaventaenlaúltimapágina."))
                #expect(!content.contains("Subtotal:200,00"))
            } else {
                #expect(content.contains("Subtotal:200,00"))
                #expect(content.contains("200,00"))
            }
        }
        let provider = try #require(CGDataProvider(data: bytes as CFData))
        let graphics = try #require(CGPDFDocument(provider))
        for index in 1...graphics.numberOfPages {
            let bounds = try billingPDFMagentaBounds(try #require(graphics.page(at: index)))
            #expect((bounds != nil) == (index == graphics.numberOfPages))
        }
        Attachment.record(bytes, named: kind == .ticket ? "13-8-ticket-many-lines.pdf" : "13-8-invoice-many-lines.pdf")
    }

    @Test("Long Unicode name is reconstructed without losing a character")
    func completeUnicodePagination() async throws {
        let name = String(repeating: "MUESTRA café niño e\u{301} 👩🏽‍💻 fin. ", count: 80)
        let document = try billingRenderingDocument(lines: [billingRenderingLine(name: name)])
        let template = try await BundleBillingDocumentTemplateRepository(bundle: .main).loadTemplate(for: .ticket)
        let plan = try await TemplateBillingDocumentPDFComposer(bundle: .main).compose(
            BillingDocumentProjection(document: document),
            template: template,
            signature: nil
        )
        let descriptions = plan.pages.flatMap(\.fields).filter { $0.frame.x == 85 }.map(\.text).joined()
        #expect(descriptions.hasPrefix("1. " + name))
        #expect(plan.pages.count > 1)
        let bytes = try await CoreGraphicsBillingPDFRenderer().render(plan)
        #expect(PDFDocument(data: bytes)?.pageCount == plan.pages.count)
        Attachment.record(bytes, named: "13-8-ticket-long-unicode.pdf")
    }

    @Test("Absent zero and full discounts remain explicit", arguments: [nil, "0", "100"])
    func distinctDiscountTerms(discount: String?) async throws {
        let line = try billingRenderingLine(price: "10", tax: "0", lineDiscount: discount)
        let document = try billingRenderingDocument(lines: [line], globalDiscount: discount)
        let pdf = try #require(PDFDocument(data: await billingRenderingPipeline()(document)))
        let content = billingRenderingCompact(try #require(pdf.string))
        let term = discount.map { $0 + "%" } ?? "Ausente"
        #expect(content.contains("Promocióndelínea:" + term))
        #expect(content.contains("Descuentoglobal:" + term))
        #expect(content.contains(discount == "100" ? "Subtotal:10,00" : "Base:10,00"))
    }

    @Test("Independent actors produce identical semantic snapshots")
    func semanticDeterminism() async throws {
        let document = try billingRenderingDocument(kind: .invoice)
        let first = try billingPDFSnapshot(await billingRenderingPipeline()(document))
        let second = try billingPDFSnapshot(await billingRenderingPipeline()(document))
        #expect(first == second)
    }

    @Test("Complete oversized numeric cells fail instead of clipping", arguments: [Int.max, 1])
    func oversizedNumericCells(quantity: Int) async throws {
        let line = try billingRenderingLine(price: quantity == 1 ? "9007199254740993.01" : "0", quantity: quantity)
        let document = try billingRenderingDocument(kind: .invoice, lines: [line])
        await #expect(throws: BillingPDFRenderError.textDoesNotFit) {
            try await billingRenderingPipeline()(document)
        }
    }

    @Test("Oversized fiscal value fails without profile enrichment")
    func oversizedFiscalSnapshot() async throws {
        let fiscal = try BillingFiscalRecipient(BillingFiscalRecipientInput(
            displayName: String(repeating: "Nombre sintético largo ", count: 100),
            taxIdentifier: "SYNTHETIC-13-8",
            streetLine: "Calle de muestra 13",
            postalCode: "00000",
            city: "Ciudad sintética",
            province: "Provincia sintética"
        ))
        let document = try billingRenderingDocument(kind: .invoice, fiscalRecipient: fiscal)
        await #expect(throws: BillingPDFRenderError.textDoesNotFit) {
            try await billingRenderingPipeline()(document)
        }
    }

    @Test("Content budget rejects an oversized name without truncation")
    func oversizedContentBudget() async throws {
        let line = try billingRenderingLine(name: String(repeating: "x", count: 200_001))
        let document = try billingRenderingDocument(lines: [line])
        await #expect(throws: BillingPDFRenderError.limitExceeded) {
            try await billingRenderingPipeline()(document)
        }
    }

    @Test("The complete-sale composer admits one hundred pages and rejects the next row", arguments: [180, 181])
    func pageBudgetBoundary(lineCount: Int) async throws {
        let lines = try (1...lineCount).map {
            try billingRenderingLine(
                name: "MUESTRA-ÚNICA-\($0)-FIN",
                price: "10",
                tax: "0",
                index: $0
            )
        }
        let projection = try BillingDocumentProjection(document: billingRenderingDocument(kind: .invoice, lines: lines))
        let template = try await BundleBillingDocumentTemplateRepository(bundle: .main).loadTemplate(for: .invoice)
        let composer = TemplateBillingDocumentPDFComposer(bundle: .main)
        if lineCount == 180 {
            let plan = try await composer.compose(projection, template: template, signature: nil)
            #expect(plan.pages.count == 100)
            let text = plan.pages.flatMap(\.fields).map(\.text).joined()
            for index in 1...180 {
                #expect(text.components(separatedBy: "MUESTRA-ÚNICA-\(index)-FIN").count == 2)
            }
        } else {
            await #expect(throws: BillingPDFRenderError.limitExceeded) {
                try await composer.compose(projection, template: template, signature: nil)
            }
        }
    }

    @Test("Invalid captured resources retain recoverable errors")
    func rejectedResources() async throws {
        let document = try billingRenderingDocument()
        await #expect(throws: BillingAssetError.invalidTemplate) {
            try await TemplateBillingDocumentPDFComposer(bundle: .main).compose(
                BillingDocumentProjection(document: document),
                template: Data("corrupt".utf8),
                signature: nil
            )
        }
        await #expect(throws: BillingAssetError.invalidSignature) {
            try await billingRenderingPipeline(signature: Data("corrupt".utf8))(document)
        }
    }
}

private func billingRenderingPipeline(signature: Data? = nil) -> RenderBillingDocumentUseCase {
    RenderBillingDocumentUseCase(
        templates: BundleBillingDocumentTemplateRepository(bundle: .main),
        signatures: BillingRenderingCapturedSignature(bytes: signature),
        composer: TemplateBillingDocumentPDFComposer(bundle: .main),
        renderer: CoreGraphicsBillingPDFRenderer()
    )
}

private struct BillingRenderingCapturedSignature: BillingBusinessSignatureRepository {
    let bytes: Data?

    func loadSignature() async throws -> Data? { bytes }
    func importSignature(_ data: Data) async throws {
        throw BillingAssetError.unauthorized
    }
}

private func billingRenderingCompact(_ text: String) -> String { text.filter { !$0.isWhitespace } }
