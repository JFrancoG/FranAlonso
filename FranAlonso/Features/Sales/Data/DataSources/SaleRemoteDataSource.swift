/// Provider-neutral failures exposed by the Sales remote transport boundary.
enum SaleRemoteDataSourceError: Error, Equatable {
    /// The caller is not permitted to perform the requested remote operation.
    case permissionDenied

    /// A server-only operation could not reach the remote sale.
    case unavailable

    /// The provider did not complete the operation before its deadline.
    case deadlineExceeded

    /// Contention aborted an idempotent operation after provider retries were exhausted.
    case aborted

    /// Provider quota or capacity rejected the operation without a safe retry distinction.
    case resourceExhausted

    /// The provider failed without a more specific stable transport meaning.
    case unexpected
}

extension SaleRemoteDataSourceError {
    /// Maps this transport failure to the shared retry decision without erasing its feature meaning.
    var syncClassification: SyncErrorClassification {
        switch self {
        case .unavailable:
            .recoverable(.unavailable)
        case .deadlineExceeded:
            .recoverable(.deadlineExceeded)
        case .aborted:
            .recoverable(.aborted)
        case .permissionDenied, .resourceExhausted, .unexpected:
            .definitive
        }
    }
}

/// Performs server-backed Sales transport operations without exposing provider SDK types.
protocol SaleRemoteDataSource: Sendable {
    /// Requests the bootstrap or incremental Sales batch after a durable cursor.
    ///
    /// - Parameter cursor: Nil for the legacy-inclusive bootstrap, otherwise the last commit.
    /// - Returns: Provider-neutral records and their next durable cursor.
    /// - Throws: A stable transport error or a decoding error with its coding path.
    func fetchChanges(
        after cursor: SaleSyncCursor?
    ) async throws -> SaleRemoteChangeBatch

    /// Applies one immutable Sales upsert or draft discard under its causal precondition.
    ///
    /// Offline queuing is not successful completion. The result is acknowledged only after
    /// the provider transaction commits or proves the exact operation already authoritative.
    ///
    /// - Parameter operation: The durable operation and remote base to evaluate.
    /// - Returns: The applied, idempotent or conflict outcome observed transactionally.
    /// - Throws: A stable transport, decoding or sync-metadata error.
    func apply(
        _ operation: SalePendingOperation
    ) async throws -> SaleRemoteMutationResult
}
