import Foundation

struct Client: Identifiable, Codable, Equatable {
    let id: UUID
    let displayName: String
}
