/// Stable failures of local client profile operations, without provider details or business payloads.
enum ClientError: Error, Equatable {
    case invalidDisplayName
    case alreadyExists
    case notFound
    case deactivated
    case conflict
    case persistenceUnavailable
}
