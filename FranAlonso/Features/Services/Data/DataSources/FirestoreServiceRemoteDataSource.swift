import FirebaseFirestore
import Foundation

/// Adapts Firestore Services documents to the provider-neutral incremental contract.
actor FirestoreServiceRemoteDataSource: ServiceRemoteDataSource {
    private let fetchDocuments: (ServiceSyncCursor?) async throws -> [
        (documentID: String, record: ServiceRemoteRecord)
    ]
    private let transactMutation: (
        ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult

    init(
        fetch: @escaping (ServiceSyncCursor?) async throws -> [
            (documentID: String, record: ServiceRemoteRecord)
        ],
        transact: @escaping (
            ServicePendingOperation
        ) async throws -> ServiceRemoteMutationResult
    ) {
        fetchDocuments = fetch
        transactMutation = transact
    }

    /// Creates the adapter for the Services collection in an explicitly selected environment.
    init(firestore: Firestore, environment: FirestoreEnvironment) {
        let collection = firestore.collection(
            environment.collectionPath(for: .services)
        )
        let counterDocument = firestore.document(
            environment.syncMetadataDocumentPath(for: .services)
        )
        let policy = ServiceSyncPolicy()

        fetchDocuments = { cursor in
            let query: Query
            if let cursor {
                query = collection
                    .whereField(
                        "_sync.changeSequence",
                        isGreaterThan: cursor.changeSequence
                    )
                    .order(by: "_sync.changeSequence")
            } else {
                query = collection
            }
            let snapshot = try await query.getDocuments(source: .server)
            return try snapshot.documents.map { document in
                let payload = try document.data(
                    as: FirestoreServiceDocumentDTO.self
                )
                return (
                    documentID: document.documentID,
                    record: try payload.toRemoteRecord(
                        documentID: document.documentID
                    )
                )
            }
        }
        transactMutation = { operation in
            try await Self.runTransaction(
                operation,
                collection: collection,
                counterDocument: counterDocument,
                firestore: firestore,
                policy: policy
            )
        }
    }

    /// Creates the live adapter after the default Firebase app has been configured.
    init(environment: FirestoreEnvironment) {
        self.init(
            firestore: Firestore.firestore(),
            environment: environment
        )
    }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        do {
            let documents = try await fetchDocuments(cursor)
            let records = try documents.map { document in
                guard document.documentID == document.record.id else {
                    throw serviceDocumentDecodingError(
                        codingPath: [ServiceDocumentCodingKey.id],
                        description: "The service identifier does not match its document path."
                    )
                }
                if let sequence = document.record.changeSequence {
                    guard sequence > 0 else {
                        throw ServiceSyncPolicyError.invalidChangeSequence
                    }
                } else if cursor != nil {
                    throw ServiceSyncPolicyError.invalidChangeSequence
                }
                return document.record
            }
            let nextSequence = records.compactMap(\.changeSequence).max()
                ?? cursor?.changeSequence
                ?? 0
            return ServiceRemoteChangeBatch(
                records: records,
                nextCursor: ServiceSyncCursor(
                    changeSequence: nextSequence
                )
            )
        } catch {
            throw mapFirestoreServiceError(error)
        }
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        do {
            if case .upsert(let upsert) = operation {
                guard UUID(uuidString: upsert.service.id) == upsert.serviceID else {
                    throw ServiceSyncPolicyError.entityIdentityMismatch
                }
            }
            return try await transactMutation(operation)
        } catch {
            throw mapFirestoreServiceError(error)
        }
    }
}

extension FirestoreServiceRemoteDataSource {
    /// Returns the next counter value, treating an absent counter as zero.
    ///
    /// - Throws: A typed policy error for negative or exhausted counter state.
    static func nextChangeSequence(after current: Int64?) throws -> Int64 {
        let current = current ?? 0
        guard current >= 0 else {
            throw ServiceSyncPolicyError.invalidChangeSequence
        }
        guard current < Int64.max else {
            throw ServiceSyncPolicyError.changeSequenceOverflow
        }
        return current + 1
    }

    private static func runTransaction(
        _ operation: ServicePendingOperation,
        collection: CollectionReference,
        counterDocument: DocumentReference,
        firestore: Firestore,
        policy: ServiceSyncPolicy
    ) async throws -> ServiceRemoteMutationResult {
        let document = collection.document(operation.serviceID.uuidString)
        return try await withCheckedThrowingContinuation { continuation in
            firestore.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(document)
                    let remoteRecord: ServiceRemoteRecord?
                    if snapshot.exists {
                        remoteRecord = try snapshot.data(
                            as: FirestoreServiceDocumentDTO.self
                        ).toRemoteRecord(documentID: snapshot.documentID)
                    } else {
                        remoteRecord = nil
                    }

                    let decision = policy.decision(
                        for: operation,
                        against: remoteRecord
                    )
                    let counterState: FirestoreServiceCounterState
                    if case .apply = decision {
                        let counterSnapshot = try transaction.getDocument(
                            counterDocument
                        )
                        if counterSnapshot.exists {
                            do {
                                counterState = .value(
                                    try counterSnapshot.data(
                                        as: FirestoreServiceCounterDTO.self
                                    ).changeSequence
                                )
                            } catch is DecodingError {
                                counterState = .malformed
                            }
                        } else {
                            counterState = .absent
                        }
                    } else {
                        counterState = .unread
                    }

                    let outcome: FirestoreServiceTransactionOutcome
                    switch try transactionPlan(
                        for: operation,
                        against: remoteRecord,
                        counter: counterState,
                        policy: policy
                    ) {
                    case .atomic(let write):
                        try transaction.setData(
                            from: FirestoreServiceWriteDTO(write.record),
                            forDocument: document,
                            merge: false
                        )
                        try transaction.setData(
                            from: write.counter,
                            forDocument: counterDocument,
                            merge: false
                        )
                        outcome = .result(.applied(write.record))
                    case .result(let result):
                        outcome = .result(result)
                    case .invalid(let error):
                        outcome = .invalid(error)
                    }
                    return try JSONEncoder().encode(outcome)
                } catch {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            } completion: { encodedOutcome, error in
                do {
                    if let error { throw error }
                    guard let outcomeData = encodedOutcome as? Data else {
                        throw ServiceRemoteDataSourceError.unexpected
                    }
                    switch try JSONDecoder().decode(
                        FirestoreServiceTransactionOutcome.self,
                        from: outcomeData
                    ) {
                    case .result(let result):
                        continuation.resume(returning: result)
                    case .invalid(let error):
                        continuation.resume(throwing: error)
                    }
                } catch {
                    continuation.resume(throwing: error)
                }
            }
        }
    }

    /// Plans the provider transaction before either Firestore write is emitted.
    ///
    /// A mutation requiring a write returns one inseparable service-and-counter pair. Invalid
    /// counter state throws before a write plan exists; idempotent and conflict outcomes do
    /// not read or advance the counter.
    static func transactionPlan(
        for operation: ServicePendingOperation,
        against remoteRecord: ServiceRemoteRecord?,
        counter: FirestoreServiceCounterState,
        policy: ServiceSyncPolicy
    ) throws -> FirestoreServiceTransactionPlan {
        switch policy.decision(for: operation, against: remoteRecord) {
        case .apply(let recordWithoutSequence):
            let currentSequence: Int64?
            switch counter {
            case .absent:
                currentSequence = nil
            case .value(let value):
                currentSequence = value
            case .malformed, .unread:
                throw ServiceSyncPolicyError.invalidChangeSequence
            }
            let nextSequence = try nextChangeSequence(
                after: currentSequence
            )
            let record = recordWithoutSequence.withChangeSequence(
                nextSequence
            )
            return .atomic(
                FirestoreServiceAtomicWrite(
                    record: record,
                    counter: FirestoreServiceCounterDTO(
                        changeSequence: nextSequence
                    )
                )
            )
        case .alreadyApplied(let record):
            return .result(.alreadyApplied(record))
        case .conflict(let reason, let record):
            return .result(.conflict(reason, record))
        case .invalid(let error):
            return .invalid(error)
        }
    }
}

struct FirestoreServiceWriteDTO: Encodable {
    private let id: String
    private let isDeleted: Bool
    private let name: String?
    private let type: ServiceTypeDTO?
    private let linkedProductID: String?
    private let price: ServiceMoneyDTO?
    private let taxRate: ServiceTaxRateDTO?
    private let discount: ServiceDiscountDTO?
    private let status: ServiceStatusDTO?
    private let syncMetadata: FirestoreServiceSyncWriteDTO

    private enum CodingKeys: String, CodingKey {
        case id
        case isDeleted = "_deleted"
        case name
        case type
        case linkedProductID
        case price
        case taxRate
        case discount
        case status
        case syncMetadata = "_sync"
    }
}

extension FirestoreServiceWriteDTO {
    /// Encodes a complete live document or business-field-free tombstone from an authoritative record.
    init(_ record: ServiceRemoteRecord) throws {
        guard let sequence = record.changeSequence, sequence > 0,
              case .versioned(let revision, let operationID) = record.version else {
            throw ServiceSyncPolicyError.invalidChangeSequence
        }
        let syncMetadata = FirestoreServiceSyncWriteDTO(
            revision: revision,
            lastOperationID: operationID.uuidString,
            changeSequence: sequence
        )
        switch record.content {
        case .live(let service):
            _ = try service.toDomain()
            self.init(
                id: service.id,
                isDeleted: false,
                name: service.name,
                type: service.type,
                linkedProductID: service.linkedProductID,
                price: service.price,
                taxRate: service.taxRate,
                discount: service.discount,
                status: service.status,
                syncMetadata: syncMetadata
            )
        case .tombstone(let serviceID):
            self.init(
                id: serviceID.uuidString,
                isDeleted: true,
                name: nil,
                type: nil,
                linkedProductID: nil,
                price: nil,
                taxRate: nil,
                discount: nil,
                status: nil,
                syncMetadata: syncMetadata
            )
        }
    }
}

struct FirestoreServiceSyncWriteDTO: Encodable {
    let revision: Int64
    let lastOperationID: String
    let changeSequence: Int64
}

struct FirestoreServiceDocumentDTO: Decodable {
    let id: String
    let isDeleted: Bool?
    let name: String?
    let type: ServiceTypeDTO?
    let linkedProductID: String?
    let price: ServiceMoneyDTO?
    let taxRate: ServiceTaxRateDTO?
    let discount: ServiceDiscountDTO?
    let status: ServiceStatusDTO?
    let syncMetadata: FirestoreServiceSyncMetadataDTO?

    private enum CodingKeys: String, CodingKey {
        case id
        case isDeleted = "_deleted"
        case name
        case type
        case linkedProductID
        case price
        case taxRate
        case discount
        case status
        case syncMetadata = "_sync"
    }

    /// Reconstructs a provider-neutral live record or tombstone after validating metadata.
    func toRemoteRecord(documentID: String) throws -> ServiceRemoteRecord {
        guard documentID == id, let serviceID = UUID(uuidString: id) else {
            throw serviceDocumentDecodingError(
                codingPath: [ServiceDocumentCodingKey.id],
                description: "The service identifier does not match its document path."
            )
        }
        let version = try remoteVersion()
        let changeSequence = try validatedChangeSequence()

        if isDeleted == true {
            guard syncMetadata != nil else {
                throw serviceDocumentDecodingError(
                    codingPath: [ServiceDocumentCodingKey.syncMetadata],
                    description: "A tombstone requires authoritative sync metadata."
                )
            }
            return ServiceRemoteRecord(
                content: .tombstone(serviceID: serviceID),
                version: version,
                changeSequence: changeSequence
            )
        }

        let service = try validatedLiveService()
        return ServiceRemoteRecord(
            content: .live(service),
            version: version,
            changeSequence: changeSequence
        )
    }

    private func validatedLiveService() throws -> ServiceDTO {
        guard let name else {
            throw missingServiceField(.name)
        }
        guard let type else {
            throw missingServiceField(.type)
        }
        guard let price else {
            throw missingServiceField(.price)
        }
        guard let taxRate else {
            throw missingServiceField(.taxRate)
        }
        guard let status else {
            throw missingServiceField(.status)
        }
        let service = ServiceDTO(
            id: id,
            name: name,
            type: type,
            linkedProductID: linkedProductID,
            price: price,
            taxRate: taxRate,
            discount: discount,
            status: status
        )
        do {
            _ = try service.toDomain()
        } catch {
            throw serviceBusinessDecodingError(error)
        }
        return service
    }

    private func remoteVersion() throws -> ServiceRemoteVersion {
        guard let syncMetadata else { return .legacy }
        guard syncMetadata.revision > 0 else {
            throw serviceDocumentDecodingError(
                codingPath: [
                    ServiceDocumentCodingKey.syncMetadata,
                    ServiceDocumentCodingKey.revision
                ],
                description: "A synchronized service revision must be positive."
            )
        }
        guard let operationID = UUID(
            uuidString: syncMetadata.lastOperationID
        ) else {
            throw serviceDocumentDecodingError(
                codingPath: [
                    ServiceDocumentCodingKey.syncMetadata,
                    ServiceDocumentCodingKey.lastOperationID
                ],
                description: "The synchronized service operation identifier is invalid."
            )
        }
        return .versioned(
            revision: syncMetadata.revision,
            lastOperationID: operationID
        )
    }

    private func validatedChangeSequence() throws -> Int64? {
        guard let sequence = syncMetadata?.changeSequence else { return nil }
        guard sequence > 0 else {
            throw serviceDocumentDecodingError(
                codingPath: [
                    ServiceDocumentCodingKey.syncMetadata,
                    ServiceDocumentCodingKey.changeSequence
                ],
                description: "A synchronized change sequence must be positive."
            )
        }
        return sequence
    }

    private func missingServiceField(
        _ key: ServiceDocumentCodingKey
    ) -> DecodingError {
        serviceDocumentDecodingError(
            codingPath: [key],
            description: "A live service requires \(key.stringValue)."
        )
    }
}

struct FirestoreServiceSyncMetadataDTO: Decodable {
    let revision: Int64
    let lastOperationID: String
    let changeSequence: Int64?
}

struct FirestoreServiceCounterDTO: Codable, Equatable {
    let changeSequence: Int64
}

enum FirestoreServiceCounterState: Equatable {
    case unread
    case absent
    case value(Int64)
    case malformed
}

struct FirestoreServiceAtomicWrite: Equatable {
    let record: ServiceRemoteRecord
    let counter: FirestoreServiceCounterDTO
}

enum FirestoreServiceTransactionPlan: Equatable {
    case atomic(FirestoreServiceAtomicWrite)
    case result(ServiceRemoteMutationResult)
    case invalid(ServiceSyncPolicyError)

    var atomicWrite: FirestoreServiceAtomicWrite? {
        guard case .atomic(let write) = self else { return nil }
        return write
    }
}

private enum FirestoreServiceTransactionOutcome: Codable {
    case result(ServiceRemoteMutationResult)
    case invalid(ServiceSyncPolicyError)
}

private enum ServiceDocumentCodingKey: String, CodingKey {
    case id
    case name
    case type
    case linkedProductID
    case price
    case amount
    case taxRate
    case discount
    case percentage
    case status
    case syncMetadata = "_sync"
    case revision
    case lastOperationID
    case changeSequence
}

private extension ServiceRemoteRecord {
    func withChangeSequence(_ changeSequence: Int64) -> ServiceRemoteRecord {
        ServiceRemoteRecord(
            content: content,
            version: version,
            changeSequence: changeSequence
        )
    }
}

private func serviceDocumentDecodingError(
    codingPath: [any CodingKey],
    description: String
) -> DecodingError {
    DecodingError.dataCorrupted(
        DecodingError.Context(
            codingPath: codingPath,
            debugDescription: description
        )
    )
}

private func serviceBusinessDecodingError(
    _ error: any Error
) -> DecodingError {
    let codingPath: [any CodingKey]
    switch error {
    case ServiceMappingError.invalidIdentifier:
        codingPath = [ServiceDocumentCodingKey.id]
    case ServiceMappingError.invalidLinkedProductIdentifier:
        codingPath = [ServiceDocumentCodingKey.linkedProductID]
    case ServiceMappingError.moneyNormalizationChanged,
         is MoneyError:
        codingPath = [
            ServiceDocumentCodingKey.price,
            ServiceDocumentCodingKey.amount
        ]
    case is TaxRateError:
        codingPath = [
            ServiceDocumentCodingKey.taxRate,
            ServiceDocumentCodingKey.percentage
        ]
    case is DiscountError:
        codingPath = [
            ServiceDocumentCodingKey.discount,
            ServiceDocumentCodingKey.percentage
        ]
    case is ServiceError:
        codingPath = [ServiceDocumentCodingKey.linkedProductID]
    default:
        codingPath = []
    }
    return serviceDocumentDecodingError(
        codingPath: codingPath,
        description: "The service business snapshot violates its Domain contract."
    )
}

private func mapFirestoreServiceError(_ error: any Error) -> any Error {
    if error is DecodingError || error is ServiceSyncPolicyError {
        return error
    }
    if error is CancellationError { return CancellationError() }

    let providerError = error as NSError
    guard providerError.domain == FirestoreErrorDomain else {
        return ServiceRemoteDataSourceError.unexpected
    }
    switch providerError.code {
    case FirestoreErrorCode.deadlineExceeded.rawValue:
        return ServiceRemoteDataSourceError.deadlineExceeded
    case FirestoreErrorCode.permissionDenied.rawValue:
        return ServiceRemoteDataSourceError.permissionDenied
    case FirestoreErrorCode.resourceExhausted.rawValue:
        return ServiceRemoteDataSourceError.resourceExhausted
    case FirestoreErrorCode.aborted.rawValue:
        return ServiceRemoteDataSourceError.aborted
    case FirestoreErrorCode.unavailable.rawValue:
        return ServiceRemoteDataSourceError.unavailable
    case FirestoreErrorCode.cancelled.rawValue:
        return CancellationError()
    default:
        return ServiceRemoteDataSourceError.unexpected
    }
}
