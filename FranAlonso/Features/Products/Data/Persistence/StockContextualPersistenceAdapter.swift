import SwiftData

/// Accepts UI adjustments using the caller's ephemeral main-actor context and the shared local primitive.
@MainActor
struct StockContextualPersistenceAdapter {
    private let localDataSource: StockLocalDataSource

    /// Acceptance does not suspend between identity checks and durable commit; retry preserves the original event.
    func append(_ movement: StockMovement, in context: ModelContext) async throws -> StockMovement {
        try localDataSource.append(movement, in: context)
    }
}

extension StockContextualPersistenceAdapter {
    init(dataSource: StockLocalDataSource = StockLocalDataSource()) {
        self.init(localDataSource: dataSource)
    }
}
