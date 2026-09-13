import Foundation
import SwiftData

/// A definitive signed envelope and its recoverable send state; the PDF is stored only inside documentPayload.
@Model
final class ClientSignedDocumentModel {
    @Attribute(.unique) var id: UUID
    var clientID: UUID
    var draftID: UUID
    var payloadVersion: Int
    var documentPayload: Data
    var statePayload: Data
    var attemptCount: Int
    var lastAttemptAt: Date?

    init(draftID: UUID, document: ClientSignedDocument) throws {
        id = document.id
        clientID = document.fields.binding.snapshot.fields.clientID.rawValue
        self.draftID = draftID
        payloadVersion = 1
        documentPayload = try JSONEncoder().encode(document)
        statePayload = try JSONEncoder().encode(ClientDocumentUploadState.pending)
        attemptCount = 0
        lastAttemptAt = nil
    }

    func toDomain() throws -> ClientDocumentDelivery {
        guard payloadVersion == 1 else { throw ClientDocumentPersistenceError.unsupportedPayloadVersion }
        let document = try JSONDecoder().decode(ClientSignedDocument.self, from: documentPayload)
        let state = try JSONDecoder().decode(ClientDocumentUploadState.self, from: statePayload)
        guard document.id == id, document.fields.binding.snapshot.fields.clientID.rawValue == clientID,
              attemptCount >= 0
        else { throw ClientDocumentPersistenceError.invalidPayload }
        return ClientDocumentDelivery(
            document: document,
            state: state,
            attemptCount: attemptCount,
            lastAttemptAt: lastAttemptAt
        )
    }

    func setState(_ state: ClientDocumentUploadState) throws {
        statePayload = try JSONEncoder().encode(state)
    }
}
