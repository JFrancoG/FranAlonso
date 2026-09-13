import Foundation

/// Resolved legal text shared by the native reader and PDF export, independent of the current catalog.
struct ClientDocumentContent: Codable, Equatable {
    struct Section: Codable, Equatable {
        let heading: String
        let body: String
    }

    struct Labels: Codable, Equatable {
        let clientName: String
        let clientID: String
        let documentID: String
        let version: String
        let language: String
        let date: String
        let signature: String
        let authorized: String
        let purpose: String
        let initialPurpose: String
        let subsequentPurpose: String
    }

    struct Fields: Codable, Equatable {
        let version: String
        let language: String
        let title: String
        let reviewNotice: String
        let sections: [Section]
        let photoAuthorization: String?
        let signatureNotice: String
        let labels: Labels
    }

    private let stored: Fields
    var fields: Fields { stored }
}

extension ClientDocumentContent {
    /// Rejects incomplete catalog resolutions before they can be shown or signed.
    init(_ fields: Fields) throws(ClientDocumentError) {
        let labels = fields.labels
        let required = [
            fields.version, fields.language, fields.title, fields.reviewNotice, fields.signatureNotice,
            labels.clientName, labels.clientID, labels.documentID, labels.version, labels.language,
            labels.date, labels.signature, labels.authorized, labels.purpose,
            labels.initialPurpose, labels.subsequentPurpose
        ] + fields.sections.map(\.body)
        guard !fields.sections.isEmpty,
              required.allSatisfy({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }),
              fields.photoAuthorization.map({ !$0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }) ?? true
        else { throw .invalidContent }
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

/// Failures of preparation, signature binding, or export; never carries client data.
enum ClientDocumentError: Error, Equatable {
    case invalidContent
    case unavailableCatalog
    case unsupportedLanguage
    case unsupportedVersion
    case invalidContext
    case photoDecisionRequired
    case staleSignature
    case invalidDate
    case invalidArtifact
    case renderingFailed
}
