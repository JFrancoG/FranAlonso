/// A neutral rejection at the local payment acceptance boundary.
enum SalePaymentError: Error, Equatable {
    case methodRequired
    case notFound
    case staleSale
    case conflict
    case deleted
    case persistenceUnavailable
}
