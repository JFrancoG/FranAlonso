import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Local stock observation", .timeLimit(.minutes(1)))
@MainActor
struct StockObservationTests {
    @Test
    func `repository publishes initial zero and accepted entries and withdrawals`() async throws {
        let setup = try StockObservationSetup.make()
        let stream = await setup.repository.observeQuantity(for: setup.product.id)
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == 0)
        let entry = try stockTestMovement(productID: setup.product.id, delta: 5, ordinal: 1)
        _ = try await setup.repository.append(entry)
        #expect(try await iterator.next() == 5)
        _ = try await setup.repository.append(stockTestMovement(productID: setup.product.id, delta: -7, ordinal: 2))
        #expect(try await iterator.next() == -2)
        await cancelStockObservation(stream)
    }

    @Test
    func `contextual writes and retries share the warmed observer without duplicate balances`() async throws {
        let setup = try StockObservationSetup.make()
        let stream = await setup.repository.observeQuantity(for: setup.product.id)
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == 0)
        let entry = try stockTestMovement(productID: setup.product.id, delta: 4, ordinal: 1)
        let adapter = StockContextualPersistenceAdapter(observationSignal: setup.signal)
        _ = try await adapter.append(entry, in: setup.container.mainContext)
        #expect(try await iterator.next() == 4)
        _ = try await adapter.append(entry, in: setup.container.mainContext)
        let products = ProductContextualPersistenceAdapter(observationSignal: setup.signal)
        _ = try await products.update(
            id: setup.product.id,
            profile: ProductProfile(name: "Renamed"),
            in: setup.container.mainContext
        )
        try await products.deactivate(setup.product.id, in: setup.container.mainContext)
        _ = try await adapter.append(
            stockTestMovement(productID: setup.product.id, delta: -6, ordinal: 2),
            in: setup.container.mainContext
        )
        #expect(try await iterator.next() == -2)
        #expect(try ModelContext(setup.container).fetchCount(FetchDescriptor<StockMovementModel>()) == 2)
        await cancelStockObservation(stream)
    }

    @Test
    func `missing product terminates with a neutral error rather than emitting zero`() async throws {
        let setup = try StockObservationSetup.make()
        let absentID = ProductID(rawValue: UUID())
        let stream = await setup.repository.observeQuantity(for: absentID)
        var iterator = stream.makeAsyncIterator()
        do {
            _ = try await iterator.next()
            Issue.record("An absent product unexpectedly produced a balance")
        } catch {
            #expect(error as? StockError == .productNotFound)
        }
    }

    @Test
    func `a tombstone from another known context invalidates a warmed stock reader`() async throws {
        let setup = try StockObservationSetup.make()
        let stream = await setup.repository.observeQuantity(for: setup.product.id)
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == 0)
        let context = ModelContext(setup.container)
        context.insert(try ProductPendingDeleteModel(
            productID: setup.product.id.rawValue,
            operationID: UUID(),
            predecessorOperationID: nil,
            base: .absent
        ))
        try context.save()
        await setup.signal.publishChange()
        do {
            _ = try await iterator.next()
            Issue.record("An absent product unexpectedly produced a balance")
        } catch {
            #expect(error as? StockError == .productNotFound)
        }
    }

    @Test
    func `delayed invalidation reloads the latest committed balance`() async throws {
        let setup = try StockObservationSetup.make()
        let stream = await setup.repository.observeQuantity(for: setup.product.id)
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == 0)
        let context = ModelContext(setup.container)
        let source = StockLocalDataSource()
        _ = try source.append(stockTestMovement(productID: setup.product.id, delta: 8, ordinal: 1), in: context)
        _ = try source.append(stockTestMovement(productID: setup.product.id, delta: -11, ordinal: 2), in: context)
        await setup.signal.publishChange()
        #expect(try await iterator.next() == -3)
        await cancelStockObservation(stream)
    }

    @Test
    func `failed contextual commit preserves the observed balance until a successful adjustment`() async throws {
        let setup = try StockObservationSetup.make()
        let stream = await setup.repository.observeQuantity(for: setup.product.id)
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == 0)
        let context = setup.container.mainContext
        let failing = StockContextualPersistenceAdapter(
            dataSource: StockLocalDataSource { _ in throw StockObservationFailure.commit },
            observationSignal: setup.signal
        )
        await #expect(throws: StockError.storageFailure) {
            try await failing.append(stockTestMovement(productID: setup.product.id, delta: 9, ordinal: 1), in: context)
        }
        _ = try await setup.repository.append(stockTestMovement(productID: setup.product.id, delta: 2, ordinal: 2))
        #expect(try await iterator.next() == 2)
        #expect(try ModelContext(setup.container).fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        await cancelStockObservation(stream)
    }

    @Test
    func `cancellation after contextual commit still publishes the accepted balance`() async throws {
        let setup = try StockObservationSetup.make()
        let stream = await setup.repository.observeQuantity(for: setup.product.id)
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == 0)
        let movement = try stockTestMovement(productID: setup.product.id, delta: 6, ordinal: 1)
        let gate = AsyncStream<@Sendable () -> Void>.makeStream()
        let accepting = Task { @MainActor in
            var gateIterator = gate.stream.makeAsyncIterator()
            let cancel = try #require(await gateIterator.next())
            let adapter = StockContextualPersistenceAdapter(
                dataSource: StockLocalDataSource { context in
                    try context.save()
                    cancel()
                },
                observationSignal: setup.signal
            )
            return try await adapter.append(movement, in: setup.container.mainContext)
        }
        gate.continuation.yield { accepting.cancel() }
        gate.continuation.finish()
        #expect(try await accepting.value == movement)
        #expect(accepting.isCancelled)
        #expect(try await iterator.next() == 6)
        await cancelStockObservation(stream)
    }

    @Test
    func `conflicted metadata remains readable while a corrupt movement terminates observation`() async throws {
        let setup = try StockObservationSetup.make()
        let context = ModelContext(setup.container)
        context.insert(try ProductSyncConflictModel(
            operation: ProductPendingUpsert(
                productID: setup.product.id.rawValue,
                operationID: UUID(),
                predecessorOperationID: nil,
                base: .absent,
                product: ProductDTO(setup.product)
            ),
            reason: .baseChanged,
            remoteRecord: nil
        ))
        try context.save()
        let stream = await setup.repository.observeQuantity(for: setup.product.id)
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == 0)
        context.insert(StockMovementModel(
            id: UUID(),
            productID: setup.product.id.rawValue,
            payloadVersion: 1,
            payloadData: Data("corrupt".utf8),
            isPendingSync: true
        ))
        try context.save()
        await setup.signal.publishChange()
        do {
            _ = try await iterator.next()
            Issue.record("Corrupt history unexpectedly produced a quantity")
        } catch {
            #expect(error as? StockError == .storageFailure)
        }
    }

    @Test
    func `multiple product observers retain independent quantities`() async throws {
        let setup = try StockObservationSetup.make()
        let second = Product(id: ProductID(rawValue: UUID()), name: "Second", status: .inactive)
        try seedStockTestProduct(second, in: setup.container)
        let firstStream = await setup.repository.observeQuantity(for: setup.product.id)
        let secondStream = await setup.repository.observeQuantity(for: second.id)
        var first = firstStream.makeAsyncIterator()
        var other = secondStream.makeAsyncIterator()
        #expect(try await first.next() == 0)
        #expect(try await other.next() == 0)
        _ = try await setup.repository.append(stockTestMovement(productID: setup.product.id, delta: 3, ordinal: 1))
        _ = try await setup.repository.append(stockTestMovement(productID: second.id, delta: -2, ordinal: 2))
        #expect(try await first.next() == 3)
        #expect(try await other.next() == -2)
        await cancelStockObservation(firstStream)
        await cancelStockObservation(secondStream)
    }

    @Test
    func `cancelling one consumer releases its pending iteration and preserves another observer`() async throws {
        let setup = try StockObservationSetup.make()
        let cancelledStream = await setup.repository.observeQuantity(for: setup.product.id)
        var first = cancelledStream.makeAsyncIterator()
        #expect(try await first.next() == 0)
        await cancelStockObservation(cancelledStream)
        let survivingStream = await setup.repository.observeQuantity(for: setup.product.id)
        var surviving = survivingStream.makeAsyncIterator()
        #expect(try await surviving.next() == 0)
        _ = try await setup.repository.append(stockTestMovement(productID: setup.product.id, delta: 1, ordinal: 1))
        #expect(try await surviving.next() == 1)
        #expect(try await first.next() == nil)
        await cancelStockObservation(survivingStream)
    }
}

@MainActor
private struct StockObservationSetup {
    let container: ModelContainer
    let product: Product
    let signal: ProductObservationSignal
    let repository: DefaultStockRepository

    static func make() throws -> StockObservationSetup {
        let container = try stockTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let signal = ProductObservationSignal()
        return StockObservationSetup(
            container: container,
            product: product,
            signal: signal,
            repository: DefaultStockRepository(
                persistenceActor: StockPersistenceActor(modelContainer: container),
                observationSignal: signal
            )
        )
    }
}

private func cancelStockObservation(_ stream: AsyncThrowingStream<Int, any Error>) async {
    let consuming = Task {
        for try await _ in stream {}
    }
    consuming.cancel()
    _ = await consuming.result
}

private enum StockObservationFailure: Error {
    case commit
}
