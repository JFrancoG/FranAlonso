import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Atomic payment recovery", .timeLimit(.minutes(1)))
@MainActor
struct AtomicSalePaymentRecoveryTests {
    @Test
    func `commit failure restores sale queue and stock while preserving accepted prefixes`() async throws {
        for prefix in [false, true] {
            let container = try saleStockContainer()
            _ = try saleStockRepository(in: container)
            let original = try saleStockFixture(paid: false)
            let context = container.mainContext
            try SaleLocalDataSource().persistPendingUpsert(original, operationID: saleStockUUID(0x91, 1), in: context)
            if prefix {
                let movement = try #require(try SaleStockMovementPolicy()(
                    sale: saleStockFixture(),
                    paymentID: saleStockPaymentID
                ).first)
                _ = try StockLocalDataSource().append(movement, in: context)
            }
            let before = try stockPayloads(in: ModelContext(container))
            let operations = try SaleLocalDataSource().pendingOperations(in: ModelContext(container))
            let signal = AtomicPaymentProductProbe(container: container)
            let failing = SaleContextualPersistenceAdapter(
                dataSource: SaleLocalDataSource { staged in
                    #expect(!staged.autosaveEnabled)
                    #expect(try staged.fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
                    #expect(try staged.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 2)
                    #expect(try staged.fetch(FetchDescriptor<SaleModel>()).first?.toDomain().status
                        == .awaitingDocument(
                            paymentID: saleStockPaymentID,
                            method: .cash,
                            paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
                        ))
                    #expect(try SaleLocalDataSource().sale(id: original.id, in: ModelContext(container)) == original)
                    #expect(try stockPayloads(in: ModelContext(container)) == before)
                    throw AtomicPaymentFailure.commit
                },
                observationSignal: SaleObservationSignal(),
                productObservationSignal: signal,
                operationID: { saleStockUUID(0x91, 2) }
            )
            await #expect(throws: SalePaymentError.persistenceUnavailable) {
                try await atomicContextualPay(original, adapter: failing, in: context)
            }
            #expect(!context.hasChanges)
            #expect(context.autosaveEnabled)
            #expect(try SaleLocalDataSource().sale(id: original.id, in: ModelContext(container)) == original)
            #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)) == operations)
            #expect(try stockPayloads(in: ModelContext(container)) == before)
            #expect(await signal.snapshots.isEmpty)
            let adapter = SaleContextualPersistenceAdapter(
                observationSignal: SaleObservationSignal(),
                productObservationSignal: signal,
                operationID: { saleStockUUID(0x91, 2) }
            )
            _ = try await atomicContextualPay(original, adapter: adapter, in: context)
            #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
            #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).count == 2)
            #expect(await signal.snapshots == [AtomicPaymentSnapshot(sales: 1, operations: 2, movements: 3)])
        }
    }

    @Test
    func `historical paid closed and voided retries complete missing movements without rewriting bytes`() throws {
        for state in 0...2 {
            let container = try saleStockContainer()
            _ = try saleStockRepository(in: container)
            let expected = try saleStockFixture(paid: false)
            var current = try saleStockFixture()
            if state >= 1 {
                try current.close(
                    documentID: BillingDocumentID(rawValue: saleStockUUID(0xe9, 1)),
                    closedAt: Date(timeIntervalSinceReferenceDate: 200)
                )
            }
            if state == 2 {
                try current.void(
                    reversalID: SaleReversalID(rawValue: saleStockUUID(0xf9, 1)),
                    voidedAt: Date(timeIntervalSinceReferenceDate: 300)
                )
            }
            let context = ModelContext(container)
            let source = SaleLocalDataSource()
            try source.upsert(current, in: context)
            let payload = try #require(try context.fetch(FetchDescriptor<SaleModel>()).first).linesData
            let first = try #require(try SaleStockMovementPolicy()(sale: current, paymentID: saleStockPaymentID).first)
            _ = try StockLocalDataSource().append(first, in: context)
            let prefix = try stockPayloads(in: context)
            #expect(try atomicSourcePay(expected, source: source, in: context) == current)
            let rows = try ModelContext(container).fetch(FetchDescriptor<SaleModel>())
            #expect(rows.first?.linesData == payload)
            #expect(try source.pendingOperations(in: ModelContext(container)).isEmpty)
            let complete = try stockPayloads(in: ModelContext(container))
            #expect(complete.count == 3)
            #expect(prefix.allSatisfy { complete[$0.key] == $0.value })
            for product in try context.fetch(FetchDescriptor<ProductModel>()) {
                context.delete(product)
            }
            try context.save()
            let noSave = SaleLocalDataSource { _ in
                throw AtomicPaymentFailure.unexpectedSave
            }
            #expect(try atomicSourcePay(expected, source: noSave, in: context) == current)
            #expect(try stockPayloads(in: ModelContext(container)) == complete)
        }
    }

    @Test
    func `conflicting second line identity rejects payment and leaves the original ledger immutable`() throws {
        let container = try saleStockContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        let context = ModelContext(container)
        let source = SaleLocalDataSource()
        try source.upsert(original, in: context)
        let divergent = try SaleStockMovementPolicy()(
            sale: saleStockFixture(paymentID: PaymentID(rawValue: saleStockUUID(0xc2, 2))),
            paymentID: PaymentID(rawValue: saleStockUUID(0xc2, 2))
        )[1]
        _ = try StockLocalDataSource().append(divergent, in: context)
        let before = try stockPayloads(in: context)
        #expect(throws: SalePaymentError.persistenceUnavailable) {
            try atomicSourcePay(original, source: source, in: context)
        }
        #expect(!context.hasChanges)
        #expect(try source.sale(id: original.id, in: ModelContext(container)) == original)
        #expect(try source.pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
    }

    @Test
    func `missing or conflicted product and cumulative overflow preserve unpaid sale and pending history`() async throws {
        for failure in 0...2 {
            let container = try saleStockContainer()
            _ = try saleStockRepository(in: container)
            let original = try saleStockFixture(paid: false)
            let context = ModelContext(container)
            let source = SaleLocalDataSource()
            try source.upsert(original, in: context)
            if failure == 0 {
                let missing = try #require(try context.fetch(FetchDescriptor<ProductModel>()).first {
                    $0.id == saleStockProductID(2).rawValue
                })
                context.delete(missing)
                try context.save()
            } else if failure == 1 {
                let product = try #require(try ProductLocalDataSource().product(
                    id: saleStockProductID(2),
                    in: context
                ))
                try ProductLocalDataSource().persistPendingUpsert(
                    product,
                    operationID: saleStockUUID(0x91, 9),
                    in: context
                )
                let pending = try #require(try ProductLocalDataSource().pendingUpserts(in: context).first)
                try ProductLocalDataSource().recordConflict(
                    operation: pending,
                    reason: .baseChanged,
                    remoteRecord: nil,
                    in: context
                )
            } else {
                let id = StockMovementID(rawValue: saleStockUUID(0x91, 8))
                let prior = try StockMovement(
                    id: id,
                    productID: saleStockProductID(1),
                    quantityDelta: Int.min + 4,
                    reason: "Synthetic ledger",
                    occurredAt: Date(timeIntervalSinceReferenceDate: 50),
                    origin: .manual(reference: id)
                )
                _ = try StockLocalDataSource().append(prior, in: context)
            }
            let before = try stockPayloads(in: context)
            let signal = AtomicPaymentProductProbe(container: container)
            let repository = DefaultSaleRepository(
                persistenceActor: SalePersistenceActor(modelContainer: container),
                observationSignal: SaleObservationSignal(),
                productObservationSignal: signal
            )
            await #expect(throws: SalePaymentError.persistenceUnavailable) {
                try await RegisterSalePaymentUseCase(repository: repository)(
                    original,
                    id: saleStockPaymentID,
                    method: .cash,
                    paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
                )
            }
            #expect(try source.sale(id: original.id, in: ModelContext(container)) == original)
            #expect(try source.pendingOperations(in: ModelContext(container)).isEmpty)
            #expect(try stockPayloads(in: ModelContext(container)) == before)
            #expect(await signal.snapshots.isEmpty)
            if failure == 1 {
                #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductSyncConflictModel>()) == 1)
            }
        }
    }

    @Test
    func `dirty context preserves unrelated edits and never invokes payment commit`() throws {
        let container = try saleStockContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        let context = ModelContext(container)
        context.autosaveEnabled = false
        try SaleLocalDataSource().upsert(original, in: context)
        context.insert(ProductModel(Product(
            id: ProductID(rawValue: saleStockUUID(0xd2, 9)),
            name: "Unsaved edit",
            status: .active
        )))
        let source = SaleLocalDataSource { _ in
            throw AtomicPaymentFailure.unexpectedSave
        }
        #expect(throws: SalePaymentError.persistenceUnavailable) {
            try atomicSourcePay(original, source: source, in: context)
        }
        #expect(context.hasChanges)
        #expect(!context.autosaveEnabled)
        #expect(try context.fetchCount(FetchDescriptor<ProductModel>()) == 3)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == 2)
        #expect(try source.sale(id: original.id, in: ModelContext(container)) == original)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    func `cancellation thrown at commit rolls back all staged changes and restores autosave`() throws {
        let container = try saleStockContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        let context = container.mainContext
        try SaleLocalDataSource().upsert(original, in: context)
        let source = SaleLocalDataSource { staged in
            #expect(try staged.fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
            throw CancellationError()
        }
        #expect(throws: CancellationError.self) {
            try atomicSourcePay(original, source: source, in: context)
        }
        #expect(!context.hasChanges)
        #expect(context.autosaveEnabled)
        #expect(try source.sale(id: original.id, in: ModelContext(container)) == original)
        #expect(try source.pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    func `professional only payment needs no product rows and replay makes no save`() throws {
        let container = try saleStockContainer()
        let original = try saleStockFixture(paid: false, professionalOnly: true)
        let context = ModelContext(container)
        try SaleLocalDataSource().upsert(original, in: context)
        let accepted = try atomicSourcePay(original, source: SaleLocalDataSource(), in: context)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).count == 1)
        #expect(try atomicSourcePay(
            original,
            source: SaleLocalDataSource { _ in
                throw AtomicPaymentFailure.unexpectedSave
            },
            in: context
        ) == accepted)
    }
}

enum AtomicPaymentFailure: Error { case commit, unexpectedSave }

struct AtomicPaymentSnapshot: Equatable {
    let sales: Int
    let operations: Int
    let movements: Int
}

actor AtomicPaymentProductProbe: ProductChangeSignaling {
    let container: ModelContainer
    private(set) var snapshots: [AtomicPaymentSnapshot] = []

    func publishChange() {
        do {
            let context = ModelContext(container)
            snapshots.append(AtomicPaymentSnapshot(
                sales: try context.fetchCount(FetchDescriptor<SaleModel>()),
                operations: try context.fetchCount(FetchDescriptor<SalePendingUpsertModel>()),
                movements: try context.fetchCount(FetchDescriptor<StockMovementModel>())
            ))
        } catch {
            Issue.record(error)
        }
    }

    init(container: ModelContainer) {
        self.container = container
    }
}

func atomicSourcePay(_ sale: Sale, source: SaleLocalDataSource, in context: ModelContext) throws -> Sale {
    try source.registerPayment(
        sale,
        id: saleStockPaymentID,
        method: .cash,
        paidAt: Date(timeIntervalSinceReferenceDate: 100.125),
        operationID: saleStockUUID(0x91, 2),
        in: context
    )
}

@MainActor
func atomicContextualPay(
    _ sale: Sale,
    adapter: SaleContextualPersistenceAdapter,
    in context: ModelContext
) async throws -> Sale {
    try await adapter.registerPayment(
        sale,
        id: saleStockPaymentID,
        method: .cash,
        paidAt: Date(timeIntervalSinceReferenceDate: 100.125),
        in: context
    )
}
