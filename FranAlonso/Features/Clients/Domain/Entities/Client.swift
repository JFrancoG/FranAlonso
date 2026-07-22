import Foundation

struct Client: Identifiable, Codable, Equatable {
    let id: ClientID
    let displayName: String
    let taxIdentifier: String?
    let billingAddress: BillingAddress?
    let status: ClientStatus
}

extension Client {
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
