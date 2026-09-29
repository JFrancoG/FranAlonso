import SwiftData

/// Accepts UI adjustments using the caller's ephemeral main-actor context and the shared local primitive.
@MainActor
struct StockContextualPersistenceAdapter {
    private let localDataSource: StockLocalDataSource
    private let observationSignal: ProductObservationSignal

    /// Acceptance does not suspend between identity checks and durable commit; retry preserves the original event.
    /// Invalidation follows acceptance and cannot turn a durable commit into cancellation or failure.
    func append(_ movement: StockMovement, in context: ModelContext) async throws -> StockMovement {
        let accepted = try localDataSource.append(movement, in: context)
        await observationSignal.publishChange()
        return accepted
    }
}

extension StockContextualPersistenceAdapter {
    /// Uses the feature's shared invalidation; the caller's context is never retained by this adapter.
    init(dataSource: StockLocalDataSource = StockLocalDataSource(), observationSignal: ProductObservationSignal) {
        self.init(localDataSource: dataSource, observationSignal: observationSignal)
    }
}
