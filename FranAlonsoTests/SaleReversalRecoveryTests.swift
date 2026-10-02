import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale reversal fences and recovery")
@MainActor
struct SaleReversalRecoveryTests {
    @Test(arguments: ["missingSale", "tombstone", "conflict"])
    func `sale identity fences never restore a missing deleted or conflicted sale`(fence: String) throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let context = ModelContext(container)
        let source = SaleLocalDataSource()
        let error: SaleReversalError
        switch fence {
        case "missingSale":
            context.delete(try #require(try context.fetch(FetchDescriptor<SaleModel>()).first))
            error = .notFound
            try context.save()
        case "tombstone":
            context.insert(try SaleRemoteStateModel(record: SaleRemoteRecord(
                content: .tombstone(saleID: closed.id.rawValue),
                version: .versioned(revision: 1, lastOperationID: saleStockUUID(0x98, 5)),
                changeSequence: 1
            )))
            error = .deleted
            try context.save()
        default:
            try source.persistPendingUpsert(closed, operationID: saleStockUUID(0x98, 5), in: context)
            let operation = try #require(try source.pendingOperations(in: context).first)
            try source.recordConflict(
                operation: operation,
                reason: .baseChanged,
                remoteRecord: nil,
                in: context
            )
            error = .conflict
        }
        let before = try stockPayloads(in: ModelContext(container))
        let queue = try source.pendingOperations(in: context)
        #expect(throws: error) {
            try saleReversalSourceVoid(closed, in: context)
        }
        #expect(!context.hasChanges)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
        #expect(try source.pendingOperations(in: ModelContext(container)) == queue)
    }

    @Test(arguments: [
        "missing", "divergent", "corrupt", "originalConflict", "inverseConflict", "divergentInverse", "overflow"
    ])
    func `invalid stock history rejects the complete reversal`(fault: String) throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let context = ModelContext(container)
        let originals = try context.fetch(FetchDescriptor<StockMovementModel>())
        let row = try #require(originals.first)
        let movement = try row.toDomain()
        if fault == "missing" {
            context.delete(row)
        } else if fault == "divergent" || fault == "corrupt" {
            context.delete(row)
            let payload: Data
            if fault == "corrupt" {
                payload = Data("{}".utf8)
            } else {
                payload = try JSONEncoder().encode(StockMovement(
                    id: movement.id,
                    productID: movement.productID,
                    quantityDelta: -99,
                    reason: "sale-payment",
                    occurredAt: movement.occurredAt,
                    origin: movement.origin
                ))
            }
            context.insert(StockMovementModel(
                id: row.id,
                productID: row.productID,
                payloadVersion: 2,
                payloadData: payload,
                isPendingSync: true
            ))
        } else if fault == "divergentInverse" {
            let otherID = SaleReversalID(rawValue: saleStockUUID(0xf2, 2))
            let inverse = try SaleStockReversalPolicy()(
                sale: saleReversalVoidedFixture(closed, id: otherID),
                reversalID: otherID
            )
            context.insert(try StockMovementModel(try #require(inverse.first)))
        } else if fault == "overflow" {
            let manual = try stockTestMovement(productID: movement.productID, delta: Int.max, ordinal: 80)
            context.insert(try StockMovementModel(manual))
            context.insert(try StockMovementModel(stockTestMovement(
                productID: movement.productID,
                delta: 1,
                ordinal: 81
            )))
        } else {
            let id: UUID
            if fault == "originalConflict" {
                id = row.id
            } else {
                id = StockMovementID.saleReversal(
                    saleID: closed.id,
                    lineID: try #require(closed.lines.first).id
                ).rawValue
            }
            context.insert(StockSyncConflictModel(movementID: id, payloadVersion: 1, conflictData: Data()))
        }
        try context.save()
        let before = try stockPayloads(in: ModelContext(container))
        #expect(throws: SaleReversalError.stockIntegrity) {
            try saleReversalSourceVoid(closed, in: context)
        }
        #expect(!context.hasChanges)
        #expect(try SaleLocalDataSource().sale(id: closed.id, in: ModelContext(container)) == closed)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
    }

    @Test
    func `historical void replay repairs only missing inverses without rewriting queue or originals`() throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let voided = try saleReversalVoidedFixture(closed)
        let context = container.mainContext
        try SaleLocalDataSource().upsert(voided, in: context)
        let inverse = try SaleStockReversalPolicy()(sale: voided, reversalID: saleReversalTestID)
        context.insert(try StockMovementModel(try #require(inverse.first)))
        try context.save()
        let prefix = try stockPayloads(in: context)
        let pending = try SaleLocalDataSource().pendingOperations(in: context)
        #expect(try saleReversalSourceVoid(closed, in: context) == voided)
        let after = try stockPayloads(in: ModelContext(container))
        #expect(after.count == 6)
        #expect(prefix.allSatisfy { after[$0.key] == $0.value })
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)) == pending)
        #expect(try saleReversalSourceVoid(
            voided,
            source: saleReversalDataSource(save: { _ in throw AtomicPaymentFailure.unexpectedSave }),
            in: context
        ) == voided)
    }

    @Test
    func `dirty context and commit cancellation preserve prior durable state`() throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let context = container.mainContext
        let before = try stockPayloads(in: ModelContext(container))
        context.insert(ProductModel(Product(
            id: ProductID(rawValue: saleStockUUID(0xd2, 9)),
            name: "Unsaved",
            status: .active
        )))
        #expect(throws: SaleReversalError.persistenceUnavailable) {
            try saleReversalSourceVoid(closed, in: context)
        }
        #expect(context.hasChanges)
        #expect(try context.fetchCount(FetchDescriptor<ProductModel>()) == 3)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == 2)
        context.rollback()
        let cancelled = saleReversalDataSource(save: { staged in
            #expect(try staged.fetchCount(FetchDescriptor<StockMovementModel>()) == 6)
            throw CancellationError()
        })
        #expect(throws: CancellationError.self) {
            try saleReversalSourceVoid(closed, source: cancelled, in: context)
        }
        #expect(!context.hasChanges)
        #expect(context.autosaveEnabled)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
        #expect(try SaleLocalDataSource().sale(id: closed.id, in: ModelContext(container)) == closed)
    }

    @Test
    func `stale commercial closure and distinct reversal metadata never accept a second void`() throws {
        let closed = try saleReversalClosedFixture()
        let container = try stockSyncTestContainer()
        try seedSaleReversal(closed, in: container)
        let context = ModelContext(container)
        #expect(throws: SaleReversalError.staleSale) {
            try saleReversalSourceVoid(saleReversalClosedFixture(firstQuantity: 8), in: context)
        }
        let accepted = try saleReversalSourceVoid(closed, in: context)
        let before = try stockPayloads(in: context)
        #expect(throws: SaleError.conflictingReversal) {
            try SaleLocalDataSource().voidSale(
                closed,
                reversalID: SaleReversalID(rawValue: saleStockUUID(0xf2, 2)),
                voidedAt: saleReversalTestDate,
                operationID: saleStockUUID(0x98, 2),
                in: context
            )
        }
        #expect(throws: SaleError.conflictingReversal) {
            try SaleLocalDataSource().voidSale(
                closed,
                reversalID: saleReversalTestID,
                voidedAt: Date(timeIntervalSinceReferenceDate: 400),
                operationID: saleStockUUID(0x98, 2),
                in: context
            )
        }
        #expect(try SaleLocalDataSource().sale(id: closed.id, in: context) == accepted)
        #expect(try stockPayloads(in: context) == before)
    }
}
