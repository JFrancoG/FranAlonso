/// Neutral adjustment failures without provider details or business payloads.
enum StockError: Error, Equatable {
    case invalidDelta
    case invalidReason
    case invalidDate
    case productNotFound
    case productConflict
    case identityConflict
    case quantityOverflow
    case storageFailure
}
