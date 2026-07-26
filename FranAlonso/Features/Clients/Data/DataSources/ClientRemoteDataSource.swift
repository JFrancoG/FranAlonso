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
    /// Requests the bootstrap or incremental Clients batch after a durable cursor.
    ///
    /// - Parameter cursor: Nil for the legacy-inclusive bootstrap, otherwise the last commit.
    /// - Returns: Provider-neutral records and their next durable cursor.
    /// - Throws: A stable transport error or a decoding error with its coding path.
    func fetchChanges(
        after cursor: ClientSyncCursor?
    ) async throws -> ClientRemoteChangeBatch

    /// Applies one immutable Clients upsert or deletion under its causal precondition.
    ///
    /// Offline queuing is not successful completion. The result is acknowledged only after
    /// the provider transaction commits or proves the exact operation already authoritative.
    ///
    /// - Parameter operation: The durable operation and remote base to evaluate.
    /// - Returns: The applied, idempotent or conflict outcome observed transactionally.
    /// - Throws: A stable transport, decoding or sync-metadata error.
    func apply(
        _ operation: ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult
}
