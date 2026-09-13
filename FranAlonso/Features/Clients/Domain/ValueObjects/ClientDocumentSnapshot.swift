import Foundation

/// Immutable presentation identity and content. Equality includes every fact to which the ink is bound.
struct ClientDocumentSnapshot: Identifiable, Codable, Equatable {
    struct Fields: Codable, Equatable {
        let id: UUID
        let clientID: ClientID
        let clientName: String
        let context: ClientDocumentContext
        let content: ClientDocumentContent
    }

    private let stored: Fields
    var fields: Fields { stored }
    var id: UUID { stored.id }
}

extension ClientDocumentSnapshot {
    /// Validates photo/content correspondence and the independently retained later-authorization purpose.
    init(_ fields: Fields) throws(ClientDocumentError) {
        guard !fields.clientName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw .invalidContent
        }
        let hasPhotoSection = fields.content.fields.photoAuthorization != nil
        guard hasPhotoSection == (fields.context.variant == .informationWithPhoto),
              fields.context.purpose != .subsequentPhotoAuthorization || hasPhotoSection
        else { throw .invalidContext }
        self.init(stored: fields)
    }

    init(from decoder: any Decoder) throws {
        try self.init(decoder.singleValueContainer().decode(Fields.self))
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(stored)
    }
}

/// Ink captured for one exact snapshot. It cannot authorize a different presentation, even with the same ID.
struct ClientDocumentSignature: Codable, Equatable {
    private let storedSnapshot: ClientDocumentSnapshot
    private let storedSignature: ClientSignature
    var snapshot: ClientDocumentSnapshot { storedSnapshot }
    var signature: ClientSignature { storedSignature }

    private enum CodingKeys: String, CodingKey {
        case snapshot, signature
    }
}

extension ClientDocumentSignature {
    /// An undecided photo must first be authorized or removed from the presentation.
    init(snapshot: ClientDocumentSnapshot, signature: ClientSignature) throws(ClientDocumentError) {
        guard snapshot.fields.context.photoDecision != .undecided else { throw .photoDecisionRequired }
        self.init(storedSnapshot: snapshot, storedSignature: signature)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            snapshot: container.decode(ClientDocumentSnapshot.self, forKey: .snapshot),
            signature: container.decode(ClientSignature.self, forKey: .signature)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(snapshot, forKey: .snapshot)
        try container.encode(signature, forKey: .signature)
    }
}
