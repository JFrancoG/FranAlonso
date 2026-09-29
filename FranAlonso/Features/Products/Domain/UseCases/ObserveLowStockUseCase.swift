/// Observes the latest local quantity with a fixed caller-selected minimum.
///
/// Consecutive equal states are suppressed. Buffering keeps the newest state rather than an event history.
/// Cancelling iteration cancels the repository subscription; a terminal error requires a new observation.
struct ObserveLowStockUseCase {
    let repository: any StockRepository

    func callAsFunction(
        for productID: ProductID,
        minimum: StockMinimum
    ) async -> AsyncThrowingStream<LowStockState, any Error> {
        let pair = AsyncThrowingStream<LowStockState, any Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let continuation = pair.continuation
        guard !Task.isCancelled else {
            continuation.finish(throwing: CancellationError())
            return pair.stream
        }
        let quantities = await repository.observeQuantity(for: productID)
        let observationTask = Task {
            do {
                var previous: LowStockState?
                for try await quantity in quantities {
                    try Task.checkCancellation()
                    let state = LowStockState(productID: productID, quantity: quantity, minimum: minimum)
                    guard state != previous else { continue }
                    previous = state
                    continuation.yield(state)
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
}
