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

    /// Reads a visible local profile by stable identity; missing and deactivated profiles return nil.
    /// - Throws: `ClientError` for a local failure or `CancellationError` before reading.
    func client(id: ClientID) async throws -> Client?

    /// Creates a draft and its pending operation locally. Existing identities are never overwritten.
    /// - Throws: `ClientError.alreadyExists` for any previously used identity, a local failure, or prior cancellation.
    func createClient(id: ClientID, profile: ClientProfile) async throws -> Client

    /// Replaces only editable fields, preserving the stored activation state and consent.
    /// Acceptance is local-first; this contract does not provide compare-and-swap between contexts.
    /// - Throws: `ClientError.notFound`, `.deactivated`, `.conflict`, a local failure, or prior cancellation.
    func updateClient(id: ClientID, profile: ClientProfile) async throws -> Client

    /// Hides a client using a durable tombstone while retaining its last profile and consent locally.
    /// Repeating deactivation is a no-op. A never-known identity throws `ClientError.notFound`.
    /// Successful completion means local acceptance, without waiting for remote convergence.
    func deactivateClient(_ id: ClientID) async throws
}
