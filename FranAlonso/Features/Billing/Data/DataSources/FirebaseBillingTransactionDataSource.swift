import FirebaseFirestore
import Foundation

/// Explicitly injected Firestore authority. Construction performs no I/O and does not activate Billing.
///
/// The Sendable provider retrieves an already configured SDK-managed client for each explicit operation.
/// It must preserve project/database configuration and never mutate settings or terminate an active client.
/// The client may be cached by Firebase: no fresh-instance ownership is promised. No SDK client is retained
/// as actor state or used again after the async transaction; only SDK-declared Sendable references remain.
actor FirebaseBillingTransactionDataSource: BillingTransactionDataSource {
    private let firestoreProvider: @Sendable () -> Firestore
    private let environment: FirestoreEnvironment

    init(
        environment: FirestoreEnvironment,
        firestoreProvider: @escaping @Sendable () -> Firestore
    ) {
        self.firestoreProvider = firestoreProvider
        self.environment = environment
    }

    /// Commits all three records in one SDK transaction, then resolves the server timestamp after acknowledgement.
    ///
    /// The synchronous SDK block can run repeatedly and has no application side effects. Its dynamic result
    /// is fresh Codable Data, never a Transaction, Firestore instance, dictionary or unresolved timestamp.
    /// A failed server read or cooperative cancellation after commit does not undo the reservation.
    func transact(
        request: BillingDocumentRequestDTO,
        plan: @escaping @Sendable (BillingTransactionSnapshot) throws -> BillingTransactionPlan
    ) async throws -> BillingDocumentRecordDTO {
        try Task.checkCancellation()
        do {
            _ = try request.toDomain()
            let firestore = firestoreProvider()
            let paths = BillingFirestorePaths(environment: environment, request: request)
            let bindingReference = firestore.document(paths.binding)
            let documentReference = firestore.document(paths.document)
            let counterReference = firestore.document(paths.counter)
            let result = try await firestore.runTransaction { transaction, errorPointer -> sending Any? in
                do {
                    let bindingSnapshot = try transaction.getDocument(bindingReference)
                    let documentSnapshot = try transaction.getDocument(documentReference)
                    let counterSnapshot = try transaction.getDocument(counterReference)
                    let binding = bindingSnapshot.exists
                        ? try bindingSnapshot.data(as: BillingRequestBindingDTO.self) : nil
                    let document = documentSnapshot.exists
                        ? try documentSnapshot.data(as: FirestoreBillingDocumentDTO.self)
                            .toRecord(documentID: documentSnapshot.documentID) : nil
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
                    let outcome = try plan(
                        BillingTransactionSnapshot(binding: binding, document: document, counter: counter)
                    )
                    let data = try JSONEncoder().encode(outcome)
                    if case let .create(record, binding, counter) = outcome {
                        try transaction.setData(
                            from: FirestoreBillingDocumentDTO(record),
                            forDocument: documentReference,
                            merge: false
                        )
                        try transaction.setData(from: binding, forDocument: bindingReference, merge: false)
                        try transaction.setData(from: counter, forDocument: counterReference, merge: false)
                    }
                    return data
                } catch {
                    errorPointer?.pointee = billingSDKError(error)
                    return nil
                }
            }
            try Task.checkCancellation()
            guard let data = result as? Data else { throw BillingDocumentReservationError.invalidResponse }
            switch try JSONDecoder().decode(BillingTransactionPlan.self, from: data) {
            case let .replay(record):
                return record
            case let .create(expected, _, _):
                let snapshot = try await documentReference.getDocument(source: .server)
                try Task.checkCancellation()
                guard snapshot.exists, !snapshot.metadata.isFromCache, !snapshot.metadata.hasPendingWrites else {
                    throw BillingDocumentReservationError.invalidResponse
                }
                let record = try snapshot.data(as: FirestoreBillingDocumentDTO.self)
                    .toRecord(documentID: snapshot.documentID)
                guard record.payloadVersion == expected.payloadVersion,
                      record.request == expected.request,
                      record.series == expected.series,
                      record.number == expected.number else {
                    throw BillingDocumentReservationError.invalidResponse
                }
                return record
            }
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            try Task.checkCancellation()
            throw billingFirestoreError(error)
        }
    }
}

/// SDK-specific envelope; nil issuedAt is encoded exclusively by Firestore as a server transform.
struct FirestoreBillingDocumentDTO: Codable {
    let payloadVersion: Int
    let request: BillingDocumentRequestDTO
    let series: BillingDocumentSeries
    let number: Int64
    @ServerTimestamp var issuedAt: Date?

    private enum CodingKeys: String, CodingKey, CaseIterable { case payloadVersion, request, series, number, issuedAt }
}

extension FirestoreBillingDocumentDTO {
    init(from decoder: any Decoder) throws {
        try requireBillingPayloadKeys(decoder, allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decode(Int.self, forKey: .payloadVersion),
            request: try container.decode(BillingDocumentRequestDTO.self, forKey: .request),
            series: try container.decode(BillingDocumentSeries.self, forKey: .series),
            number: try container.decode(Int64.self, forKey: .number),
            issuedAt: try container.decode(ServerTimestamp<Date>.self, forKey: .issuedAt).wrappedValue
        )
    }

    init(_ record: BillingDocumentRecordDTO) {
        self.init(
            payloadVersion: record.payloadVersion,
            request: record.request,
            series: record.series,
            number: record.number,
            issuedAt: record.issuedAt?.date
        )
    }

    /// Converts only a resolved, coherent server record; no device clock supplies an issue date.
    func toRecord(documentID: String) throws -> BillingDocumentRecordDTO {
        guard documentID == request.documentID, let issuedAt else {
            throw BillingDocumentReservationError.invalidResponse
        }
        do {
            let record = BillingDocumentRecordDTO(
                payloadVersion: payloadVersion,
                request: request,
                series: series,
                number: number,
                issuedAt: try SaleTimestampDTO(issuedAt)
            )
            _ = try record.toDomain()
            return record
        } catch {
            throw BillingDocumentReservationError.invalidResponse
        }
    }
}

/// Billing identity and family keys remain isolated from legacy collections and sync feed counters.
struct BillingFirestorePaths {
    let environment: FirestoreEnvironment
    let request: BillingDocumentRequestDTO

    var binding: String { "\(environment.rawValue)/collections/billingRequests/\(request.id)" }
    var document: String { "\(environment.rawValue)/collections/billingDocuments/\(request.documentID)" }
    var counter: String { "\(environment.rawValue)/collections/billingCounters/\(request.kind.series.rawValue)" }
}

private let billingTransactionErrorDomain = "FranAlonso.BillingTransaction"

private func billingSDKError(_ error: any Error) -> NSError {
    guard let neutral = error as? BillingDocumentReservationError else { return error as NSError }
    let code: Int
    switch neutral {
    case .unavailable: code = 1
    case .permissionDenied: code = 2
    case .conflict: code = 3
    case .invalidResponse: code = 4
    }
    return NSError(domain: billingTransactionErrorDomain, code: code)
}

private func billingFirestoreError(_ error: any Error) -> any Error {
    if error is CancellationError {
        return CancellationError()
    }
    if let neutral = error as? BillingDocumentReservationError {
        return neutral
    }
    if error is DecodingError || error is EncodingError {
        return BillingDocumentReservationError.invalidResponse
    }
    let provider = error as NSError
    if provider.domain == billingTransactionErrorDomain {
        switch provider.code {
        case 1: return BillingDocumentReservationError.unavailable
        case 2: return BillingDocumentReservationError.permissionDenied
        case 3: return BillingDocumentReservationError.conflict
        case 4: return BillingDocumentReservationError.invalidResponse
        default: return BillingDocumentReservationError.unavailable
        }
    }
    guard provider.domain == FirestoreErrorDomain else { return BillingDocumentReservationError.unavailable }
    switch provider.code {
    case FirestoreErrorCode.permissionDenied.rawValue, FirestoreErrorCode.unauthenticated.rawValue:
        return BillingDocumentReservationError.permissionDenied
    case FirestoreErrorCode.cancelled.rawValue:
        return CancellationError()
    case FirestoreErrorCode.invalidArgument.rawValue, FirestoreErrorCode.dataLoss.rawValue:
        return BillingDocumentReservationError.invalidResponse
    default:
        return BillingDocumentReservationError.unavailable
    }
}
