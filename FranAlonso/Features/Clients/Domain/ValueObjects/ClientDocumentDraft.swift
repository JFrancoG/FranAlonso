import Foundation

/// Recoverable editing work, independent of an immutable document identity and its upload lifecycle.
struct ClientDocumentDraft: Identifiable, Codable, Equatable {
    struct Fields: Codable, Equatable {
        let id: UUID
        let clientID: ClientID
        let profile: ClientProfile
        let snapshot: ClientDocumentSnapshot?
        let binding: ClientDocumentSignature?
        let signedAt: Date?
        let revision: Int
    }

    private let stored: Fields
    var fields: Fields { stored }
    var id: UUID { stored.id }
}

extension ClientDocumentDraft {
    /// Rejects mismatched identities, stale ink and incomplete signature/date pairs, including when decoding.
    init(_ fields: Fields) throws {
        guard fields.revision >= 0 else { throw ClientDocumentPersistenceError.invalidDraft }
        if let snapshot = fields.snapshot {
            guard snapshot.fields.clientID == fields.clientID,
                  snapshot.fields.clientName == fields.profile.displayName
            else { throw ClientDocumentPersistenceError.invalidDraft }
        }
        if let binding = fields.binding, let signedAt = fields.signedAt {
            guard binding.snapshot == fields.snapshot else { throw ClientDocumentPersistenceError.invalidDraft }
            let seconds = signedAt.timeIntervalSince1970
            guard seconds.isFinite, (-62_135_596_800...253_402_300_799).contains(seconds) else {
                throw ClientDocumentPersistenceError.invalidDraft
            }
        } else if fields.binding != nil || fields.signedAt != nil {
            throw ClientDocumentPersistenceError.invalidDraft
        }
        self.init(stored: fields)
    }

    /// Retains ink only for an unchanged presentation. A changed signed presentation needs a new document ID.
    func revising(profile: ClientProfile, snapshot: ClientDocumentSnapshot?) throws -> Self {
        let preservesSignature = snapshot == fields.snapshot
        if let previous = fields.snapshot, let snapshot, !preservesSignature, previous.id == snapshot.id {
            throw ClientDocumentPersistenceError.documentConflict
        }
        return try Self(.init(
            id: id,
            clientID: fields.clientID,
            profile: profile,
            snapshot: snapshot,
            binding: preservesSignature ? fields.binding : nil,
            signedAt: preservesSignature ? fields.signedAt : nil,
            revision: fields.revision
        ))
    }

    /// Fixes the signing time before rendering, so recovery never needs to replace valid ink or its date.
    func signing(with signature: ClientSignature, at date: Date) throws -> Self {
        guard let snapshot = fields.snapshot else { throw ClientDocumentPersistenceError.invalidDraft }
        return try Self(.init(
            id: id,
            clientID: fields.clientID,
            profile: fields.profile,
            snapshot: snapshot,
            binding: ClientDocumentSignature(snapshot: snapshot, signature: signature),
            signedAt: date,
            revision: fields.revision
        ))
    }

    init(from decoder: any Decoder) throws {
        try self.init(decoder.singleValueContainer().decode(Fields.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stored)
    }
}

/// Stable local failures; none embeds client data, storage paths, documents or provider diagnostics.
enum ClientDocumentPersistenceError: Error, Equatable {
    case notFound
    case staleDraft
    case documentConflict
    case invalidDraft
    case alreadyAccepted
    case persistenceUnavailable
    case unsupportedPayloadVersion
    case invalidPayload
}
