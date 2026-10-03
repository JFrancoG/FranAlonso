import Foundation

/// Counter corruption blocks new allocations without preventing recovery of a valid immutable document.
enum BillingCounterState: Equatable {
    case absent
    case value(BillingCounterDTO)
    case malformed
}

/// Consistent reads of both identities and the selected family's counter, before any write.
struct BillingTransactionSnapshot {
    let binding: BillingRequestBindingDTO?
    let document: BillingDocumentRecordDTO?
    let counter: BillingCounterState
}

/// A replay performs no writes; a create commits all three records together.
enum BillingTransactionPlan: Codable, Equatable {
    case replay(BillingDocumentRecordDTO)
    case create(BillingDocumentRecordDTO, BillingRequestBindingDTO, BillingCounterDTO)
}

extension BillingTransactionPlan {
    /// Re-evaluated for every SDK transaction attempt; never mutates caller state.
    ///
    /// Both identity keys must agree before a replay is accepted. Divergent ownership/content conflicts;
    /// orphaned records and invalid metadata fail closed. Only creation reads the counter's value:
    /// an absent counter starts at zero, while negative, malformed or exhausted values cannot allocate.
    static func plan(
        for request: BillingDocumentRequestDTO,
        against snapshot: BillingTransactionSnapshot
    ) throws -> BillingTransactionPlan {
        let requested = try request.toDomain()
        if let binding = snapshot.binding {
            guard binding.payloadVersion == 1, binding.requestID == request.id,
                  let documentID = UUID(uuidString: binding.documentID),
                  documentID.uuidString == binding.documentID else {
                throw BillingDocumentReservationError.invalidResponse
            }
            guard binding.documentID == request.documentID else { throw BillingDocumentReservationError.conflict }
            guard let record = snapshot.document else { throw BillingDocumentReservationError.invalidResponse }
            let existing = try record.toDomain()
            guard record.request.documentID == request.documentID,
                  record.request.id == request.id else {
                throw BillingDocumentReservationError.invalidResponse
            }
            guard existing.request == requested else { throw BillingDocumentReservationError.conflict }
            return .replay(record)
        }
        if let record = snapshot.document {
            _ = try record.toDomain()
            guard record.request.documentID == request.documentID else {
                throw BillingDocumentReservationError.invalidResponse
            }
            guard record.request.id != request.id else { throw BillingDocumentReservationError.invalidResponse }
            throw BillingDocumentReservationError.conflict
        }
        let current: Int64
        switch snapshot.counter {
        case .absent:
            current = 0
        case let .value(counter):
            guard counter.payloadVersion == 1, counter.series == requested.kind.series else {
                throw BillingDocumentReservationError.invalidResponse
            }
            current = counter.lastNumber
        case .malformed:
            throw BillingDocumentReservationError.invalidResponse
        }
        guard current >= 0, current < Int64.max, Int(exactly: current + 1) != nil else {
            throw BillingDocumentReservationError.invalidResponse
        }
        let next = current + 1
        return .create(
            BillingDocumentRecordDTO(
                payloadVersion: 1,
                request: request,
                series: requested.kind.series,
                number: next,
                issuedAt: nil
            ),
            BillingRequestBindingDTO(payloadVersion: 1, requestID: request.id, documentID: request.documentID),
            BillingCounterDTO(payloadVersion: 1, series: requested.kind.series, lastNumber: next)
        )
    }
}

/// Infrastructure seam for an atomic snapshot/plan/commit, independent of the SDK.
///
/// The implementation may re-evaluate plan on fresh snapshots under contention. A create resolves issuedAt
/// from the committed server record before returning. Failure or cancellation may follow a commit:
/// callers recover using the identical request, rather than allocating another identity.
protocol BillingTransactionDataSource: Sendable {
    func transact(
        request: BillingDocumentRequestDTO,
        plan: @escaping @Sendable (BillingTransactionSnapshot) throws -> BillingTransactionPlan
    ) async throws -> BillingDocumentRecordDTO
}
