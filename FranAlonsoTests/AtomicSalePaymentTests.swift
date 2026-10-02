import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Atomic local sale payment", .timeLimit(.minutes(1)))
@MainActor
struct AtomicSalePaymentTests {
    @Test
    func `repository payment commits captured consumptions and causal successor exactly once`() async throws {
        let container = try saleStockContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        let source = SaleLocalDataSource()
        try source.persistPendingUpsert(original, operationID: saleStockUUID(0x91, 1), in: ModelContext(container))
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal(),
            operationID: { saleStockUUID(0x91, 2) }
        )
        let useCase = RegisterSalePaymentUseCase(repository: repository)
        let accepted = try await useCase(
            original,
            id: saleStockPaymentID,
            method: .cash,
            paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
        )
        let context = ModelContext(container)
        let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
        #expect(rows.count == 3)
        let deltas = try rows.map {
            try $0.toDomain().quantityDelta
        }
        #expect(deltas.sorted() == [-4, -3, -2])
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == -5)
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(2), in: context) == -4)
        let before = try stockPayloads(in: context)
        let operations = try source.pendingOperations(in: context)
        #expect(operations.map(\.operationID) == [saleStockUUID(0x91, 1), saleStockUUID(0x91, 2)])
        #expect(operations.map(\.predecessorOperationID) == [nil, saleStockUUID(0x91, 1)])
        #expect(try await useCase(
            original,
            id: saleStockPaymentID,
            method: .cash,
            paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
        ) == accepted)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
        #expect(try source.pendingOperations(in: ModelContext(container)) == operations)
    }

    @Test
    func `concurrent commands sharing a sale writer create one complete payment and consumption set`() async throws {
        let container = try saleStockContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        try SaleLocalDataSource().upsert(original, in: ModelContext(container))
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal()
        )
        let useCase = RegisterSalePaymentUseCase(repository: repository)
        async let first = useCase(
            original,
            id: saleStockPaymentID,
            method: .cash,
            paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
        )
        async let second = useCase(
            original,
            id: saleStockPaymentID,
            method: .cash,
            paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
        )
        let accepted = try await [first, second]
        #expect(accepted[0] == accepted[1])
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
        #expect(try SaleLocalDataSource().pendingOperations(in: context).count == 1)
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == -5)
    }
}
