/// Access to client snapshots materialized by the local source of truth.
protocol ClientRepository: Sendable {
    /// Requests an observation stream backed by locally materialized client snapshots.
    ///
    /// - Returns: A stream backed by locally materialized client values.
    func observeClients() async -> AsyncThrowingStream<[Client], any Error>

    /// Persists a client through the local-first repository boundary.
    ///
    /// Successful completion means the local source accepted the snapshot;
    /// remote convergence may continue independently.
    ///
    /// - Parameter client: The validated client snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func saveClient(_ client: Client) async throws
}
