import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing fiscal request transport")
struct BillingFiscalRequestDTOTests {
    @Test
    func `a historical invoice without recipient still allocates and replays its original paid request`() async throws {
        let dto = try JSONDecoder().decode(
            BillingDocumentRequestDTO.self,
            from: fiscalRequestFixtureBytes(version: 1, recipient: nil)
        )
        let request = try dto.toDomain()
        let ledger = BillingTransactionLedger()
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)

        let document = try await repository.reserve(request)
        let committed = await ledger.state()
        let replay = try await repository.reserve(request)

        #expect(request.fiscalRecipient == nil)
        #expect(document.number.series == .invoice)
        #expect(document.number.value == 1)
        #expect(replay == document)
        #expect(await ledger.state() == committed)
        #expect(committed.commits == 1)
    }

    @Test
    func `an external version two invoice reaches numbered recovery with the complete recipient snapshot`() async throws {
        let dto = try JSONDecoder().decode(BillingDocumentRequestDTO.self, from: fiscalRequestFixtureBytes())
        let request = try dto.toDomain()
        let ledger = BillingTransactionLedger()
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)

        let document = try await repository.reserve(request)
        let replay = try await repository.reserve(request)
        let recipient = try #require(document.request.fiscalRecipient)

        #expect(recipient.displayName == "Ana  Núñez")
        #expect(recipient.taxIdentifier == "doc-ID/Ñ")
        #expect(recipient.billingAddress == BillingAddress(
            streetLine: "Calle  Sol 12",
            postalCode: "SW1A 1AA",
            city: "Madrid",
            province: "Comunidad de Madrid"
        ))
        #expect(document.number.value == 1)
        #expect(replay == document)
        #expect(await ledger.state().commits == 1)
    }

    @Test(arguments: [
        FiscalRequestFixtureCorruption.legacyRecipient, .legacyNull, .missing, .null,
        .ticketRecipient, .unknownVersion, .unknownRecipientField, .unknownRequestField, .blankCity
    ])
    func `incompatible malformed or unknown fiscal transport cannot create records`(
        _ corruption: FiscalRequestFixtureCorruption
    ) async throws {
        let ledger = BillingTransactionLedger()
        let bytes = try corruption.bytes()

        do {
            let dto = try JSONDecoder().decode(BillingDocumentRequestDTO.self, from: bytes)
            let request = try dto.toDomain()
            _ = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
            Issue.record("The invalid fiscal payload reached allocation")
        } catch {
            #expect(error is DecodingError || error as? BillingDocumentReservationError == .invalidResponse)
        }

        #expect(await ledger.calls == 0)
        #expect(await ledger.state().commits == 0)
        #expect(await ledger.state().documents.isEmpty)
    }

    @Test
    func `new invoice encoding selects v2 and legacy encoding omits the recipient key`() throws {
        let sale = try viewModelSale(stage: .awaitingDocument)
        let request = try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: viewModelUUID(1701)),
            documentID: BillingDocumentID(rawValue: viewModelUUID(1801)),
            sale: sale,
            kind: .invoice,
            requestedAt: Date(timeIntervalSinceReferenceDate: 1),
            fiscalRecipient: BillingFiscalRecipient(billingFiscalInput())
        )
        let encoder = JSONEncoder()
        let invoiceWire = try JSONDecoder().decode(
            FiscalRequestWireContract.self,
            from: encoder.encode(BillingDocumentRequestDTO(request))
        )
        let legacyWire = try JSONDecoder().decode(
            FiscalRequestWireContract.self,
            from: encoder.encode(BillingDocumentRequestDTO(billingTransactionRequest(kind: .invoice)))
        )

        #expect(invoiceWire.payloadVersion == 2)
        #expect(invoiceWire.keys == Set([
            "payloadVersion", "id", "documentID", "kind", "requestedAt", "sale", "fiscalRecipient"
        ]))
        #expect(invoiceWire.recipientKeys == Set([
            "displayName", "taxIdentifier", "streetLine", "postalCode", "city", "province"
        ]))
        #expect(legacyWire.payloadVersion == 1)
        #expect(legacyWire.keys == Set(["payloadVersion", "id", "documentID", "kind", "requestedAt", "sale"]))
        #expect(legacyWire.recipientKeys == nil)
    }
}

private let fiscalRecipientFixtureJSON = """
{"displayName":"Ana  Núñez","taxIdentifier":"doc-ID/Ñ","streetLine":"Calle  Sol 12",
"postalCode":"SW1A 1AA","city":"Madrid","province":"Comunidad de Madrid"}
"""

private func fiscalRequestFixtureBytes(
    version: Int = 2,
    kind: BillingDocumentKind = .invoice,
    recipient: String? = fiscalRecipientFixtureJSON,
    extraRequestField: String = ""
) throws -> Data {
    let saleBytes = try JSONEncoder().encode(SaleDTO(viewModelSale(stage: .awaitingDocument)))
    let saleJSON = try #require(String(data: saleBytes, encoding: .utf8))
    let fiscalJSON = recipient.map { ",\"fiscalRecipient\":\($0)" } ?? ""
    return Data("""
    {"payloadVersion":\(version),"id":"00000000-0000-0000-0000-000000001701",
    "documentID":"00000000-0000-0000-0000-000000001801","kind":"\(kind.rawValue)",
    "requestedAt":"3ff0000000000000","sale":\(saleJSON)\(fiscalJSON)\(extraRequestField)}
    """.utf8)
}

enum FiscalRequestFixtureCorruption {
    case legacyRecipient, legacyNull, missing, null, ticketRecipient, unknownVersion
    case unknownRecipientField, unknownRequestField, blankCity

    fileprivate func bytes() throws -> Data {
        switch self {
        case .legacyRecipient:
            try fiscalRequestFixtureBytes(version: 1)
        case .legacyNull:
            try fiscalRequestFixtureBytes(version: 1, recipient: "null")
        case .missing:
            try fiscalRequestFixtureBytes(recipient: nil)
        case .null:
            try fiscalRequestFixtureBytes(recipient: "null")
        case .ticketRecipient:
            try fiscalRequestFixtureBytes(kind: .ticket)
        case .unknownVersion:
            try fiscalRequestFixtureBytes(version: 3)
        case .unknownRecipientField:
            try fiscalRequestFixtureBytes(recipient: fiscalRecipientFixtureJSON.replacingOccurrences(
                of: "\"displayName\":",
                with: "\"unrecognized\":true,\"displayName\":"
            ))
        case .unknownRequestField:
            try fiscalRequestFixtureBytes(extraRequestField: ",\"unrecognized\":true")
        case .blankCity:
            try fiscalRequestFixtureBytes(recipient: fiscalRecipientFixtureJSON.replacingOccurrences(
                of: "\"city\":\"Madrid\"",
                with: "\"city\":\" \""
            ))
        }
    }
}

private struct FiscalRequestWireContract: Decodable {
    let payloadVersion: Int
    let keys: Set<String>
    let recipientKeys: Set<String>?
}

extension FiscalRequestWireContract {
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: FiscalWireKey.self)
        keys = Set(container.allKeys.map(\.stringValue))
        payloadVersion = try container.decode(Int.self, forKey: FiscalWireKey(stringValue: "payloadVersion"))
        let recipientKey = FiscalWireKey(stringValue: "fiscalRecipient")
        if container.contains(recipientKey) {
            let recipient = try container.nestedContainer(keyedBy: FiscalWireKey.self, forKey: recipientKey)
            recipientKeys = Set(recipient.allKeys.map(\.stringValue))
        } else {
            recipientKeys = nil
        }
    }
}

private struct FiscalWireKey: CodingKey {
    private let rawKey: String
    var stringValue: String { rawKey }
    var intValue: Int? { nil }
}

extension FiscalWireKey {
    init(stringValue: String) { self.init(rawKey: stringValue) }
    init?(intValue: Int) { return nil }
}
