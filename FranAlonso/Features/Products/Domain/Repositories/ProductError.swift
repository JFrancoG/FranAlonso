/// Stable local product-operation failures, without provider details or business payloads.
enum ProductError: Error, Equatable {
    case invalidName
    case alreadyExists
    case notFound
    case deleted
    case conflict
    case persistenceUnavailable
}
