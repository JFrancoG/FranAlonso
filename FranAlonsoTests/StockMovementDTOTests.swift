import Foundation
import Testing

@testable import FranAlonso

@Suite("Stock immutable wire payload")
struct StockMovementDTOTests {
    @Test(arguments: [false, true])
    func `manual and sale origins preserve signed units and exact fractional dates`(sale: Bool) throws {
        let id = StockMovementID(rawValue: UUID())
        let date = Date(timeIntervalSinceReferenceDate: 1234.567890123)
        let movement = try StockMovement(
            id: id,
            productID: ProductID(rawValue: UUID()),
            quantityDelta: -11,
            reason: "Accepted reason",
            occurredAt: date,
            origin: sale
                ? .sale(
                    saleID: SaleID(rawValue: UUID()),
                    lineID: SaleLineID(rawValue: UUID()),
                    paymentID: PaymentID(rawValue: UUID())
                ) : .manual(reference: id)
        )
        let dto = try StockMovementDTO(movement)
        let bytes = try JSONEncoder().encode(dto)
        let restored = try JSONDecoder().decode(StockMovementDTO.self, from: bytes).toDomain()
        #expect(restored == movement)
        #expect(
            restored.occurredAt.timeIntervalSinceReferenceDate.bitPattern
                == date.timeIntervalSinceReferenceDate.bitPattern
        )
        #expect(restored.quantityDelta == -11)
    }

    @Test(arguments: ["version", "noncanonicalID", "missingOrigin", "mixedOrigin", "unknownField", "zero", "untrimmed"])
    func `malformed immutable payload fails closed`(fault: String) throws {
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: -1, ordinal: 1)
        let dto = try StockMovementDTO(movement)
        var fixture = StockMalformedWireFixture(
            payloadVersion: dto.payloadVersion,
            id: dto.id,
            productID: dto.productID,
            quantityDelta: dto.quantityDelta,
            reason: dto.reason,
            occurredAt: dto.occurredAt,
            origin: StockWireOriginFixture(kind: "manual", reference: movement.id.rawValue.uuidString)
        )
        switch fault {
        case "version": fixture.payloadVersion = 3
        case "noncanonicalID": fixture.id = "abcdefab-0000-0000-0000-000000000001"
        case "missingOrigin": fixture.origin = nil
        case "mixedOrigin": fixture.origin?.saleID = UUID().uuidString
        case "unknownField": fixture.isDeleted = true
        case "zero": fixture.quantityDelta = 0
        default: fixture.reason = " Needs trimming "
        }
        let bytes = try JSONEncoder().encode(fixture)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(StockMovementDTO.self, from: bytes) }
    }

    @Test(arguments: ["legacy", "revision", "sequence", "operation", "tombstone", "metadataField"])
    func `document never accepts legacy mutable or malformed metadata`(fault: String) throws {
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: 1, ordinal: 1)
        let record = try stockSyncTestRecord(movement, sequence: 1)
        var fixture = StockMalformedDocumentFixture(
            movement: record.movement,
            syncMetadata: StockWireMetadataFixture(
                revision: record.revision,
                operationID: record.operationID.uuidString,
                changeSequence: record.changeSequence
            )
        )
        switch fault {
        case "legacy": fixture.syncMetadata = nil
        case "revision": fixture.syncMetadata?.revision = 2
        case "sequence": fixture.syncMetadata?.changeSequence = 0
        case "operation": fixture.syncMetadata?.operationID = UUID().uuidString
        case "tombstone": fixture.isDeleted = true
        default: fixture.syncMetadata?.unexpected = true
        }
        let bytes = try JSONEncoder().encode(fixture)
        #expect(throws: (any Error).self) { try JSONDecoder().decode(FirestoreStockDocumentDTO.self, from: bytes) }
    }
}

private struct StockMalformedWireFixture: Codable {
    var payloadVersion: Int
    var id: String
    let productID: String
    var quantityDelta: Int64
    var reason: String
    let occurredAt: SaleTimestampDTO
    var origin: StockWireOriginFixture?
    var isDeleted: Bool? = nil

    private enum CodingKeys: String, CodingKey {
        case payloadVersion, id, productID, quantityDelta, reason, occurredAt, origin
        case isDeleted = "_deleted"
    }
}

private struct StockWireOriginFixture: Codable {
    let kind: String
    let reference: String
    var saleID: String? = nil
}

private struct StockMalformedDocumentFixture: Codable {
    let movement: StockMovementDTO
    var syncMetadata: StockWireMetadataFixture?
    var isDeleted: Bool? = nil

    private enum CodingKeys: String, CodingKey {
        case movement
        case syncMetadata = "_sync"
        case isDeleted = "_deleted"
    }
}

private struct StockWireMetadataFixture: Codable {
    var revision: Int64
    var operationID: String
    var changeSequence: Int64
    var unexpected: Bool? = nil
}
