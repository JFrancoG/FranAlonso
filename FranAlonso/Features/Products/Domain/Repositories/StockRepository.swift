/// The append-only local stock boundary. A successful append returns the accepted movement, never a cached balance.
protocol StockRepository: Sendable {
    /// Same identity and canonical payload is a no-op; a different payload must preserve the original and fail.
    /// Cancellation before acceptance writes nothing; cancellation after commit does not revoke success.
    func append(_ movement: StockMovement) async throws -> StockMovement
    func movement(id: StockMovementID) async throws -> StockMovement?
    /// Derives the current quantity from accepted movements; no mutable total is stored on Product.
    func quantity(for productID: ProductID) async throws -> Int
}
