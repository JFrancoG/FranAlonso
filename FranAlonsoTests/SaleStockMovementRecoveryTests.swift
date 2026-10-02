import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale stock cancellation and storage compatibility")
struct SaleStockMovementRecoveryTests {
    @Test
    @MainActor
    func `prior cancellation inserts no consumption`() async throws {
        let container = try saleStockContainer()
        let create = CreateSaleStockMovementsUseCase(repository: try saleStockRepository(in: container))
        let sale = try saleStockFixture()
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            return try await create(sale: sale, paymentID: saleStockPaymentID)
        }
        task.cancel()
        gate.continuation.finish()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    @Test
    @MainActor
    func `cancellation between lines retains accepted prefix and retry completes the sale`() async throws {
        let container = try saleStockContainer()
        let base = try saleStockRepository(in: container)
        let sale = try saleStockFixture()
        let task = saleStockCancellingTask(base: base, sale: sale, after: 2)
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        let before = try stockPayloads(in: ModelContext(container))
        #expect(before.count == 2)
        #expect(try await base.quantity(for: saleStockProductID(1)) == -5)
        #expect(try await base.quantity(for: saleStockProductID(2)) == 0)
        let create = CreateSaleStockMovementsUseCase(repository: base)
        #expect(try await create(sale: sale, paymentID: saleStockPaymentID).count == 3)
        let after = try stockPayloads(in: ModelContext(container))
        #expect(after.count == 3)
        #expect(before.allSatisfy { after[$0.key] == $0.value })
        #expect(try await base.quantity(for: saleStockProductID(2)) == -4)
    }

    @Test
    @MainActor
    func `cancellation after the final accepted line preserves successful result`() async throws {
        let container = try saleStockContainer()
        let base = try saleStockRepository(in: container)
        let task = saleStockCancellingTask(base: base, sale: try saleStockFixture(), after: 3)
        #expect(try await task.value.count == 3)
        #expect(task.isCancelled)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
        #expect(try await base.quantity(for: saleStockProductID(1)) == -5)
        #expect(try await base.quantity(for: saleStockProductID(2)) == -4)
    }

    @Test
    @MainActor
    func `professional services need no product and produce no stock records`() async throws {
        let container = try saleStockContainer()
        let repository = DefaultStockRepository(
            persistenceActor: StockPersistenceActor(modelContainer: container),
            observationSignal: ProductObservationSignal()
        )
        let create = CreateSaleStockMovementsUseCase(repository: repository)
        let sale = try saleStockFixture(professionalOnly: true)
        #expect(try await create(sale: sale, paymentID: saleStockPaymentID).isEmpty)
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
    }

    @Test
    @MainActor
    func `accepted replay remains valid after linked products disappear`() async throws {
        let container = try saleStockContainer()
        let repository = try saleStockRepository(in: container)
        let create = CreateSaleStockMovementsUseCase(repository: repository)
        let sale = try saleStockFixture()
        let accepted = try await create(sale: sale, paymentID: saleStockPaymentID)
        let before = try stockPayloads(in: ModelContext(container))
        let context = ModelContext(container)
        for product in try context.fetch(FetchDescriptor<ProductModel>()) {
            context.delete(product)
        }
        try context.save()
        #expect(try await create(sale: sale, paymentID: saleStockPaymentID) == accepted)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
        await #expect(throws: StockError.productNotFound) {
            try await repository.quantity(for: saleStockProductID(1))
        }
    }

    @Test
    @MainActor
    func `manual and sale version mismatches reject reads and retries without replacing bytes`() async throws {
        let sale = try saleStockFixture()
        let saleMovement = try #require(try SaleStockMovementPolicy()(sale: sale, paymentID: saleStockPaymentID).first)
        let manualID = StockMovementID(rawValue: saleStockUUID(0x92, 1))
        let manual = try StockMovement(
            id: manualID,
            productID: saleStockProductID(1),
            quantityDelta: 5,
            reason: "Physical count",
            occurredAt: Date(timeIntervalSinceReferenceDate: 50),
            origin: .manual(reference: manualID)
        )
        for (movement, incorrectVersion) in [(saleMovement, 1), (manual, 2), (saleMovement, 99)] {
            let container = try saleStockContainer()
            let repository = try saleStockRepository(in: container)
            let payload = try JSONEncoder().encode(movement)
            let context = ModelContext(container)
            context.insert(StockMovementModel(
                id: movement.id.rawValue,
                productID: movement.productID.rawValue,
                payloadVersion: incorrectVersion,
                payloadData: payload,
                isPendingSync: true
            ))
            try context.save()
            await #expect(throws: StockError.storageFailure) {
                try await repository.movement(id: movement.id)
            }
            await #expect(throws: StockError.storageFailure) {
                try await repository.quantity(for: movement.productID)
            }
            await #expect(throws: StockError.storageFailure) {
                try await repository.append(movement)
            }
            let rows = try ModelContext(container).fetch(FetchDescriptor<StockMovementModel>())
            let row = try #require(rows.count == 1 ? rows.first : nil)
            #expect(row.payloadData == payload)
            #expect(row.payloadVersion == incorrectVersion)
            #expect(row.isPendingSync)
        }
    }
}

@MainActor
private func saleStockCancellingTask(
    base: DefaultStockRepository,
    sale: Sale,
    after count: Int
) -> Task<[StockMovement], any Error> {
    let gate = AsyncStream<@Sendable () -> Void>.makeStream()
    let task = Task { @MainActor in
        var iterator = gate.stream.makeAsyncIterator()
        let cancel = try #require(await iterator.next())
        let repository = SaleStockInterruptionRepository(base: base) { acceptedCount in
            if acceptedCount == count {
                cancel()
            }
        }
        return try await CreateSaleStockMovementsUseCase(repository: repository)(
            sale: sale,
            paymentID: saleStockPaymentID
        )
    }
    gate.continuation.yield {
        task.cancel()
    }
    gate.continuation.finish()
    return task
}
