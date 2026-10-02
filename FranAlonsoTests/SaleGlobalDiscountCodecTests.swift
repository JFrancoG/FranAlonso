import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale global discount codecs")
struct SaleGlobalDiscountCodecTests {
    @Test("An authentic SaleDTO v1 retains its version and promotion without a global key")
    func historicalDTOReencodesWithoutGlobalKey() throws {
        let dto = try JSONDecoder().decode(SaleDTO.self, from: Data(SaleGlobalDiscountDataFixture.saleV1.utf8))
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        let encoded = String(decoding: try encoder.encode(dto), as: UTF8.self)
        let sale = try dto.toDomain()

        #expect(encoded == SaleGlobalDiscountDataFixture.saleV1)
        #expect(sale.globalDiscount == nil)
        #expect(try SaleCalculator().calculate(sale: sale, currency: .eur).total.amount == 90)
    }

    @Test("New Domain snapshots write SaleDTO v2 and preserve sequential historical pricing")
    func domainWriterUsesVersionTwo() throws {
        let dto = try SaleDTO(SaleGlobalDiscountDataFixture.domain(globalPercentage: 20))
        let encoded = try JSONEncoder().encode(dto)
        let sale = try JSONDecoder().decode(SaleDTO.self, from: encoded).toDomain()

        #expect(dto.payloadVersion == 2)
        #expect(sale.globalDiscount?.policy == .lineThenGlobalV1)
        #expect(sale.globalDiscount?.discount.percentage == 20)
        #expect(sale.lines.first?.discount?.percentage == 10)
        #expect(try SaleCalculator().calculate(sale: sale, currency: .eur).total.amount == 72)
    }

    @Test(
        "V2 distinguishes absent zero fractional and full global terms",
        arguments: [
            GlobalCodecCase(global: nil, percentage: nil, total: "90"),
            GlobalCodecCase(global: "null", percentage: nil, total: "90"),
            GlobalCodecCase(global: #"{"percentage":"0","policy":"lineThenGlobalV1"}"#, percentage: "0", total: "90"),
            GlobalCodecCase(global: #"{"percentage":"20.5","policy":"lineThenGlobalV1"}"#, percentage: "20.5", total: "71.55"),
            GlobalCodecCase(global: #"{"percentage":"100","policy":"lineThenGlobalV1"}"#, percentage: "100", total: "0")
        ]
    )
    func versionTwoUsesValidatedGlobalTerm(_ testCase: GlobalCodecCase) throws {
        let bytes = Data(SaleGlobalDiscountDataFixture.salePayload(version: 2, global: testCase.global).utf8)
        let sale = try JSONDecoder().decode(SaleDTO.self, from: bytes).toDomain()
        let expectedPercentage = testCase.percentage.flatMap { Decimal(string: $0) }
        let calculation = try SaleCalculator().calculate(sale: sale, currency: .eur)

        #expect(sale.globalDiscount?.discount.percentage == expectedPercentage)
        #expect(calculation.total.amount == Decimal(string: testCase.total))
    }

    @Test("V1 rejects a global key including null", arguments: ["null", SaleGlobalDiscountDataFixture.global20])
    func versionOneRejectsAnyGlobalKey(_ global: String) {
        let bytes = Data(SaleGlobalDiscountDataFixture.salePayload(version: 1, global: global).utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(SaleDTO.self, from: bytes).toDomain()
        }
    }

    @Test(
        "V2 refuses unknown policy noncanonical percentage out of range and extra term keys",
        arguments: [
            #"{"percentage":"20","policy":"future"}"#,
            #"{"percentage":"20.0","policy":"lineThenGlobalV1"}"#,
            #"{"percentage":"+20","policy":"lineThenGlobalV1"}"#,
            #"{"percentage":"2e1","policy":"lineThenGlobalV1"}"#,
            #"{"percentage":"-1","policy":"lineThenGlobalV1"}"#,
            #"{"percentage":"101","policy":"lineThenGlobalV1"}"#,
            #"{"percentage":"20","policy":"lineThenGlobalV1","unexpected":true}"#,
            #"{"percentage":"20"}"#,
            #"{"policy":"lineThenGlobalV1"}"#
        ]
    )
    func invalidGlobalTermsFailClosed(_ global: String) {
        let bytes = Data(SaleGlobalDiscountDataFixture.salePayload(version: 2, global: global).utf8)

        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(SaleDTO.self, from: bytes).toDomain()
        }
    }

    @Test("Unsupported aggregate payload versions fail closed", arguments: [0, 3, Int.max])
    func unsupportedAggregateVersionsFailClosed(_ version: Int) {
        let bytes = Data(SaleGlobalDiscountDataFixture.salePayload(version: version, global: nil).utf8)

        #expect(throws: (any Error).self) {
            _ = try JSONDecoder().decode(SaleDTO.self, from: bytes).toDomain()
        }
    }

    @Test("Reading authentic local1 neither upgrades its array nor creates global terms")
    func localVersionOneRemainsByteExact() throws {
        let model = SaleGlobalDiscountDataFixture.rawModel()
        let sale = try model.toDomain()

        #expect(model.linesPayloadVersion == 1)
        #expect(model.linesData == Data(SaleGlobalDiscountDataFixture.linesV1.utf8))
        #expect(sale.globalDiscount == nil)
        #expect(try SaleCalculator().calculate(sale: sale, currency: .eur).total.amount == 90)
    }

    @Test("Local2 replays the envelope promotion and global policy into pricing")
    func localVersionTwoReconstructsSequentialPricing() throws {
        let bytes = Data(#"{"lines":\#(SaleGlobalDiscountDataFixture.linesV1),"globalDiscount":\#(SaleGlobalDiscountDataFixture.global20)}"#.utf8)
        let model = SaleGlobalDiscountDataFixture.rawModel(version: 2, bytes: bytes)
        let sale = try model.toDomain()

        #expect(sale.globalDiscount?.policy == .lineThenGlobalV1)
        #expect(sale.lines.first?.discount?.percentage == 10)
        #expect(try SaleCalculator().calculate(sale: sale, currency: .eur).total.amount == 72)
        #expect(model.linesData == bytes)
    }

    @Test("A new flattened snapshot writes a local2 envelope even without a global term")
    func localWriterUsesEnvelopeTwo() throws {
        let model = try SaleModel(SaleGlobalDiscountDataFixture.domain())
        let envelope = try JSONDecoder().decode(GlobalLocalEnvelopeInspection.self, from: model.linesData)

        #expect(model.linesPayloadVersion == 2)
        #expect(envelope.lines.count == 1)
        #expect(envelope.globalDiscount == nil)
        #expect(try SaleCalculator().calculate(sale: model.toDomain(), currency: .eur).total.amount == 90)
    }

    @Test(
        "Malformed local2 envelopes fail closed instead of discarding their global terms",
        arguments: [
            SaleGlobalDiscountDataFixture.linesV1,
            #"{"lines":\#(SaleGlobalDiscountDataFixture.linesV1),"globalDiscount":{"percentage":"20","policy":"future"}}"#,
            #"{"lines":\#(SaleGlobalDiscountDataFixture.linesV1),"globalDiscount":{"percentage":"20.0","policy":"lineThenGlobalV1"}}"#,
            #"{"lines":\#(SaleGlobalDiscountDataFixture.linesV1),"globalDiscount":\#(SaleGlobalDiscountDataFixture.global20),"unexpected":true}"#
        ]
    )
    func invalidLocalEnvelopesFailClosed(_ payload: String) {
        let model = SaleGlobalDiscountDataFixture.rawModel(version: 2, bytes: Data(payload.utf8))

        #expect(throws: (any Error).self) {
            _ = try model.toDomain()
        }
    }

    @Test("Payment closure and void transport retain the global policy and captured promotion")
    func terminalSnapshotsRetainCommercialTerms() throws {
        var sale = try SaleGlobalDiscountDataFixture.domain(globalPercentage: 20)
        try sale.start()
        let line = try #require(sale.lines.first)
        try sale.startLine(id: line.id)
        try sale.completeLine(id: line.id)
        try sale.registerPayment(
            id: PaymentID(rawValue: UUID(uuidString: "92000000-0000-0000-0000-000000000040")!),
            method: .card,
            paidAt: Date(timeIntervalSinceReferenceDate: 2)
        )
        let paidDTO = try SaleDTO(sale).toDomain()
        #expect(paidDTO.globalDiscount?.discount.percentage == 20)
        try sale.close(
            documentID: BillingDocumentID(rawValue: UUID(uuidString: "92000000-0000-0000-0000-000000000041")!),
            closedAt: Date(timeIntervalSinceReferenceDate: 3)
        )
        let closedLocal = try SaleModel(sale).toDomain()
        #expect(closedLocal.globalDiscount?.policy == .lineThenGlobalV1)
        try sale.void(
            reversalID: SaleReversalID(rawValue: UUID(uuidString: "92000000-0000-0000-0000-000000000042")!),
            voidedAt: Date(timeIntervalSinceReferenceDate: 4)
        )
        let voidedDTO = try SaleDTO(sale).toDomain()
        let voidedLocal = try SaleModel(sale).toDomain()

        #expect(voidedDTO == sale)
        #expect(voidedLocal == sale)
        #expect(voidedLocal.lines.first?.discount?.percentage == 10)
        #expect(try SaleCalculator().calculate(sale: voidedLocal, currency: .eur).total.amount == 72)
    }
}

struct GlobalCodecCase {
    let global: String?
    let percentage: String?
    let total: String
}

private struct GlobalLocalEnvelopeInspection: Decodable {
    let lines: [SaleLineDTO]
    let globalDiscount: GlobalTermInspection?
}

private struct GlobalTermInspection: Decodable {
    let percentage: String
    let policy: String
}
