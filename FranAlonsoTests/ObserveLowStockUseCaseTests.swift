import Foundation
import Testing
@testable import FranAlonso

@Suite("Low stock observation")
struct ObserveLowStockUseCaseTests {
    @Test(arguments: [
        (4, 5, true),
        (5, 5, false),
        (6, 5, false),
        (0, 0, false),
        (-1, 0, true),
        (1, 0, false),
        (Int.min, Int.max, true),
        (Int.max, Int.max, false),
        (Int.max, 0, false)
    ])
    func `low stock excludes equality and supports zero negative and extreme quantities`(
        quantity: Int,
        minimum: Int,
        expectedLow: Bool
    ) throws {
        let state = LowStockState(
            productID: lowStockProductID(),
            quantity: quantity,
            minimum: try StockMinimum(minimum)
        )

        #expect(state.isLow == expectedLow)
    }

    @Test(arguments: [-1, Int.min])
    func `negative minima cannot be constructed or decoded`(_ minimum: Int) {
        #expect(throws: StockMinimum.ValidationError.invalidValue) {
            try StockMinimum(minimum)
        }
        #expect(throws: StockMinimum.ValidationError.invalidValue) {
            try JSONDecoder().decode(StockMinimum.self, from: Data(String(minimum).utf8))
        }
    }

    @Test
    func `decoding a stock state cannot bypass its minimum invariant`() throws {
        let payload = try JSONEncoder().encode(
            LowStockRawPayload(
                productID: lowStockProductID(),
                quantity: 3,
                minimum: -1,
                isLow: false
            )
        )

        #expect(throws: StockMinimum.ValidationError.invalidValue) {
            try JSONDecoder().decode(LowStockState.self, from: payload)
        }
    }

    @Test
    func `decoded low stock is derived instead of trusting a serialized flag`() throws {
        let payload = try JSONEncoder().encode(
            LowStockRawPayload(
                productID: lowStockProductID(),
                quantity: -3,
                minimum: 0,
                isLow: false
            )
        )

        let state = try JSONDecoder().decode(LowStockState.self, from: payload)

        #expect(state.isLow)
    }

    @Test
    func `quantity updates report low stock and recovery while retaining product identity`() async throws {
        let source = LowStockQuantitySource(productID: lowStockProductID(), initial: 8)
        defer { source.finish() }
        let stream = await ObserveLowStockUseCase(repository: source)(
            for: lowStockProductID(),
            minimum: try StockMinimum(5)
        )
        var observation = stream.makeAsyncIterator()
        let initial = try #require(try await observation.next())
        #expect(initial.quantity == 8)
        #expect(!initial.isLow)

        source.send(4)
        let low = try #require(try await observation.next())
        #expect(low.quantity == 4)
        #expect(low.isLow)
        #expect(low.id == initial.id)

        source.send(5)
        let equal = try #require(try await observation.next())
        #expect(equal.quantity == 5)
        #expect(!equal.isLow)

        source.send(7)
        let above = try #require(try await observation.next())
        #expect(above.quantity == 7)
        #expect(!above.isLow)

        source.send(-2)
        let negative = try #require(try await observation.next())
        #expect(negative.quantity == -2)
        #expect(negative.isLow)
        #expect(negative.id == lowStockProductID())
    }

    @Test
    func `a repeated quantity is suppressed even when it is the final upstream value`() async throws {
        let source = LowStockQuantitySource(productID: lowStockProductID(), initial: 3)
        defer { source.finish() }
        let stream = await ObserveLowStockUseCase(repository: source)(
            for: lowStockProductID(),
            minimum: try StockMinimum(5)
        )
        var observation = stream.makeAsyncIterator()
        _ = try #require(try await observation.next())

        source.send(3)
        source.finish()

        #expect(try await observation.next() == nil)
    }

    @Test
    func `a repository error terminates observation without fabricating recovery`() async throws {
        let source = LowStockQuantitySource(productID: lowStockProductID(), initial: 0)
        defer { source.finish() }
        let stream = await ObserveLowStockUseCase(repository: source)(
            for: lowStockProductID(),
            minimum: try StockMinimum(1)
        )
        var observation = stream.makeAsyncIterator()
        let initial = try #require(try await observation.next())
        #expect(initial.isLow)

        source.fail(.quantityOverflow)

        do {
            _ = try await observation.next()
            Issue.record("An upstream overflow unexpectedly produced another stock state")
        } catch {
            #expect(error as? StockError == .quantityOverflow)
        }
    }

    @Test
    func `cancelling a waiting consumer releases the upstream subscription`() async throws {
        let source = LowStockQuantitySource(productID: lowStockProductID(), initial: 0)
        defer { source.finish() }
        let stream = await ObserveLowStockUseCase(repository: source)(
            for: lowStockProductID(),
            minimum: try StockMinimum(1)
        )
        var observation = stream.makeAsyncIterator()
        _ = try #require(try await observation.next())
        let waiting = Task { try await observation.next() }

        waiting.cancel()

        switch await waiting.result {
        case .success(nil):
            break
        case .failure(let error):
            #expect(error is CancellationError)
        case .success(.some):
            Issue.record("Cancellation unexpectedly delivered another stock state")
        }
        var termination = source.termination.makeAsyncIterator()
        #expect(await termination.next() == true)
    }
}

private func lowStockProductID() -> ProductID {
    ProductID(rawValue: UUID(uuid: (0x59, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1)))
}

private struct LowStockRawPayload: Encodable {
    let productID: ProductID
    let quantity: Int
    let minimum: Int
    let isLow: Bool
}

private struct LowStockQuantitySource: StockRepository {
    let productID: ProductID
    let initial: Int
    let stream: AsyncThrowingStream<Int, any Error>
    let continuation: AsyncThrowingStream<Int, any Error>.Continuation
    let termination: AsyncStream<Bool>

    func append(_ movement: StockMovement) async throws -> StockMovement { throw StockError.storageFailure }
    func movement(id: StockMovementID) async throws -> StockMovement? { throw StockError.storageFailure }
    func quantity(for productID: ProductID) async throws -> Int { throw StockError.storageFailure }

    func observeQuantity(for productID: ProductID) async -> AsyncThrowingStream<Int, any Error> {
        guard productID == self.productID else {
            return AsyncThrowingStream {
                $0.finish(throwing: StockError.productNotFound)
            }
        }
        continuation.yield(initial)
        return stream
    }

    func send(_ quantity: Int) {
        continuation.yield(quantity)
    }

    func finish() {
        continuation.finish()
    }

    func fail(_ error: StockError) {
        continuation.finish(throwing: error)
    }
}

private extension LowStockQuantitySource {
    init(productID: ProductID, initial: Int) {
        let values = AsyncThrowingStream<Int, any Error>.makeStream()
        let termination = AsyncStream<Bool>.makeStream()
        values.continuation.onTermination = { reason in
            if case .cancelled = reason {
                termination.continuation.yield(true)
            } else {
                termination.continuation.yield(false)
            }
            termination.continuation.finish()
        }
        self.init(
            productID: productID,
            initial: initial,
            stream: values.stream,
            continuation: values.continuation,
            termination: termination.stream
        )
    }
}
