import Foundation

/// An ephemeral manual-email snapshot bound to one final document, principal and canonical PDF receipt.
/// Codable preserves the validated value contract; drafts must never be persisted, logged or sent automatically.
struct EmailDraft: Identifiable, Codable, Equatable {
    private let contents: Contents

    var id: BillingDocumentID { document.id }
    var requestID: BillingDocumentRequestID { document.request.id }
    var document: BillingDocument { contents.document }
    var principalID: String { contents.principalID }
    var receipt: BillingPDFUploadReceipt { contents.receipt }
    var pdf: Data { contents.pdf }
    var recipient: String { contents.recipient }
    var subject: String { contents.content.subject }
    var body: String { contents.content.body }
    var fileName: String { "\(document.kind.rawValue)-\(id.rawValue.uuidString.lowercased()).pdf" }
    var mimeType: String { "application/pdf" }

    private enum CodingKeys: String, CodingKey {
        case contents
    }

    private struct Contents: Codable, Equatable {
        let document: BillingDocument
        let principalID: String
        let receipt: BillingPDFUploadReceipt
        let pdf: Data
        let recipient: String
        let content: BillingEmailContent
    }
}

extension EmailDraft {
    /// Requires a final retained delivery and an explicit single mailbox; it allocates and writes nothing.
    /// Subjects are limited to 1,024 UTF-8 bytes and bodies to 65,536; neither bound certifies deliverability.
    /// Basic mailbox checks reject empty sides, whitespace, controls and recipient-list delimiters, not all RFC syntax.
    static func prepared(
        delivery: BillingDocumentDelivery,
        recipient: String,
        content: BillingEmailContent
    ) throws -> EmailDraft {
        guard delivery.isFinal else { throw BillingEmailError.documentNotFinal }
        guard
            let document = delivery.document,
            let pdf = delivery.pdf,
            let receipt = delivery.receipt,
            delivery.uploadAttempts > 0,
            delivery.failure == nil,
            document.request == delivery.request
        else {
            throw BillingEmailError.invalidDraft
        }
        return try validated(contents: Contents(
            document: document,
            principalID: delivery.principalID,
            receipt: receipt,
            pdf: pdf,
            recipient: recipient,
            content: content
        ))
    }

    init(from decoder: any Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self = try Self.validated(contents: container.decode(Contents.self, forKey: .contents))
        } catch let error as BillingEmailError {
            throw error
        } catch {
            throw BillingEmailError.invalidDraft
        }
    }
}

private extension EmailDraft {
    private static func validated(contents: Contents) throws -> EmailDraft {
        guard
            !contents.principalID.isEmpty,
            !contents.pdf.isEmpty,
            contents.pdf.count <= 33_554_432,
            contents.receipt.matches(documentID: contents.document.id, principalID: contents.principalID)
        else {
            throw BillingEmailError.invalidDraft
        }
        let recipient = try singleMailbox(contents.recipient)
        try validate(content: contents.content)
        return EmailDraft(contents: Contents(
            document: contents.document,
            principalID: contents.principalID,
            receipt: contents.receipt,
            pdf: contents.pdf,
            recipient: recipient,
            content: contents.content
        ))
    }

    static func singleMailbox(_ input: String) throws -> String {
        guard !input.unicodeScalars.contains(where: { CharacterSet.controlCharacters.contains($0) }) else {
            throw BillingEmailError.invalidRecipient
        }
        let recipient = input.trimmingCharacters(in: .whitespaces)
        let parts = recipient.split(separator: "@", omittingEmptySubsequences: false)
        guard
            parts.count == 2,
            parts.allSatisfy({ !$0.isEmpty }),
            !recipient.unicodeScalars.contains(where: { CharacterSet.whitespacesAndNewlines.contains($0) }),
            !recipient.contains(where: { ",;<>\"".contains($0) })
        else {
            throw BillingEmailError.invalidRecipient
        }
        return recipient
    }

    static func validate(content: BillingEmailContent) throws {
        guard
            !content.subject.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            content.subject.utf8.count <= 1_024,
            !content.subject.unicodeScalars.contains(where: { isControl($0) || CharacterSet.newlines.contains($0) }),
            !content.body.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
            content.body.utf8.count <= 65_536,
            !content.body.unicodeScalars.contains(where: isForbiddenBodyControl)
        else {
            throw BillingEmailError.invalidContent
        }
    }

    static func isControl(_ scalar: Unicode.Scalar) -> Bool {
        scalar.value < 0x20 || (0x7F...0x9F).contains(scalar.value)
    }

    static func isForbiddenBodyControl(_ scalar: Unicode.Scalar) -> Bool {
        isControl(scalar) && !"\t\r\n".unicodeScalars.contains(scalar)
    }
}
