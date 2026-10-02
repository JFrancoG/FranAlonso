import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Atomic sale reversal")
@MainActor
struct AtomicSaleReversalTests {
    @Test
    func `inactive catalogue and negative remaining balance do not suppress historical restitution`() throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let context = ModelContext(container)
        for row in try context.fetch(FetchDescriptor<ProductModel>()) {
            let product = try row.toDomain()
            context.delete(row)
            context.insert(ProductModel(Product(id: product.id, name: product.name, status: .inactive)))
        }
        context.insert(try StockMovementModel(stockTestMovement(
            productID: saleStockProductID(1),
            delta: -10,
            ordinal: 90
        )))
        try context.save()
        _ = try saleReversalSourceVoid(closed, in: context)
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == -10)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 7)
        #expect(try context.fetch(FetchDescriptor<ProductModel>()).allSatisfy { try $0.toDomain().status == .inactive })
    }

    @Test
    func `repository void restores repeated products once preserving originals and causal queue`() async throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let context = ModelContext(container)
        let before = try stockPayloads(in: context)
        let signal = AtomicPaymentProductProbe(container: container)
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal(),
            productObservationSignal: signal,
            operationID: { saleStockUUID(0x98, 1) }
        )
        let useCase = VoidSaleUseCase(repository: repository)
        let accepted = try await useCase(closed, reversalID: saleReversalTestID, voidedAt: saleReversalTestDate)
        #expect(accepted == (try saleReversalVoidedFixture(closed)))
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == 0)
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(2), in: context) == 0)
        let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
        #expect(rows.count == 6)
        #expect(rows.filter { $0.payloadVersion == 3 }.count == 3)
        let inverse = try rows.filter { $0.payloadVersion == 3 }.map { try $0.toDomain() }
        #expect(inverse.map(\.quantityDelta).sorted() == [2, 3, 4])
        #expect(inverse.allSatisfy { $0.occurredAt == saleReversalTestDate })
        #expect(inverse.contains { $0.id.rawValue.uuidString == saleReversalLiteralID })
        let bytes = try stockPayloads(in: context)
        #expect(before.allSatisfy { bytes[$0.key] == $0.value })
        let pending = try SaleLocalDataSource().pendingOperations(in: context)
        #expect(pending.map(\.operationID) == [saleStockUUID(0x98, 1)])
        #expect(try await useCase(closed, reversalID: saleReversalTestID, voidedAt: saleReversalTestDate) == accepted)
        #expect(try await useCase(accepted, reversalID: saleReversalTestID, voidedAt: saleReversalTestDate) == accepted)
        #expect(try stockPayloads(in: ModelContext(container)) == bytes)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)) == pending)
        #expect(await signal.snapshots.allSatisfy {
            $0 == AtomicPaymentSnapshot(sales: 1, operations: 1, movements: 6)
        })
    }

    @Test
    func `contextual commit failure rolls back sale queue and every compensation before retry`() async throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let context = container.mainContext
        let before = try stockPayloads(in: ModelContext(container))
        let signal = AtomicPaymentProductProbe(container: container)
        let source = saleReversalDataSource(save: { staged in
            #expect(!staged.autosaveEnabled)
            #expect(try staged.fetchCount(FetchDescriptor<StockMovementModel>()) == 6)
            #expect(try staged.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 1)
            #expect(try SaleLocalDataSource().sale(id: closed.id, in: staged) == saleReversalVoidedFixture(closed))
            #expect(try SaleLocalDataSource().sale(id: closed.id, in: ModelContext(container)) == closed)
            #expect(try stockPayloads(in: ModelContext(container)) == before)
            throw AtomicPaymentFailure.commit
        })
        let failing = SaleContextualPersistenceAdapter(
            dataSource: source,
            observationSignal: SaleObservationSignal(),
            productObservationSignal: signal,
            operationID: { saleStockUUID(0x98, 1) }
        )
        await #expect(throws: SaleReversalError.persistenceUnavailable) {
            try await failing.voidSale(
                closed,
                reversalID: saleReversalTestID,
                voidedAt: saleReversalTestDate,
                in: context
            )
        }
        #expect(!context.hasChanges)
        #expect(context.autosaveEnabled)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
        #expect(try SaleLocalDataSource().sale(id: closed.id, in: ModelContext(container)) == closed)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(await signal.snapshots.isEmpty)
        let adapter = SaleContextualPersistenceAdapter(
            observationSignal: SaleObservationSignal(),
            productObservationSignal: signal,
            operationID: { saleStockUUID(0x98, 1) }
        )
        _ = try await adapter.voidSale(
            closed,
            reversalID: saleReversalTestID,
            voidedAt: saleReversalTestDate,
            in: context
        )
        #expect(try stockPayloads(in: ModelContext(container)).count == 6)
        #expect(await signal.snapshots == [AtomicPaymentSnapshot(sales: 1, operations: 1, movements: 6)])
    }

    @Test(arguments: [false, true])
    func `history compensates with missing or conflicted Product without restoring metadata`(missing: Bool) throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let context = ModelContext(container)
        let product = try #require(try context.fetch(FetchDescriptor<ProductModel>()).first)
        if missing {
            context.delete(product)
            try context.save()
        } else {
            let snapshot = try product.toDomain()
            let source = ProductLocalDataSource()
            try source.persistPendingUpsert(snapshot, operationID: saleStockUUID(0x99, 1), in: context)
            let pending = try #require(try source.pendingUpserts(in: context).first)
            try source.recordConflict(operation: pending, reason: .baseChanged, remoteRecord: nil, in: context)
        }
        let productCount = try context.fetchCount(FetchDescriptor<ProductModel>())
        _ = try saleReversalSourceVoid(closed, in: context)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == productCount)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 6)
        #expect(try context.fetchCount(FetchDescriptor<ProductSyncConflictModel>()) == (missing ? 0 : 1))
    }

    @Test
    func `professional only void and exact replay need no stock or additional save`() throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture(professionalOnly: true)
        try SaleLocalDataSource().upsert(closed, in: ModelContext(container))
        let context = container.mainContext
        let accepted = try saleReversalSourceVoid(closed, in: context)
        let noSave = saleReversalDataSource(save: { _ in throw AtomicPaymentFailure.unexpectedSave })
        #expect(try saleReversalSourceVoid(closed, source: noSave, in: context) == accepted)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        #expect(try SaleLocalDataSource().pendingOperations(in: context).count == 1)
    }
}
