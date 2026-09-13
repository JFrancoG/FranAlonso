/// Creates immutable remote documents behind a provider-independent boundary.
///
/// The principal and document ID form one stable identity. Repeating that identity with the complete
/// same document returns its original receipt; any different snapshot, ink, date or PDF must conflict
/// without replacing the accepted document. Implementations must make comparison and creation atomic.
/// Cancellation or an unavailable response does not prove the remote document was never accepted.
protocol ClientDocumentStorage: Sendable {
    func upload(_ document: ClientSignedDocument, principalID: String) async throws -> ClientDocumentUploadReceipt
}

/// Neutral storage failures without provider details, credentials or document contents.
enum ClientDocumentStorageError: String, Error, Codable {
    case permissionDenied
    case unavailable
    case conflict
    case invalidReceipt
}
