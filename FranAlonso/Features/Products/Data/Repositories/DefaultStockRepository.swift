import Foundation

/// Exposes the local append-only stock ledger without activating a remote synchronization engine.
struct DefaultStockRepository: StockRepository {
    private let writer: StockPersistenceActor
    private let observationSignal: ProductObservationSignal

    /// Reloads committed local state after feature invalidation and suppresses unchanged quantities.
    /// Registration precedes the initial read; newest-only buffering does not promise every intermediate balance.
    func observeQuantity(for productID: ProductID) async -> AsyncThrowingStream<Int, any Error> {
        guard !Task.isCancelled else {
            return AsyncThrowingStream {
                $0.finish(throwing: CancellationError())
            }
        }
        let changes = await observationSignal.stream()
        let pair = AsyncThrowingStream<Int, any Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let continuation = pair.continuation
        let observationTask = Task {
            do {
                var previous: Int?
                for await _ in changes {
                    try Task.checkCancellation()
                    let quantity = try await writer.quantity(for: productID)
                    try Task.checkCancellation()
                    guard quantity != previous else { continue }
                    previous = quantity
                    if case .terminated = continuation.yield(quantity) {
                        break
                    }
                }
                continuation.finish()
            } catch {
                continuation.finish(throwing: error)
            }
        }
        continuation.onTermination = { _ in
            observationTask.cancel()
        }
        if Task.isCancelled {
            observationTask.cancel()
        }
        return pair.stream
    }

    func append(_ movement: StockMovement) async throws -> StockMovement {
        let accepted = try await writer.append(movement)
        await observationSignal.publishChange()
        return accepted
    }

    func movement(id: StockMovementID) async throws -> StockMovement? {
        try await writer.movement(id: id)
    }

    func quantity(for productID: ProductID) async throws -> Int {
        try await writer.quantity(for: productID)
    }
}

extension DefaultStockRepository {
    /// Shares the writer and the same invalidation used by Product writes and contextual stock acceptance.
    init(persistenceActor: StockPersistenceActor, observationSignal: ProductObservationSignal) {
        self.init(writer: persistenceActor, observationSignal: observationSignal)
    }
}
