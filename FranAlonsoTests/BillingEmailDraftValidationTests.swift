import Foundation
import Testing
@testable import FranAlonso

@Suite("Validated ephemeral billing email drafts")
struct BillingEmailDraftValidationTests {
    @Test(arguments: [
        "", "missing-at.example.invalid", "@example.invalid", "synthetic@", "one@@example.invalid",
        "first@example.invalid,second@example.invalid", "first@example.invalid;second@example.invalid",
        "Synthetic <one@example.invalid>", "two words@example.invalid",
        "one@example.invalid\r\nBcc: two@example.invalid",
        "one@example.invalid\u{0000}", "one@example.invalid\n"
    ])
    func `recipient syntax cannot smuggle headers or additional mailboxes`(_ recipient: String) async throws {
        let final = try await BillingEmailDraftFixtures.finalDelivery()
        #expect(throws: BillingEmailError.invalidRecipient) {
            try EmailDraft.prepared(delivery: final, recipient: recipient, content: BillingEmailDraftFixtures.content)
        }
    }

    @Test
    func `surrounding mailbox spaces are normalized without changing the final attachment`() async throws {
        let final = try await BillingEmailDraftFixtures.finalDelivery()
        let draft = try EmailDraft.prepared(
            delivery: final,
            recipient: "  synthetic-recipient@example.invalid  ",
            content: BillingEmailDraftFixtures.content
        )
        #expect(draft.recipient == "synthetic-recipient@example.invalid")
        #expect(draft.pdf == final.pdf)
        #expect(draft.receipt == final.receipt)
    }

    @Test(arguments: [
        BillingEmailContent(subject: "", body: "Synthetic body."),
        BillingEmailContent(subject: " ", body: "Synthetic body."),
        BillingEmailContent(subject: "Document\r\nBcc: another", body: "Synthetic body."),
        BillingEmailContent(subject: String(repeating: "s", count: 1_025), body: "Synthetic body."),
        BillingEmailContent(subject: "Document", body: ""),
        BillingEmailContent(subject: "Document", body: " \n "),
        BillingEmailContent(subject: "Document", body: "Synthetic\u{0000}body."),
        BillingEmailContent(subject: "Document", body: String(repeating: "b", count: 65_537))
    ])
    func `content requires a bounded single-line subject and nonempty plain-text body`(
        _ content: BillingEmailContent
    ) async throws {
        let final = try await BillingEmailDraftFixtures.finalDelivery()
        #expect(throws: BillingEmailError.invalidContent) {
            try EmailDraft.prepared(delivery: final, recipient: BillingEmailDraftFixtures.recipient, content: content)
        }
    }

    @Test(arguments: BillingEmailDraftPayloadDamage.allCases)
    func `decoding cannot bypass final receipt or email input invariants`(
        _ damage: BillingEmailDraftPayloadDamage
    ) async throws {
        var payload = try BillingEmailDraftPayload.final(await BillingEmailDraftFixtures.finalDelivery())
        try damage.apply(to: &payload)
        let bytes = try JSONEncoder().encode(payload)
        #expect(throws: damage.expectedError) {
            try JSONDecoder().decode(EmailDraft.self, from: bytes)
        }
    }
}
