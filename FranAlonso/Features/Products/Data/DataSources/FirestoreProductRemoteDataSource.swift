import FirebaseFirestore

/// Adapts Firestore Products documents to the provider-neutral incremental contract.
actor FirestoreProductRemoteDataSource: ProductRemoteDataSource {
    private let fetchDocuments: (ProductSyncCursor?) async throws -> [
        (documentID: String, record: ProductRemoteRecord)
    ]
    private let transactMutation: (
        ProductPendingOperation
    ) async throws -> ProductRemoteMutationResult

    init(
        fetch: @escaping (ProductSyncCursor?) async throws -> [
            (documentID: String, record: ProductRemoteRecord)
        ],
        transact: @escaping (
            ProductPendingOperation
        ) async throws -> ProductRemoteMutationResult
    ) {
        fetchDocuments = fetch
        transactMutation = transact
    }

    /// Creates the adapter for the Products collection in an explicitly selected environment.
    init(firestore: Firestore, environment: FirestoreEnvironment) {
        let collection = firestore.collection(
            environment.collectionPath(for: .products)
        )
        let counterDocument = firestore.document(
            environment.syncMetadataDocumentPath(for: .products)
        )
        let policy = ProductSyncPolicy()

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
                    as: FirestoreProductDocumentDTO.self
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
        after cursor: ProductSyncCursor?
    ) async throws -> ProductRemoteChangeBatch {
        do {
            let documents = try await fetchDocuments(cursor)
            let records = try documents.map { document in
                guard document.documentID == document.record.id else {
                    throw productDocumentDecodingError(
                        codingPath: [ProductDocumentCodingKey.id],
                        description: "The product identifier does not match its document path."
                    )
                }
                if let sequence = document.record.changeSequence {
                    guard sequence > 0 else {
                        throw ProductSyncPolicyError.invalidChangeSequence
                    }
                } else if cursor != nil {
                    throw ProductSyncPolicyError.invalidChangeSequence
                }
                return document.record
            }
            let nextSequence = records.compactMap(\.changeSequence).max()
                ?? cursor?.changeSequence
                ?? 0
            return ProductRemoteChangeBatch(
                records: records,
                nextCursor: ProductSyncCursor(
                    changeSequence: nextSequence
                )
            )
        } catch {
            throw mapFirestoreError(error)
        }
    }

    func apply(
        _ operation: ProductPendingOperation
    ) async throws -> ProductRemoteMutationResult {
        do {
            if case .upsert(let upsert) = operation {
                guard UUID(uuidString: upsert.product.id) == upsert.productID else {
                    throw ProductSyncPolicyError.entityIdentityMismatch
                }
            }
            return try await transactMutation(operation)
        } catch {
            throw mapFirestoreError(error)
        }
    }
}

extension FirestoreProductRemoteDataSource {
    /// Returns the next counter value, treating an absent counter as zero.
    ///
    /// - Throws: A typed policy error for negative or exhausted counter state.
    static func nextChangeSequence(after current: Int64?) throws -> Int64 {
        let current = current ?? 0
        guard current >= 0 else {
            throw ProductSyncPolicyError.invalidChangeSequence
        }
        guard current < Int64.max else {
            throw ProductSyncPolicyError.changeSequenceOverflow
        }
        return current + 1
    }

    private static func runTransaction(
        _ operation: ProductPendingOperation,
        collection: CollectionReference,
        counterDocument: DocumentReference,
        firestore: Firestore,
        policy: ProductSyncPolicy
    ) async throws -> ProductRemoteMutationResult {
        let document = collection.document(operation.productID.uuidString)
        return try await withCheckedThrowingContinuation { continuation in
            firestore.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(document)
                    let remoteRecord: ProductRemoteRecord?
                    if snapshot.exists {
                        remoteRecord = try snapshot.data(
                            as: FirestoreProductDocumentDTO.self
                        ).toRemoteRecord(documentID: snapshot.documentID)
                    } else {
                        remoteRecord = nil
                    }

                    let decision = policy.decision(
                        for: operation,
                        against: remoteRecord
                    )
                    let counterState: FirestoreProductCounterState
                    if case .apply = decision {
                        let counterSnapshot = try transaction.getDocument(
                            counterDocument
                        )
                        if counterSnapshot.exists {
                            do {
                                counterState = .value(
                                    try counterSnapshot.data(
                                        as: FirestoreProductCounterDTO.self
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

                    let outcome: FirestoreProductTransactionOutcome
                    switch try transactionPlan(
                        for: operation,
                        against: remoteRecord,
                        counter: counterState,
                        policy: policy
                    ) {
                    case .atomic(let write):
                        try transaction.setData(
                            from: FirestoreProductWriteDTO(write.record),
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
                        throw ProductRemoteDataSourceError.unexpected
                    }
                    switch try JSONDecoder().decode(
                        FirestoreProductTransactionOutcome.self,
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
    /// A mutation requiring a write returns one inseparable product-and-counter pair. Invalid
    /// counter state throws before a write plan exists; idempotent and conflict outcomes do
    /// not read or advance the counter.
    static func transactionPlan(
        for operation: ProductPendingOperation,
        against remoteRecord: ProductRemoteRecord?,
        counter: FirestoreProductCounterState,
        policy: ProductSyncPolicy
    ) throws -> FirestoreProductTransactionPlan {
        switch policy.decision(for: operation, against: remoteRecord) {
        case .apply(let recordWithoutSequence):
            let currentSequence: Int64?
            switch counter {
            case .absent:
                currentSequence = nil
            case .value(let value):
                currentSequence = value
            case .malformed, .unread:
                throw ProductSyncPolicyError.invalidChangeSequence
            }
            let nextSequence = try nextChangeSequence(
                after: currentSequence
            )
            let record = recordWithoutSequence.withChangeSequence(
                nextSequence
            )
            return .atomic(
                FirestoreProductAtomicWrite(
                    record: record,
                    counter: FirestoreProductCounterDTO(
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

struct FirestoreProductWriteDTO: Encodable {
    let id: String
    let isDeleted: Bool
    let name: String?
    let status: ProductStatusDTO?
    let syncMetadata: FirestoreProductSyncWriteDTO

    private enum CodingKeys: String, CodingKey {
        case id
        case isDeleted = "_deleted"
        case name
        case status
        case syncMetadata = "_sync"
    }
}

extension FirestoreProductWriteDTO {
    /// Encodes a full live document or a PII-free tombstone from an authoritative record.
    init(_ record: ProductRemoteRecord) throws {
        guard let sequence = record.changeSequence, sequence > 0,
              case .versioned(let revision, let operationID) = record.version else {
            throw ProductSyncPolicyError.invalidChangeSequence
        }
        switch record.content {
        case .live(let product):
            self.init(
                id: product.id,
                isDeleted: false,
                name: product.name,
                status: product.status,
                syncMetadata: FirestoreProductSyncWriteDTO(
                    revision: revision,
                    lastOperationID: operationID.uuidString,
                    changeSequence: sequence
                )
            )
        case .tombstone(let productID):
            self.init(
                id: productID.uuidString,
                isDeleted: true,
                name: nil,
                status: nil,
                syncMetadata: FirestoreProductSyncWriteDTO(
                    revision: revision,
                    lastOperationID: operationID.uuidString,
                    changeSequence: sequence
                )
            )
        }
    }
}

struct FirestoreProductSyncWriteDTO: Encodable {
    let revision: Int64
    let lastOperationID: String
    let changeSequence: Int64
}

struct FirestoreProductDocumentDTO: Decodable {
    let id: String
    let isDeleted: Bool?
    let name: String?
    let status: ProductStatusDTO?
    let syncMetadata: FirestoreProductSyncMetadataDTO?

    private enum CodingKeys: String, CodingKey {
        case id
        case isDeleted = "_deleted"
        case name
        case status
        case syncMetadata = "_sync"
    }

    /// Reconstructs a provider-neutral live record or tombstone after validating metadata.
    func toRemoteRecord(documentID: String) throws -> ProductRemoteRecord {
        guard documentID == id, let productID = UUID(uuidString: id) else {
            throw productDocumentDecodingError(
                codingPath: [ProductDocumentCodingKey.id],
                description: "The product identifier does not match its document path."
            )
        }
        let version = try remoteVersion()
        let changeSequence = try validatedChangeSequence()

        if isDeleted == true {
            guard syncMetadata != nil else {
                throw productDocumentDecodingError(
                    codingPath: [ProductDocumentCodingKey.syncMetadata],
                    description: "A tombstone requires authoritative sync metadata."
                )
            }
            return ProductRemoteRecord(
                content: .tombstone(productID: productID),
                version: version,
                changeSequence: changeSequence
            )
        }

        guard let name else {
            throw missingProductField(.name)
        }
        guard let status else {
            throw missingProductField(.status)
        }
        return ProductRemoteRecord(
            content: .live(
                ProductDTO(
                    id: id,
                    name: name,
                    status: status
                )
            ),
            version: version,
            changeSequence: changeSequence
        )
    }

    private func remoteVersion() throws -> ProductRemoteVersion {
        guard let syncMetadata else { return .legacy }
        guard syncMetadata.revision > 0 else {
            throw productDocumentDecodingError(
                codingPath: [
                    ProductDocumentCodingKey.syncMetadata,
                    ProductDocumentCodingKey.revision
                ],
                description: "A synchronized product revision must be positive."
            )
        }
        guard let operationID = UUID(
            uuidString: syncMetadata.lastOperationID
        ) else {
            throw productDocumentDecodingError(
                codingPath: [
                    ProductDocumentCodingKey.syncMetadata,
                    ProductDocumentCodingKey.lastOperationID
                ],
                description: "The synchronized product operation identifier is invalid."
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
            throw productDocumentDecodingError(
                codingPath: [
                    ProductDocumentCodingKey.syncMetadata,
                    ProductDocumentCodingKey.changeSequence
                ],
                description: "A synchronized change sequence must be positive."
            )
        }
        return sequence
    }

    private func missingProductField(
        _ key: ProductDocumentCodingKey
    ) -> DecodingError {
        productDocumentDecodingError(
            codingPath: [key],
            description: "A live product requires \(key.stringValue)."
        )
    }
}

struct FirestoreProductSyncMetadataDTO: Decodable {
    let revision: Int64
    let lastOperationID: String
    let changeSequence: Int64?
}

struct FirestoreProductCounterDTO: Codable, Equatable {
    let changeSequence: Int64
}

enum FirestoreProductCounterState: Equatable {
    case unread
    case absent
    case value(Int64)
    case malformed
}

struct FirestoreProductAtomicWrite: Equatable {
    let record: ProductRemoteRecord
    let counter: FirestoreProductCounterDTO
}

enum FirestoreProductTransactionPlan: Equatable {
    case atomic(FirestoreProductAtomicWrite)
    case result(ProductRemoteMutationResult)
    case invalid(ProductSyncPolicyError)

    var atomicWrite: FirestoreProductAtomicWrite? {
        guard case .atomic(let write) = self else { return nil }
        return write
    }
}

private enum FirestoreProductTransactionOutcome: Codable {
    case result(ProductRemoteMutationResult)
    case invalid(ProductSyncPolicyError)
}

private enum ProductDocumentCodingKey: String, CodingKey {
    case id
    case name
    case status
    case syncMetadata = "_sync"
    case revision
    case lastOperationID
    case changeSequence
}

private extension ProductRemoteRecord {
    func withChangeSequence(_ changeSequence: Int64) -> ProductRemoteRecord {
        ProductRemoteRecord(
            content: content,
            version: version,
            changeSequence: changeSequence
        )
    }
}

private func productDocumentDecodingError(
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

private func mapFirestoreError(_ error: any Error) -> any Error {
    if error is DecodingError || error is ProductSyncPolicyError {
        return error
    }
    if error is CancellationError { return CancellationError() }

    let providerError = error as NSError
    guard providerError.domain == FirestoreErrorDomain else {
        return ProductRemoteDataSourceError.unexpected
    }
    switch providerError.code {
    case FirestoreErrorCode.deadlineExceeded.rawValue:
        return ProductRemoteDataSourceError.deadlineExceeded
    case FirestoreErrorCode.permissionDenied.rawValue:
        return ProductRemoteDataSourceError.permissionDenied
    case FirestoreErrorCode.resourceExhausted.rawValue:
        return ProductRemoteDataSourceError.resourceExhausted
    case FirestoreErrorCode.aborted.rawValue:
        return ProductRemoteDataSourceError.aborted
    case FirestoreErrorCode.unavailable.rawValue:
        return ProductRemoteDataSourceError.unavailable
    case FirestoreErrorCode.cancelled.rawValue:
        return CancellationError()
    default:
        return ProductRemoteDataSourceError.unexpected
    }
}
