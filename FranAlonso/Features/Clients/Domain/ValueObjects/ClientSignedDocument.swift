import Foundation

/// A signed presentation and its definitive PDF bytes, retained together for future persistence and retry.
/// This envelope is not a cryptographic signature or evidence of legal validity.
struct ClientSignedDocument: Identifiable, Codable, Equatable {
    struct Fields: Codable, Equatable {
        let binding: ClientDocumentSignature
        let signedAt: Date
        let pdf: Data
    }

    private let stored: Fields
    var fields: Fields { stored }
    var id: UUID { stored.binding.snapshot.id }
}

extension ClientSignedDocument {
    /// Checks transport-level PDF framing, not its semantic contents. Only the renderer establishes those contents.
    init(_ fields: Fields) throws(ClientDocumentError) {
        let seconds = fields.signedAt.timeIntervalSince1970
        guard seconds.isFinite, (-62_135_596_800...253_402_300_799).contains(seconds) else {
            throw .invalidDate
        }
        guard fields.pdf.starts(with: Data("%PDF-".utf8)),
              String(decoding: fields.pdf.suffix(32), as: UTF8.self).contains("%%EOF")
        else { throw .invalidArtifact }
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
