import SwiftData
import Testing
@testable import FranAlonso

@Suite("Stock runtime composition")
@MainActor
struct StockCompositionTests {
    @Test
    func `runtime stock callers share local acceptance without activating remote engines`() async throws {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let runtime = AppRuntime(modelContainer: container, environment: .develop)
        let first = AdjustStockUseCase(repository: runtime.stockRepository)
        let second = AdjustStockUseCase(repository: runtime.stockRepository)
        let movement = try stockTestMovement(productID: product.id, delta: 5, ordinal: 1)

        async let one = first(
            id: movement.id,
            productID: movement.productID,
            quantityDelta: movement.quantityDelta,
            reason: movement.reason,
            occurredAt: movement.occurredAt
        )
        async let two = second(
            id: movement.id,
            productID: movement.productID,
            quantityDelta: movement.quantityDelta,
            reason: movement.reason,
            occurredAt: movement.occurredAt
        )
        #expect(try await [one, two] == [movement, movement])
        #expect(try await runtime.stockRepository.quantity(for: product.id) == 5)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        #expect(runtime.clientSyncEngine == nil)
        #expect(runtime.productSyncEngine == nil)
        #expect(runtime.serviceSyncEngine == nil)
        #expect(runtime.saleSyncEngine == nil)
        #expect(runtime.authenticationRootViewModel == nil)
    }
}
