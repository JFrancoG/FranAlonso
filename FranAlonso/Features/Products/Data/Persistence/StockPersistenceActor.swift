import SwiftData

/// Serializes stock operations through one context with explicit saves and no automatic acceptance.
/// Composition shares one writer; independent writers or processes are outside this atomicity contract.
@ModelActor
actor StockPersistenceActor {
    private let dataSource = StockLocalDataSource()

    /// Commits or deduplicates an event without a suspension inside its acceptance boundary.
    func append(_ movement: StockMovement) throws -> StockMovement {
        modelContext.autosaveEnabled = false
        return try dataSource.append(movement, in: modelContext)
    }

    /// Returns detached accepted history by stable identity.
    func movement(id: StockMovementID) throws -> StockMovement? {
        modelContext.autosaveEnabled = false
        return try dataSource.movement(id: id, in: modelContext)
    }

    /// Returns a checked sum of accepted deltas for a present Product.
    func quantity(for productID: ProductID) throws -> Int {
        modelContext.autosaveEnabled = false
        return try dataSource.quantity(for: productID, in: modelContext)
    }
}
