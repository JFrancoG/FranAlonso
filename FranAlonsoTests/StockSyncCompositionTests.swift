import Foundation
import SwiftData
import Testing

@testable import FranAlonso

@Suite("Inactive Stock composition and paid ledger convergence")
@MainActor
struct StockSyncCompositionTests {
    @Test
    func `bootstrap constructs once in explicit environment without calling remote`() async throws {
        let container = try stockSyncTestContainer()
        let factory = StockSyncTestFactory()
        let runtime = AppRuntime(
            modelContainer: container,
            environment: .production,
            makeStockRemoteDataSource: factory.make
        )
        runtime.activateStockSync(firebaseIsConfigured: false)
        #expect(runtime.stockSyncEngine == nil)
        #expect(factory.environments.isEmpty)
        runtime.activateStockSync(firebaseIsConfigured: true)
        let first = try #require(runtime.stockSyncEngine)
        runtime.activateStockSync(firebaseIsConfigured: true)
        #expect(runtime.stockSyncEngine === first)
        #expect(factory.environments == [.production])
        #expect(await factory.remote.fetchCount == 0)
        #expect(await factory.remote.pushCount == 0)
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let movement = try stockTestMovement(productID: product.id, delta: -2, ordinal: 1)
        _ = try await runtime.stockRepository.append(movement)
        try await first.synchronize()
        #expect(try await runtime.stockRepository.quantity(for: product.id) == -2)
        #expect(await factory.remote.appliedIDs == [movement.id.rawValue])
    }

    @Test
    func `payment created ledger converges independently without recalculating Sale consumptions`() async throws {
        let container = try stockSyncTestContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        try SaleLocalDataSource().persistPendingUpsert(
            original,
            operationID: saleStockUUID(0x91, 1),
            in: ModelContext(container)
        )
        let context = container.mainContext
        let accepted = try atomicSourcePay(original, source: SaleLocalDataSource(), in: context)
        let bytes = try stockPayloads(in: context)
        let saleOperations = try SaleLocalDataSource().pendingOperations(in: context)
        let remote = StockSyncTestRemote()
        let writer = StockPersistenceActor(modelContainer: container)
        let engine = StockSyncEngine(
            persistenceActor: writer,
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal()
        )
        try await engine.synchronize()
        try await engine.synchronize()
        let verification = ModelContext(container)
        #expect(try stockPayloads(in: verification) == bytes)
        #expect(try verification.fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
        #expect(await remote.records.count == 3)
        #expect(try SaleLocalDataSource().sale(id: original.id, in: verification) == accepted)
        #expect(try SaleLocalDataSource().pendingOperations(in: verification) == saleOperations)
        #expect(try await writer.quantity(for: saleStockProductID(1)) == -5)
        #expect(try await writer.quantity(for: saleStockProductID(2)) == -4)
        #expect(try await writer.deliverablePendingMovements().isEmpty)
    }
}

@MainActor
private final class StockSyncTestFactory {
    let remote = StockSyncTestRemote()
    private(set) var environments: [FirestoreEnvironment] = []

    func make(_ environment: FirestoreEnvironment) -> any StockRemoteDataSource {
        environments.append(environment)
        return remote
    }
}
