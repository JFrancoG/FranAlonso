import Foundation

/// Exposes the local append-only stock ledger without activating a remote synchronization engine.
struct DefaultStockRepository: StockRepository {
    private let writer: StockPersistenceActor

    func append(_ movement: StockMovement) async throws -> StockMovement {
        try await writer.append(movement)
    }

    func movement(id: StockMovementID) async throws -> StockMovement? {
        try await writer.movement(id: id)
    }

    func quantity(for productID: ProductID) async throws -> Int {
        try await writer.quantity(for: productID)
    }
}

extension DefaultStockRepository {
    /// Retains the composition's shared writer so repeated callers serialize acceptance together.
    init(persistenceActor: StockPersistenceActor) {
        self.init(writer: persistenceActor)
    }
}
