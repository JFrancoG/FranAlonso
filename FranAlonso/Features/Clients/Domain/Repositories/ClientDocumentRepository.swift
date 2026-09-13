import Foundation

/// Authorized access to recoverable editing work, immutable artifacts and their local delivery state.
/// Implementations retain the complete accepted document before upload and never activate a client.
protocol ClientDocumentRepository: Sendable {
    var principalID: String { get }

    func saveDraft(_ draft: ClientDocumentDraft, operationID: UUID) async throws -> ClientDocumentDraft
    func draft(id: UUID) async throws -> ClientDocumentDraft?
    func drafts(clientID: ClientID) async throws -> [ClientDocumentDraft]
    func accept(_ document: ClientSignedDocument, draftID: UUID, revision: Int) async throws -> ClientDocumentDelivery
    func delivery(id: UUID) async throws -> ClientDocumentDelivery?
    func deliveries(clientID: ClientID) async throws -> [ClientDocumentDelivery]
    func discardDraft(id: UUID, revision: Int) async throws

    /// Records one attempt before any network operation; a completed receipt does not create another attempt.
    func beginUpload(id: UUID, at date: Date) async throws -> ClientDocumentDelivery

    /// Persists the correlated receipt before reporting success. A save failure retains recoverable pending work.
    func completeUpload(
        id: UUID,
        receipt: ClientDocumentUploadReceipt,
        principalID: String
    ) async throws -> ClientDocumentUploadReceipt

    /// Transient failures affect only their current attempt. A payload conflict from any attempt
    /// stops unconfirmed delivery; an existing durable receipt or terminal conflict remains intact.
    func recordUploadFailure(id: UUID, attempt: Int, error: ClientDocumentStorageError) async throws
}
