import Foundation

struct Client: Identifiable, Codable, Equatable {
    let id: ClientID
    let displayName: String
}
