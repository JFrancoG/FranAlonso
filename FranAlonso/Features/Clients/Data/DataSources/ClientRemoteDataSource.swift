/// Provider-neutral failures exposed by the Clients remote transport boundary.
enum ClientRemoteDataSourceError: Error, Equatable {
    /// The caller is not permitted to perform the requested remote operation.
    case permissionDenied

    /// A server-only operation could not reach the remote service.
    case unavailable

    /// The provider failed without a more specific stable transport meaning.
    case unexpected
}

/// Performs server-backed Clients transport operations without exposing provider SDK types.
protocol ClientRemoteDataSource: Sendable {
    /// Requests complete versioned Clients records from the server.
    ///
    /// - Returns: Provider-neutral records obtained without a cache fallback.
    /// - Throws: A stable transport error or a decoding error with its coding path.
    func fetchAll() async throws -> [ClientRemoteRecord]

    /// Applies one immutable Clients operation under its causal precondition.
    ///
    /// Offline queuing is not successful completion. The result is acknowledged only after
    /// the provider transaction commits or proves the exact operation already authoritative.
    ///
    /// - Parameter operation: The durable operation and remote base to evaluate.
    /// - Returns: The applied, idempotent or conflict outcome observed transactionally.
    /// - Throws: A stable transport, decoding or sync-metadata error.
    func upsert(
        _ operation: ClientPendingUpsert
    ) async throws -> ClientRemoteUpsertResult
}
