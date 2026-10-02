/// Provider-neutral failures exposed by the Stock remote transport boundary.
enum StockRemoteDataSourceError: Error, Equatable {
    /// The caller is not permitted to perform the requested remote operation.
    case permissionDenied

    /// A server-only operation could not reach the remote service.
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

extension StockRemoteDataSourceError {
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

/// Transfers immutable stock events independently of Products and Sales synchronization.
protocol StockRemoteDataSource: Sendable {
    /// Fetches a strict bootstrap or incremental feed; no legacy or deleted event is valid.
    func fetchChanges(after cursor: StockSyncCursor?) async throws -> StockRemoteChangeBatch

    /// Creates once or returns the authoritative equivalent/divergent full payload.
    func apply(_ movement: StockMovement) async throws -> StockRemoteMutationResult
}
