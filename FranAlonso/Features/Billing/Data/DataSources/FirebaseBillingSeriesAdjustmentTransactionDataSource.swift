import FirebaseFirestore
import Foundation

/// Explicit SDK injection remains inert until an authorized caller requests a transaction.
/// It shares the reservation counter path and never provisions or infers administrative privileges.
actor FirebaseBillingSeriesAdjustmentTransactionDataSource: BillingSeriesAdjustmentTransactionDataSource {
    private let firestoreProvider: @Sendable () -> Firestore
    private let environment: FirestoreEnvironment

    init(
        environment: FirestoreEnvironment,
        firestoreProvider: @escaping @Sendable () -> Firestore
    ) {
        self.firestoreProvider = firestoreProvider
        self.environment = environment
    }

    /// Reads both records before writes and resolves the authoritative audit time after acknowledgement.
    /// The repeatable callback returns fresh Codable bytes and never mutates application state.
    /// Cancellation or a failed server reread after commit does not undo the advance.
    func transact(
        request: BillingSeriesAdjustmentRequestDTO,
        principalID: String,
        plan: @escaping @Sendable (BillingSeriesAdjustmentTransactionSnapshot) throws -> BillingSeriesAdjustmentTransactionPlan
    ) async throws -> BillingSeriesAdjustmentAuditDTO {
        try Task.checkCancellation()
        do {
            _ = try request.toDomain()
            try requireBillingSeriesAdministrationPrincipal(principalID)
            let firestore = firestoreProvider()
            let paths = BillingSeriesAdjustmentFirestorePaths(environment: environment, request: request)
            let auditReference = firestore.document(paths.audit)
            let counterReference = firestore.document(paths.counter)
            let result = try await firestore.runTransaction { transaction, errorPointer -> sending Any? in
                do {
                    let auditSnapshot = try transaction.getDocument(auditReference)
                    let counterSnapshot = try transaction.getDocument(counterReference)
                    let audit: BillingSeriesAdjustmentAuditState
                    if auditSnapshot.exists {
                        do {
                            audit = .value(
                                try auditSnapshot.data(as: FirestoreBillingSeriesAdjustmentAuditDTO.self)
                                    .toAudit(operationID: auditSnapshot.documentID)
                            )
                        } catch is DecodingError {
                            audit = .malformed
                        } catch BillingSeriesAdjustmentError.invalidResponse {
                            audit = .malformed
                        }
                    } else {
                        audit = .absent
                    }
                    let counter: BillingCounterState
                    if counterSnapshot.exists {
                        do {
                            counter = .value(try counterSnapshot.data(as: BillingCounterDTO.self))
                        } catch is DecodingError {
                            counter = .malformed
                        }
                    } else {
                        counter = .absent
                    }
                    let outcome = try plan(BillingSeriesAdjustmentTransactionSnapshot(audit: audit, counter: counter))
                    let data = try JSONEncoder().encode(outcome)
                    if case let .create(pending, counter) = outcome {
                        try transaction.setData(
                            from: FirestoreBillingSeriesAdjustmentAuditDTO(pending),
                            forDocument: auditReference,
                            merge: false
                        )
                        try transaction.setData(from: counter, forDocument: counterReference, merge: false)
                    }
                    return data
                } catch {
                    errorPointer?.pointee = billingSeriesAdjustmentSDKError(error)
                    return nil
                }
            }
            try Task.checkCancellation()
            guard let data = result as? Data else { throw BillingSeriesAdjustmentError.invalidResponse }
            switch try JSONDecoder().decode(BillingSeriesAdjustmentTransactionPlan.self, from: data) {
            case let .replay(audit):
                return audit
            case let .create(expected, _):
                let snapshot = try await auditReference.getDocument(source: .server)
                try Task.checkCancellation()
                guard snapshot.exists, !snapshot.metadata.isFromCache, !snapshot.metadata.hasPendingWrites else {
                    throw BillingSeriesAdjustmentError.invalidResponse
                }
                let audit = try snapshot.data(as: FirestoreBillingSeriesAdjustmentAuditDTO.self)
                    .toAudit(operationID: snapshot.documentID)
                guard audit.payloadVersion == expected.payloadVersion,
                      audit.request == expected.request,
                      audit.principalID == expected.principalID else {
                    throw BillingSeriesAdjustmentError.invalidResponse
                }
                return audit
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            throw billingSeriesAdjustmentFirestoreError(error)
        }
    }
}

/// Only the Firestore encoder converts unresolved adjustedAt into a server transform.
struct FirestoreBillingSeriesAdjustmentAuditDTO: Codable {
    let payloadVersion: Int
    let request: BillingSeriesAdjustmentRequestDTO
    let principalID: String
    @ServerTimestamp var adjustedAt: Date?

    private enum CodingKeys: String, CodingKey, CaseIterable { case payloadVersion, request, principalID, adjustedAt }
}

extension FirestoreBillingSeriesAdjustmentAuditDTO {
    init(from decoder: any Decoder) throws {
        try requireBillingPayloadKeys(decoder, allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decode(Int.self, forKey: .payloadVersion),
            request: try container.decode(BillingSeriesAdjustmentRequestDTO.self, forKey: .request),
            principalID: try container.decode(String.self, forKey: .principalID),
            adjustedAt: try container.decode(ServerTimestamp<Date>.self, forKey: .adjustedAt).wrappedValue
        )
    }

    init(_ audit: BillingSeriesAdjustmentAuditDTO) {
        self.init(
            payloadVersion: audit.payloadVersion,
            request: audit.request,
            principalID: audit.principalID,
            adjustedAt: audit.adjustedAt?.date
        )
    }

    /// A path mismatch or unresolved/nonfinite time cannot masquerade as an acknowledged audit.
    func toAudit(operationID: String) throws -> BillingSeriesAdjustmentAuditDTO {
        guard operationID == request.id, let adjustedAt else { throw BillingSeriesAdjustmentError.invalidResponse }
        do {
            let audit = BillingSeriesAdjustmentAuditDTO(
                payloadVersion: payloadVersion,
                request: request,
                principalID: principalID,
                adjustedAt: try SaleTimestampDTO(adjustedAt)
            )
            _ = try audit.toDomain()
            return audit
        } catch {
            throw BillingSeriesAdjustmentError.invalidResponse
        }
    }
}

/// Administrative audits are separate immutable records; their counter namespace is shared with reservations.
struct BillingSeriesAdjustmentFirestorePaths {
    let environment: FirestoreEnvironment
    let request: BillingSeriesAdjustmentRequestDTO

    var audit: String { "\(environment.rawValue)/collections/billingSeriesAdjustments/\(request.id)" }
    var counter: String { "\(environment.rawValue)/collections/billingCounters/\(request.series.rawValue)" }
}

private let billingSeriesAdjustmentTransactionErrorDomain = "FranAlonso.BillingSeriesAdjustmentTransaction"

private func billingSeriesAdjustmentSDKError(_ error: any Error) -> NSError {
    guard let neutral = error as? BillingSeriesAdjustmentError else { return error as NSError }
    let code: Int
    switch neutral {
    case .unavailable: code = 1
    case .permissionDenied: code = 2
    case .conflict: code = 3
    case .invalidResponse: code = 4
    case .invalidRequest: code = 5
    }
    return NSError(domain: billingSeriesAdjustmentTransactionErrorDomain, code: code)
}

private func billingSeriesAdjustmentFirestoreError(_ error: any Error) -> any Error {
    if error is CancellationError {
        return CancellationError()
    }
    if let neutral = error as? BillingSeriesAdjustmentError {
        return neutral
    }
    if error is DecodingError || error is EncodingError {
        return BillingSeriesAdjustmentError.invalidResponse
    }
    let provider = error as NSError
    if provider.domain == billingSeriesAdjustmentTransactionErrorDomain {
        switch provider.code {
        case 1: return BillingSeriesAdjustmentError.unavailable
        case 2: return BillingSeriesAdjustmentError.permissionDenied
        case 3: return BillingSeriesAdjustmentError.conflict
        case 4: return BillingSeriesAdjustmentError.invalidResponse
        case 5: return BillingSeriesAdjustmentError.invalidRequest
        default: return BillingSeriesAdjustmentError.unavailable
        }
    }
    guard provider.domain == FirestoreErrorDomain else { return BillingSeriesAdjustmentError.unavailable }
    switch provider.code {
    case FirestoreErrorCode.permissionDenied.rawValue, FirestoreErrorCode.unauthenticated.rawValue:
        return BillingSeriesAdjustmentError.permissionDenied
    case FirestoreErrorCode.cancelled.rawValue:
        return CancellationError()
    case FirestoreErrorCode.invalidArgument.rawValue, FirestoreErrorCode.dataLoss.rawValue:
        return BillingSeriesAdjustmentError.invalidResponse
    default:
        return BillingSeriesAdjustmentError.unavailable
    }
}
