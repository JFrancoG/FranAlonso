import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Reversal cancellation and writer serialization", .timeLimit(.minutes(1)))
@MainActor
struct SaleReversalCancellationTests {
    @Test
    func `prior cancellation never reaches the sale or inventory commit`() async throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let before = try stockPayloads(in: ModelContext(container))
        let dependencies = AppDependencies.live(modelContainer: container)
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            return try await dependencies.voidSale(
                closed,
                reversalID: saleReversalTestID,
                voidedAt: saleReversalTestDate
            )
        }
        task.cancel()
        gate.continuation.finish()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try SaleLocalDataSource().sale(id: closed.id, in: ModelContext(container)) == closed)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
    }

    @Test
    func `cancellation during publication after commit returns the durable accepted reversal`() async throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let entered = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let signal = ReversalPublicationGate(entered: entered.continuation, release: release.stream)
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal(),
            productObservationSignal: signal
        )
        let task = Task {
            try await VoidSaleUseCase(repository: repository)(
                closed,
                reversalID: saleReversalTestID,
                voidedAt: saleReversalTestDate
            )
        }
        var iterator = entered.stream.makeAsyncIterator()
        #expect(await iterator.next() != nil)
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 6)
        #expect(try SaleLocalDataSource().pendingOperations(in: context).count == 1)
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == 0)
        task.cancel()
        release.continuation.finish()
        #expect(try await task.value == saleReversalVoidedFixture(closed))
        entered.continuation.finish()
    }

    @Test
    func `concurrent same reversal calls sharing the actor accept only one queue and inverse set`() async throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal()
        )
        let useCase = VoidSaleUseCase(repository: repository)
        async let first = useCase(closed, reversalID: saleReversalTestID, voidedAt: saleReversalTestDate)
        async let second = useCase(closed, reversalID: saleReversalTestID, voidedAt: saleReversalTestDate)
        let values = try await [first, second]
        #expect(values == Array(repeating: try saleReversalVoidedFixture(closed), count: 2))
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 6)
        #expect(try SaleLocalDataSource().pendingOperations(in: context).count == 1)
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == 0)
    }
}

private actor ReversalPublicationGate: ProductChangeSignaling {
    let entered: AsyncStream<Void>.Continuation
    let release: AsyncStream<Void>

    func publishChange() async {
        entered.yield()
        var iterator = release.makeAsyncIterator()
        _ = await iterator.next()
    }

    init(entered: AsyncStream<Void>.Continuation, release: AsyncStream<Void>) {
        self.entered = entered
        self.release = release
    }
}
