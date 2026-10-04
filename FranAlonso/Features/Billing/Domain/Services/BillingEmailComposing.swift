import Foundation

/// Neutral manual-composition failures never include recipients, document contents or provider diagnostics.
enum BillingEmailError: Error, Equatable {
    case documentNotFound, documentNotFinal, invalidRecipient, invalidContent, invalidDraft
    case unauthorized, unavailable, busy
}

/// A person's Mail action; queued acknowledges the outbox, not delivery to the recipient.
enum EmailCompositionResult: String, Codable, Equatable {
    case cancelled, saved, queued, failed
}

/// Presents one editable native composition and returns its terminal human action without closing the sale.
/// Cancellation dismisses the owned interface; it cannot retract an already queued message.
@MainActor
protocol BillingEmailComposing {
    func compose(_ draft: EmailDraft) async throws -> EmailCompositionResult
}
