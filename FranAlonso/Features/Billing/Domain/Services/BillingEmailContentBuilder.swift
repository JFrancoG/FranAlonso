import Foundation

/// Already-resolved plain text for one confirmed billing document; no recipient is inferred from its sale.
struct BillingEmailContent: Codable, Equatable {
    let subject: String
    let body: String
}

/// Resolves the confirmed family and number into localized text without persistence or external effects.
protocol BillingEmailContentBuilder: Sendable {
    func content(for document: BillingDocument) -> BillingEmailContent
}
