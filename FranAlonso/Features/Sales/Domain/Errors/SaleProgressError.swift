/// Neutral local rejection of an expected service-work transition.
enum SaleProgressError: Error, Equatable {
    case notFound, staleSale, conflict, deleted, persistenceUnavailable
}
