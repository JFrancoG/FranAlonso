import Foundation

/// Checks the current session and durable principal binding around all actor operations.
/// No live model or context crosses this boundary, and acknowledgements remain principal-scoped.
struct DefaultClientDocumentRepository: ClientDocumentRepository {
    let persistence: ClientDocumentPersistenceActor
    let access: ClientDocumentAccess
    let observationSignal: any ClientChangeSignaling
    var principalID: String { access.principalID }

    func saveDraft(_ draft: ClientDocumentDraft, operationID: UUID) async throws -> ClientDocumentDraft {
        let saved = try await authorized {
            try await persistence.saveDraft(draft, operationID: operationID)
        }
        await observationSignal.publishChange()
        try await access.validate()
        return saved
    }

    func draft(id: UUID) async throws -> ClientDocumentDraft? {
        try await authorized { try await persistence.draft(id: id) }
    }

    func drafts(clientID: ClientID) async throws -> [ClientDocumentDraft] {
        try await authorized { try await persistence.drafts(clientID: clientID) }
    }

    func accept(_ document: ClientSignedDocument, draftID: UUID, revision: Int) async throws -> ClientDocumentDelivery {
        let result = try await authorized {
            try await persistence.accept(document, draftID: draftID, revision: revision)
        }
        try validateReceipt(in: result)
        return result
    }

    func delivery(id: UUID) async throws -> ClientDocumentDelivery? {
        let result = try await authorized { try await persistence.delivery(id: id) }
        if let result {
            try validateReceipt(in: result)
        }
        return result
    }

    func deliveries(clientID: ClientID) async throws -> [ClientDocumentDelivery] {
        let results = try await authorized { try await persistence.deliveries(clientID: clientID) }
        for result in results {
            try validateReceipt(in: result)
        }
        return results
    }

    func discardDraft(id: UUID, revision: Int) async throws {
        try await authorized { try await persistence.discardDraft(id: id, revision: revision) }
    }

    func beginUpload(id: UUID, at date: Date) async throws -> ClientDocumentDelivery {
        let result = try await authorized { try await persistence.beginUpload(id: id, at: date) }
        try validateReceipt(in: result)
        return result
    }

    func completeUpload(
        id: UUID,
        receipt: ClientDocumentUploadReceipt,
        principalID: String
    ) async throws -> ClientDocumentUploadReceipt {
        try await authorized {
            guard principalID == self.principalID else { throw ClientDocumentStorageError.invalidReceipt }
            return try await persistence.completeUpload(id: id, receipt: receipt, principalID: principalID)
        }
    }

    func recordUploadFailure(id: UUID, attempt: Int, error: ClientDocumentStorageError) async throws {
        try await authorized { try await persistence.recordUploadFailure(id: id, attempt: attempt, error: error) }
    }

    private func authorized<Value: Sendable>(
        _ operation: @Sendable () async throws -> Value
    ) async throws -> Value {
        try await access.validate()
        let result = try await operation()
        try await access.validate()
        return result
    }

    private func validateReceipt(in delivery: ClientDocumentDelivery) throws {
        switch delivery.state {
        case .uploaded(let receipt), .conflict(.some(let receipt)):
            guard receipt.matches(documentID: delivery.id, principalID: principalID) else {
                throw ClientDocumentStorageError.invalidReceipt
            }
        case .pending, .failed, .conflict(nil):
            break
        }
    }
}
