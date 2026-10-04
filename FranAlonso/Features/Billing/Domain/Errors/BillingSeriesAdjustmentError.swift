/// Neutral failures for an explicit administrative change of a future billing sequence.
enum BillingSeriesAdjustmentError: Error, Equatable {
    case invalidRequest
    case permissionDenied
    case conflict
    case invalidResponse
    case unavailable
}
