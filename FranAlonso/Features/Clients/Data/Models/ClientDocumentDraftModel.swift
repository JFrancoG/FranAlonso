import Foundation
import SwiftData

/// Versioned local editing envelope. Its revision is a compare-and-save token owned by the persistence actor.
@Model
final class ClientDocumentDraftModel {
    @Attribute(.unique) var id: UUID
    var clientID: UUID
    var revision: Int
    var payloadVersion: Int
    var payload: Data

    init(_ draft: ClientDocumentDraft) throws {
        id = draft.id
        clientID = draft.fields.clientID.rawValue
        revision = draft.fields.revision
        payloadVersion = 1
        payload = try JSONEncoder().encode(ClientDocumentDraftRecord(draft: draft, retiredDocumentIDs: []))
    }

    func toDomain() throws -> ClientDocumentDraft {
        try record().draft
    }

    private func record() throws -> ClientDocumentDraftRecord {
        guard payloadVersion == 1 else { throw ClientDocumentPersistenceError.unsupportedPayloadVersion }
        let record = try JSONDecoder().decode(ClientDocumentDraftRecord.self, from: payload)
        let draft = record.draft
        guard draft.id == id, draft.fields.clientID.rawValue == clientID, draft.fields.revision == revision else {
            throw ClientDocumentPersistenceError.invalidPayload
        }
        if let snapshotID = draft.fields.snapshot?.id, record.retiredDocumentIDs.contains(snapshotID) {
            throw ClientDocumentPersistenceError.invalidPayload
        }
        return record
    }

    func update(_ draft: ClientDocumentDraft) throws {
        guard draft.id == id, draft.fields.clientID.rawValue == clientID else {
            throw ClientDocumentPersistenceError.invalidPayload
        }
        let previous = try record()
        var retiredIDs = previous.retiredDocumentIDs
        if let previousSnapshot = previous.draft.fields.snapshot, previousSnapshot != draft.fields.snapshot {
            retiredIDs.insert(previousSnapshot.id)
        }
        if let snapshotID = draft.fields.snapshot?.id, retiredIDs.contains(snapshotID) {
            throw ClientDocumentPersistenceError.documentConflict
        }
        payload = try JSONEncoder().encode(ClientDocumentDraftRecord(draft: draft, retiredDocumentIDs: retiredIDs))
        revision = draft.fields.revision
    }
}

/// Keeps invalidated presentation identities durable even while the editable draft has no snapshot.
private struct ClientDocumentDraftRecord: Codable {
    let draft: ClientDocumentDraft
    let retiredDocumentIDs: Set<UUID>
}
