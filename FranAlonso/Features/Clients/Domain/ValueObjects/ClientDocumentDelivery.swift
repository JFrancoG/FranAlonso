import Foundation

/// The locally durable result of delivering an immutable document. Pending also covers an interrupted attempt.
enum ClientDocumentUploadState: Codable, Equatable {
    case pending
    case failed(ClientDocumentStorageError)
    case uploaded(ClientDocumentUploadReceipt)
    case conflict(receipt: ClientDocumentUploadReceipt?)
}

/// Delivery metadata is mutable independently of the signed payload, which is retained exactly once.
struct ClientDocumentDelivery: Identifiable, Equatable {
    let document: ClientSignedDocument
    let state: ClientDocumentUploadState
    let attemptCount: Int
    let lastAttemptAt: Date?

    var id: UUID { document.id }
}
