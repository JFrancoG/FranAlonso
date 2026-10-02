/// Neutral rejections of a local compensating void, without persistence or provider payloads.
enum SaleReversalError: Error, Equatable {
    case notFound
    case deleted
    case conflict
    case staleSale
    case stockIntegrity
    case persistenceUnavailable
}
