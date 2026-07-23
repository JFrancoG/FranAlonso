/// Access to sale snapshots materialized by the local source of truth.
protocol SaleRepository: Sendable {
    /// Requests an observation stream backed by locally materialized sale snapshots.
    ///
    /// - Returns: A stream backed by locally materialized sale values.
    func observeSales() async -> AsyncThrowingStream<[Sale], any Error>

    /// Persists a sale through the local-first repository boundary.
    ///
    /// Successful completion means the local source accepted the snapshot;
    /// remote convergence may continue independently.
    ///
    /// - Parameter sale: The validated sale snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func saveSale(_ sale: Sale) async throws
}
