import Foundation

/// Accepts a closed snapshot or an exact reversal replay without altering captured commercial history.
struct SaleReversalAcceptancePolicy {
    /// Initial acceptance requires complete equality; replay permits the original closed copy or current voided copy.
    /// Payment, document, original closure, reversal identity and effective date must all agree.
    /// - Throws: Lifecycle errors, conflicting reversal metadata, or a stale snapshot rejection.
    func callAsFunction(
        expected: Sale,
        current: Sale,
        reversalID: SaleReversalID,
        voidedAt: Date
    ) throws -> Sale {
        var candidate = expected
        try candidate.void(reversalID: reversalID, voidedAt: voidedAt)
        switch current.status {
        case .closed:
            guard current == expected else { throw SaleReversalError.staleSale }
            return candidate
        case .voided:
            var replay = current
            try replay.void(reversalID: reversalID, voidedAt: voidedAt)
            guard candidate == replay else { throw SaleReversalError.staleSale }
            return replay
        case .draft, .inProgress, .awaitingPayment, .awaitingDocument:
            throw SaleReversalError.staleSale
        }
    }
}
