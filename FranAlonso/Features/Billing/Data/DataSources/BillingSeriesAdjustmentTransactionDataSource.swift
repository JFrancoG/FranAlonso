import Foundation

/// Malformed audit data blocks both overwrite and recovery.
enum BillingSeriesAdjustmentAuditState: Equatable {
    case absent
    case value(BillingSeriesAdjustmentAuditDTO)
    case malformed
}

/// Consistent reads of the immutable operation and the shared reservation counter, before writes.
struct BillingSeriesAdjustmentTransactionSnapshot {
    let audit: BillingSeriesAdjustmentAuditState
    let counter: BillingCounterState
}

/// A replay writes nothing; creation changes the future head and its audit atomically.
enum BillingSeriesAdjustmentTransactionPlan: Codable, Equatable {
    case replay(BillingSeriesAdjustmentAuditDTO)
    case create(BillingSeriesAdjustmentAuditDTO, BillingCounterDTO)
}

extension BillingSeriesAdjustmentTransactionPlan {
    /// Re-evaluates a pure compare-and-set decision on every transaction attempt.
    /// Existing acceptance is considered before the current counter, preserving recovery after later allocations.
    static func plan(
        for request: BillingSeriesAdjustmentRequestDTO,
        principalID: String,
        against snapshot: BillingSeriesAdjustmentTransactionSnapshot
    ) throws -> BillingSeriesAdjustmentTransactionPlan {
        let requested = try request.toDomain()
        try requireBillingSeriesAdministrationPrincipal(principalID)
        switch snapshot.audit {
        case let .value(audit):
            let acceptance = try audit.toDomain()
            guard acceptance.request == requested, acceptance.principalID == principalID else {
                throw BillingSeriesAdjustmentError.conflict
            }
            return .replay(audit)
        case .malformed:
            throw BillingSeriesAdjustmentError.invalidResponse
        case .absent:
            break
        }
        let current: Int64
        switch snapshot.counter {
        case .absent:
            current = 0
        case let .value(counter):
            guard counter.payloadVersion == 1, counter.series == requested.series, counter.lastNumber >= 0 else {
                throw BillingSeriesAdjustmentError.invalidResponse
            }
            current = counter.lastNumber
        case .malformed:
            throw BillingSeriesAdjustmentError.invalidResponse
        }
        guard current == requested.expectedLastNumber else { throw BillingSeriesAdjustmentError.conflict }
        return .create(
            BillingSeriesAdjustmentAuditDTO(
                payloadVersion: 1,
                request: request,
                principalID: principalID,
                adjustedAt: nil
            ),
            BillingCounterDTO(payloadVersion: 1, series: requested.series, lastNumber: requested.targetLastNumber)
        )
    }
}

/// Rejects malformed authority identities before any transaction can contact a remote provider.
func requireBillingSeriesAdministrationPrincipal(_ principalID: String) throws {
    guard BillingSeriesAdjustmentReceipt.acceptsPrincipal(principalID) else {
        throw BillingSeriesAdjustmentError.permissionDenied
    }
}

/// Atomic administrative seam, sharing the reservation counter namespace.
///
/// A create resolves adjustedAt from its committed server record. Failure or cancellation may follow a commit:
/// only an explicit identical request with currently valid authority can recover the acceptance.
protocol BillingSeriesAdjustmentTransactionDataSource: Sendable {
    func transact(
        request: BillingSeriesAdjustmentRequestDTO,
        principalID: String,
        plan: @escaping @Sendable (BillingSeriesAdjustmentTransactionSnapshot) throws -> BillingSeriesAdjustmentTransactionPlan
    ) async throws -> BillingSeriesAdjustmentAuditDTO
}
