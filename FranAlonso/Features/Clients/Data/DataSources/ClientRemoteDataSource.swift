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
    /// Requests a Clients snapshot from the server without falling back to cached data.
    ///
    /// The returned values may include locally pending writes introduced by provider latency
    /// compensation. They are not revision or conflict authority until the synchronization
    /// policy adds the metadata required for those decisions.
    ///
    /// - Returns: Transport values obtained by the server-backed read.
    /// - Throws: `ClientRemoteDataSourceError` for stable transport failures or a
    ///   `DecodingError` that preserves the invalid payload's coding path.
    func fetchAll() async throws -> [ClientDTO]

    /// Upserts a client by stable identity and waits for remote acknowledgement.
    ///
    /// Offline queuing is not successful completion of this operation.
    ///
    /// - Parameter client: The transport value to create or replace remotely.
    /// - Throws: `ClientRemoteDataSourceError` when the remote service rejects or cannot
    ///   acknowledge the operation.
    func upsert(_ client: ClientDTO) async throws
}
