import Foundation

/// A client profile whose operational availability is governed by consent-backed activation.
struct Client: Identifiable, Codable, Equatable {
    let id: ClientID
    let displayName: String
    let taxIdentifier: String?
    let billingAddress: BillingAddress?
    let status: ClientStatus
}

extension Client {
    /// Creates the initial locally editable client profile.
    ///
    /// The returned client has no tax identifier or billing address and remains
    /// unavailable for business operations until consent-backed activation.
    ///
    /// - Returns: A client in the `ClientStatus.draft` state.
    static func draft(id: ClientID, displayName: String) -> Client {
        Client(
            id: id,
            displayName: displayName,
            taxIdentifier: nil,
            billingAddress: nil,
            status: .draft
        )
    }
}
