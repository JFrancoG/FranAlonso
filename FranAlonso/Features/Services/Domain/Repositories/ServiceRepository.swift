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

    /// Reads active and inactive snapshots; absent or deleted identities return nil.
    func service(id: ServiceID) async throws -> Service?

    /// Creates an active offering without overwriting any previously used identity.
    /// - Throws: `ServiceError` for local rejection, or cancellation before acceptance.
    func createService(id: ServiceID, profile: ServiceProfile) async throws -> Service

    /// Replaces the commercial profile while preserving the identity and current availability.
    /// Acceptance is local-first, without compare-and-swap across independent contexts.
    func updateService(id: ServiceID, profile: ServiceProfile) async throws -> Service

    /// Marks an offering inactive, retaining all commercial fields and references.
    /// Repetition is a no-op; absence, deletion and unresolved conflicts reject the mutation.
    func deactivateService(_ id: ServiceID) async throws
}
