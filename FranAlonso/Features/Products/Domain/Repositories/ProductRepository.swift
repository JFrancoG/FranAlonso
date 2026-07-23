/// Access to product snapshots materialized by the local source of truth.
protocol ProductRepository: Sendable {
    /// Requests an observation stream backed by locally materialized product snapshots.
    ///
    /// - Returns: A stream backed by locally materialized product values.
    func observeProducts() async -> AsyncThrowingStream<[Product], any Error>

    /// Persists a product through the local-first repository boundary.
    ///
    /// Successful completion means the local source accepted the snapshot;
    /// remote convergence may continue independently.
    ///
    /// - Parameter product: The validated product snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func saveProduct(_ product: Product) async throws
}
