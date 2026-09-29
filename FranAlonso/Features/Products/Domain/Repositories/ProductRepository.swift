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

    /// Reads an active or inactive local product; absent and deleted identities return nil.
    func product(id: ProductID) async throws -> Product?

    /// Creates an active product locally; previously used identities are never overwritten.
    /// - Throws: `ProductError.alreadyExists`, a neutral local failure or prior cancellation.
    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product

    /// Replaces only editable metadata, preserving current identity and availability.
    /// Acceptance is local-first, without compare-and-swap across separate contexts.
    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product

    /// Marks a known product inactive, preserving its profile and references.
    /// Repeated deactivation is a no-op; missing, deleted or conflicted identities are rejected.
    func deactivateProduct(_ id: ProductID) async throws
}
