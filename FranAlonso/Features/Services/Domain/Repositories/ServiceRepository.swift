/// Access to service snapshots materialized by the local source of truth.
protocol ServiceRepository: Sendable {
    /// Requests an observation stream backed by locally materialized service snapshots.
    ///
    /// - Returns: A stream backed by locally materialized service values.
    func observeServices() async -> AsyncThrowingStream<[Service], any Error>

    /// Persists a service through the local-first repository boundary.
    ///
    /// Successful completion means the local source accepted the snapshot;
    /// remote convergence may continue independently.
    ///
    /// - Parameter service: The validated service snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func saveService(_ service: Service) async throws
}
