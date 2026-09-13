import Foundation

/// Uploads only an already durable artifact, then saves its receipt before reporting completion.
/// Repeated calls retain the same document bytes and cannot activate a client or regenerate a PDF.
struct UploadConsentUseCase {
    let repository: any ClientDocumentRepository
    let storage: any ClientDocumentStorage
    let now: @Sendable () -> Date

    func callAsFunction(documentID: UUID) async throws -> ClientDocumentUploadReceipt {
        try Task.checkCancellation()
        let delivery = try await repository.beginUpload(id: documentID, at: now())
        try Task.checkCancellation()
        if case .uploaded(let receipt) = delivery.state {
            guard receipt.matches(documentID: documentID, principalID: repository.principalID) else {
                throw ClientDocumentStorageError.invalidReceipt
            }
            return receipt
        }

        let receipt: ClientDocumentUploadReceipt
        do {
            receipt = try await storage.upload(delivery.document, principalID: repository.principalID)
            try Task.checkCancellation()
            guard receipt.matches(documentID: documentID, principalID: repository.principalID) else {
                throw ClientDocumentStorageError.invalidReceipt
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            let failure = error as? ClientDocumentStorageError ?? .unavailable
            try await repository.recordUploadFailure(id: documentID, attempt: delivery.attemptCount, error: failure)
            throw failure
        }

        let completed = try await repository.completeUpload(
            id: documentID,
            receipt: receipt,
            principalID: repository.principalID
        )
        try Task.checkCancellation()
        return completed
    }
}
