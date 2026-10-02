import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Compensatory stock payload compatibility")
struct SaleStockReversalPayloadTests {
    @Test
    func `literal remote compensation retains exact origin and timestamp through persistence`() throws {
        let dto = try JSONDecoder().decode(StockMovementDTO.self, from: Data(saleReversalRemoteFixture.utf8))
        let value = try dto.toDomain()
        #expect(value.id.rawValue.uuidString == saleReversalLiteralID)
        #expect(value.quantityDelta == 2)
        #expect(value.occurredAt == saleReversalTestDate)
        #expect(try StockMovementDTO(value) == dto)
        let local = try StockMovementModel(value)
        #expect(local.payloadVersion == 3)
        #expect(try local.toDomain() == value)
        #expect(try JSONDecoder().decode(StockMovementDTO.self, from: JSONEncoder().encode(dto)) == dto)
    }

    @Test(arguments: ["version1", "future", "negative", "zero", "wrongID", "wrongOriginal", "lowercase", "extra"])
    func `remote compensation rejects unsupported or ambiguous payload`(fault: String) throws {
        var object = try #require(
            JSONSerialization.jsonObject(with: Data(saleReversalRemoteFixture.utf8)) as? [String: Any]
        )
        var origin = try #require(object["origin"] as? [String: Any])
        switch fault {
        case "version1": object["payloadVersion"] = 1
        case "future": object["payloadVersion"] = 3
        case "negative": object["quantityDelta"] = -2
        case "zero": object["quantityDelta"] = 0
        case "wrongID": object["id"] = "A2500000-0000-4000-8000-000000000001"
        case "wrongOriginal": origin["originalMovementID"] = saleReversalLiteralID
        case "lowercase": origin["reversalID"] = "f2500000-0000-4000-8000-000000000001"
        default: origin["unexpected"] = "extra"
        }
        object["origin"] = origin
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: (any Error).self) {
            try JSONDecoder().decode(StockMovementDTO.self, from: data)
        }
    }

    @Test(arguments: [1, 2, 4])
    func `compensation cannot masquerade as a historical local payload version`(version: Int) throws {
        let row = StockMovementModel(
            id: try #require(UUID(uuidString: saleReversalLiteralID)),
            productID: saleStockProductID(1).rawValue,
            payloadVersion: version,
            payloadData: Data(saleReversalLocalFixture.utf8),
            isPendingSync: true
        )
        #expect(throws: StockError.storageFailure) {
            try row.toDomain()
        }
    }

    @Test(arguments: [false, true])
    func `historical manual and consumption transports retain version one and reject version two`(sale: Bool) throws {
        let value: StockMovement
        if sale {
            value = try #require(SaleStockMovementPolicy()(
                sale: saleReversalClosedFixture(),
                paymentID: saleStockPaymentID
            ).first)
        } else {
            value = try stockTestMovement(productID: saleStockProductID(1), delta: 2, ordinal: 99)
        }
        let dto = try StockMovementDTO(value)
        #expect(dto.payloadVersion == 1)
        #expect(try StockMovementModel(value).payloadVersion == (sale ? 2 : 1))
        var object = try #require(JSONSerialization.jsonObject(with: JSONEncoder().encode(dto)) as? [String: Any])
        object["payloadVersion"] = 2
        let data = try JSONSerialization.data(withJSONObject: object)
        #expect(throws: StockSyncError.invalidPayload) {
            try JSONDecoder().decode(StockMovementDTO.self, from: data)
        }
    }

    @Test
    func `canonical local compensation decodes through the persisted contract`() throws {
        let payload = Data(saleReversalLocalFixture.utf8)
        let id = try #require(UUID(uuidString: saleReversalLiteralID))
        let row = StockMovementModel(
            id: id,
            productID: saleStockProductID(1).rawValue,
            payloadVersion: 3,
            payloadData: payload,
            isPendingSync: true
        )
        let movement = try row.toDomain()
        #expect(movement.quantityDelta == 2)
        #expect(movement.occurredAt == Date(timeIntervalSinceReferenceDate: 300.125))
        #expect(try JSONDecoder().decode(StockMovement.self, from: row.payloadData) == movement)
    }
}

let saleReversalLiteralID = "A8B4068F-36AA-8795-9669-3FAD6C9BF025"
let saleReversalRemoteFixture = """
{"payloadVersion":2,"id":"A8B4068F-36AA-8795-9669-3FAD6C9BF025",
"productID":"D2500000-0000-4000-8000-000000000001","quantityDelta":2,
"reason":"sale-reversal","occurredAt":"4072c20000000000",
"origin":{"kind":"saleReversal","saleID":"A2500000-0000-4000-8000-000000000001",
"lineID":"B2500000-0000-4000-8000-000000000001","paymentID":"C2500000-0000-4000-8000-000000000001",
"reversalID":"F2500000-0000-4000-8000-000000000001","originalMovementID":"C0969BE6-6A1B-8497-8388-E059E9006643"}}
"""
let saleReversalLocalFixture = """
{"id":{"rawValue":"A8B4068F-36AA-8795-9669-3FAD6C9BF025"},
"productID":{"rawValue":"D2500000-0000-4000-8000-000000000001"},
"quantityDelta":2,"reason":"sale-reversal","occurredAt":300.125,
"origin":{"saleReversal":{
"saleID":{"rawValue":"A2500000-0000-4000-8000-000000000001"},
"lineID":{"rawValue":"B2500000-0000-4000-8000-000000000001"},
"paymentID":{"rawValue":"C2500000-0000-4000-8000-000000000001"},
"reversalID":{"rawValue":"F2500000-0000-4000-8000-000000000001"},
"originalMovementID":{"rawValue":"C0969BE6-6A1B-8497-8388-E059E9006643"}}}}
"""
