import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Atomic sale payment composition", .timeLimit(.minutes(1)))
@MainActor
struct AtomicSalePaymentCompositionTests {
    @Test
    func `runtime live and interactive preview payment invalidate the shared product catalogue`() async throws {
        for mode in 0...2 {
            let container = try saleStockContainer()
            _ = try saleStockRepository(in: container)
            let original = try saleStockFixture(paid: false)
            try SaleLocalDataSource().upsert(original, in: ModelContext(container))
            let dependencies: AppDependencies
            switch mode {
            case 0:
                dependencies = AppRuntime(modelContainer: container, environment: .develop).dependencies
            case 1:
                dependencies = AppDependencies.live(modelContainer: container)
            default:
                dependencies = AppDependencies.preview(modelContainer: container)
            }
            try await verifyAtomicPaymentCatalogue(dependencies, sale: original, in: container)
        }
    }

    @Test
    func `contextual commit publishes durable sale and stock to both existing observations`() async throws {
        let container = try saleStockContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        try SaleLocalDataSource().upsert(original, in: ModelContext(container))
        let products = ProductObservationSignal()
        let sales = SaleObservationSignal()
        let stock = DefaultStockRepository(
            persistenceActor: StockPersistenceActor(modelContainer: container),
            observationSignal: products
        )
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: sales,
            productObservationSignal: products
        )
        let stockStream = await stock.observeQuantity(for: saleStockProductID(1))
        let saleStream = await repository.observeSales()
        var stockIterator = stockStream.makeAsyncIterator()
        var saleIterator = saleStream.makeAsyncIterator()
        #expect(try await stockIterator.next() == 0)
        #expect(try await saleIterator.next() == [original])
        let adapter = SaleContextualPersistenceAdapter(observationSignal: sales, productObservationSignal: products)
        let accepted = try await atomicContextualPay(original, adapter: adapter, in: container.mainContext)
        #expect(try await stockIterator.next() == -5)
        #expect(try await saleIterator.next() == [accepted])
        let releaseStock = Task {
            for try await _ in stockStream {}
        }
        let releaseSales = Task {
            for try await _ in saleStream {}
        }
        releaseStock.cancel()
        releaseSales.cancel()
        _ = await releaseStock.result
        _ = await releaseSales.result
    }

    @Test
    func `cancellation while publishing after commit still returns complete accepted payment`() async throws {
        let container = try saleStockContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        try SaleLocalDataSource().upsert(original, in: ModelContext(container))
        let published = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let signal = AtomicPaymentPublicationGate(published: published.continuation, release: release.stream)
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal(),
            productObservationSignal: signal
        )
        let task = Task {
            try await RegisterSalePaymentUseCase(repository: repository)(
                original,
                id: saleStockPaymentID,
                method: .cash,
                paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
            )
        }
        var iterator = published.stream.makeAsyncIterator()
        #expect(await iterator.next() != nil)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).count == 1)
        task.cancel()
        release.continuation.finish()
        #expect(try await task.value == saleStockFixture())
        #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: ModelContext(container)) == -5)
        published.continuation.finish()
    }

    @Test
    func `prior cancelled payment reaches neither sale queue nor stock`() async throws {
        let container = try saleStockContainer()
        _ = try saleStockRepository(in: container)
        let original = try saleStockFixture(paid: false)
        try SaleLocalDataSource().upsert(original, in: ModelContext(container))
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: SaleObservationSignal()
        )
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            return try await RegisterSalePaymentUseCase(repository: repository)(
                original,
                id: saleStockPaymentID,
                method: .cash,
                paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
            )
        }
        task.cancel()
        gate.continuation.finish()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try SaleLocalDataSource().sale(id: original.id, in: ModelContext(container)) == original)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    }

    #if FRANALONSO_AUTH_FIXTURE
    @Test
    func `demo composition publishes payment stock through its shared catalogue`() async throws {
        let demo = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        _ = try saleStockRepository(in: demo.modelContainer)
        let sale = try saleStockFixture(paid: false)
        try SaleLocalDataSource().upsert(sale, in: ModelContext(demo.modelContainer))
        try await verifyAtomicPaymentCatalogue(demo.dependencies, sale: sale, in: demo.modelContainer)
    }
    #endif
}

@MainActor
private func verifyAtomicPaymentCatalogue(
    _ dependencies: AppDependencies,
    sale: Sale,
    in container: ModelContainer
) async throws {
    let catalogue = await dependencies.observeProducts()
    var iterator = catalogue.makeAsyncIterator()
    let initial = try #require(try await iterator.next())
    let accepted = try await dependencies.registerSalePayment(
        sale,
        id: saleStockPaymentID,
        method: .cash,
        paidAt: Date(timeIntervalSinceReferenceDate: 100.125)
    )
    #expect(try await iterator.next() == initial)
    #expect(try accepted == saleStockFixture())
    let context = ModelContext(container)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == -5)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(2), in: context) == -4)
    let consuming = Task {
        for try await _ in catalogue {}
    }
    consuming.cancel()
    _ = await consuming.result
}

private actor AtomicPaymentPublicationGate: ProductChangeSignaling {
    let published: AsyncStream<Void>.Continuation
    let release: AsyncStream<Void>

    func publishChange() async {
        published.yield()
        var iterator = release.makeAsyncIterator()
        _ = await iterator.next()
    }

    init(published: AsyncStream<Void>.Continuation, release: AsyncStream<Void>) {
        self.published = published
        self.release = release
    }
}
