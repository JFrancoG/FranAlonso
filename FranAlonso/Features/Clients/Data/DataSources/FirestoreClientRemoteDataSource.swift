import FirebaseFirestore

/// Adapts Firestore Clients documents to the provider-neutral incremental contract.
actor FirestoreClientRemoteDataSource: ClientRemoteDataSource {
    private let fetchDocuments: (ClientSyncCursor?) async throws -> [
        (documentID: String, record: ClientRemoteRecord)
    ]
    private let transactMutation: (
        ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult

    init(
        fetch: @escaping (ClientSyncCursor?) async throws -> [
            (documentID: String, record: ClientRemoteRecord)
        ],
        transact: @escaping (
            ClientPendingOperation
        ) async throws -> ClientRemoteMutationResult
    ) {
        fetchDocuments = fetch
        transactMutation = transact
    }

    /// Creates the adapter for the Clients collection in an explicitly selected environment.
    init(firestore: Firestore, environment: FirestoreEnvironment) {
        let collection = firestore.collection(
            Self.collectionPath(in: environment)
        )
        let counterDocument = firestore.document(
            Self.syncMetadataPath(in: environment)
        )
        let policy = ClientSyncPolicy()

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
                    as: FirestoreClientDocumentDTO.self
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
        after cursor: ClientSyncCursor?
    ) async throws -> ClientRemoteChangeBatch {
        do {
            let documents = try await fetchDocuments(cursor)
            let records = try documents.map { document in
                guard document.documentID == document.record.id else {
                    throw clientDocumentDecodingError(
                        codingPath: [ClientDocumentCodingKey.id],
                        description: "The client identifier does not match its document path."
                    )
                }
                if let sequence = document.record.changeSequence {
                    guard sequence > 0 else {
                        throw ClientSyncPolicyError.invalidChangeSequence
                    }
                } else if cursor != nil {
                    throw ClientSyncPolicyError.invalidChangeSequence
                }
                return document.record
            }
            let nextSequence = records.compactMap(\.changeSequence).max()
                ?? cursor?.changeSequence
                ?? 0
            return ClientRemoteChangeBatch(
                records: records,
                nextCursor: ClientSyncCursor(
                    changeSequence: nextSequence
                )
            )
        } catch {
            throw mapFirestoreError(error)
        }
    }

    func apply(
        _ operation: ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult {
        do {
            if case .upsert(let upsert) = operation {
                guard UUID(uuidString: upsert.client.id) == upsert.clientID else {
                    throw ClientSyncPolicyError.entityIdentityMismatch
                }
            }
            return try await transactMutation(operation)
        } catch {
            throw mapFirestoreError(error)
        }
    }
}

extension FirestoreClientRemoteDataSource {
    /// Returns the Clients collection path for an explicitly selected environment.
    static func collectionPath(in environment: FirestoreEnvironment) -> String {
        "\(environment.rawValue)/collections/clients"
    }

    /// Returns the per-environment Clients change-sequence counter path.
    static func syncMetadataPath(
        in environment: FirestoreEnvironment
    ) -> String {
        "\(environment.rawValue)/collections/syncMetadata/clients"
    }

    /// Returns the next counter value, treating an absent counter as zero.
    ///
    /// - Throws: A typed policy error for negative or exhausted counter state.
    static func nextChangeSequence(after current: Int64?) throws -> Int64 {
        let current = current ?? 0
        guard current >= 0 else {
            throw ClientSyncPolicyError.invalidChangeSequence
        }
        guard current < Int64.max else {
            throw ClientSyncPolicyError.changeSequenceOverflow
        }
        return current + 1
    }

    private static func runTransaction(
        _ operation: ClientPendingOperation,
        collection: CollectionReference,
        counterDocument: DocumentReference,
        firestore: Firestore,
        policy: ClientSyncPolicy
    ) async throws -> ClientRemoteMutationResult {
        let document = collection.document(operation.clientID.uuidString)
        return try await withCheckedThrowingContinuation { continuation in
            firestore.runTransaction { transaction, errorPointer -> Any? in
                do {
                    let snapshot = try transaction.getDocument(document)
                    let remoteRecord: ClientRemoteRecord?
                    if snapshot.exists {
                        remoteRecord = try snapshot.data(
                            as: FirestoreClientDocumentDTO.self
                        ).toRemoteRecord(documentID: snapshot.documentID)
                    } else {
                        remoteRecord = nil
                    }

                    let decision = policy.decision(
                        for: operation,
                        against: remoteRecord
                    )
                    let counterState: FirestoreClientCounterState
                    if case .apply = decision {
                        let counterSnapshot = try transaction.getDocument(
                            counterDocument
                        )
                        if counterSnapshot.exists {
                            do {
                                counterState = .value(
                                    try counterSnapshot.data(
                                        as: FirestoreClientCounterDTO.self
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

                    let outcome: FirestoreClientTransactionOutcome
                    switch try transactionPlan(
                        for: operation,
                        against: remoteRecord,
                        counter: counterState,
                        policy: policy
                    ) {
                    case .atomic(let write):
                        try transaction.setData(
                            from: FirestoreClientWriteDTO(write.record),
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
                        throw ClientRemoteDataSourceError.unexpected
                    }
                    switch try JSONDecoder().decode(
                        FirestoreClientTransactionOutcome.self,
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
    /// A mutation requiring a write returns one inseparable client-and-counter pair. Invalid
    /// counter state throws before a write plan exists; idempotent and conflict outcomes do
    /// not read or advance the counter.
    static func transactionPlan(
        for operation: ClientPendingOperation,
        against remoteRecord: ClientRemoteRecord?,
        counter: FirestoreClientCounterState,
        policy: ClientSyncPolicy
    ) throws -> FirestoreClientTransactionPlan {
        switch policy.decision(for: operation, against: remoteRecord) {
        case .apply(let recordWithoutSequence):
            let currentSequence: Int64?
            switch counter {
            case .absent:
                currentSequence = nil
            case .value(let value):
                currentSequence = value
            case .malformed, .unread:
                throw ClientSyncPolicyError.invalidChangeSequence
            }
            let nextSequence = try nextChangeSequence(
                after: currentSequence
            )
            let record = recordWithoutSequence.withChangeSequence(
                nextSequence
            )
            return .atomic(
                FirestoreClientAtomicWrite(
                    record: record,
                    counter: FirestoreClientCounterDTO(
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

struct FirestoreClientWriteDTO: Encodable {
    let id: String
    let isDeleted: Bool
    let displayName: String?
    let taxIdentifier: String?
    let billingAddress: BillingAddressDTO?
    let status: ClientStatusDTO?
    let consentReference: String?
    let syncMetadata: FirestoreClientSyncWriteDTO

    private enum CodingKeys: String, CodingKey {
        case id
        case isDeleted = "_deleted"
        case displayName
        case taxIdentifier
        case billingAddress
        case status
        case consentReference
        case syncMetadata = "_sync"
    }
}

extension FirestoreClientWriteDTO {
    /// Encodes a full live document or a PII-free tombstone from an authoritative record.
    init(_ record: ClientRemoteRecord) throws {
        guard let sequence = record.changeSequence, sequence > 0,
              case .versioned(let revision, let operationID) = record.version else {
            throw ClientSyncPolicyError.invalidChangeSequence
        }
        switch record.content {
        case .live(let client):
            self.init(
                id: client.id,
                isDeleted: false,
                displayName: client.displayName,
                taxIdentifier: client.taxIdentifier,
                billingAddress: client.billingAddress,
                status: client.status,
                consentReference: client.consentReference,
                syncMetadata: FirestoreClientSyncWriteDTO(
                    revision: revision,
                    lastOperationID: operationID.uuidString,
                    changeSequence: sequence
                )
            )
        case .tombstone(let clientID):
            self.init(
                id: clientID.uuidString,
                isDeleted: true,
                displayName: nil,
                taxIdentifier: nil,
                billingAddress: nil,
                status: nil,
                consentReference: nil,
                syncMetadata: FirestoreClientSyncWriteDTO(
                    revision: revision,
                    lastOperationID: operationID.uuidString,
                    changeSequence: sequence
                )
            )
        }
    }
}

struct FirestoreClientSyncWriteDTO: Encodable {
    let revision: Int64
    let lastOperationID: String
    let changeSequence: Int64
}

struct FirestoreClientDocumentDTO: Decodable {
    let id: String
    let isDeleted: Bool?
    let displayName: String?
    let taxIdentifier: String?
    let billingAddress: BillingAddressDTO?
    let status: ClientStatusDTO?
    let consentReference: String?
    let syncMetadata: FirestoreClientSyncMetadataDTO?

    private enum CodingKeys: String, CodingKey {
        case id
        case isDeleted = "_deleted"
        case displayName
        case taxIdentifier
        case billingAddress
        case status
        case consentReference
        case syncMetadata = "_sync"
    }

    /// Reconstructs a provider-neutral live record or tombstone after validating metadata.
    func toRemoteRecord(documentID: String) throws -> ClientRemoteRecord {
        guard documentID == id, let clientID = UUID(uuidString: id) else {
            throw clientDocumentDecodingError(
                codingPath: [ClientDocumentCodingKey.id],
                description: "The client identifier does not match its document path."
            )
        }
        let version = try remoteVersion()
        let changeSequence = try validatedChangeSequence()

        if isDeleted == true {
            guard syncMetadata != nil else {
                throw clientDocumentDecodingError(
                    codingPath: [ClientDocumentCodingKey.syncMetadata],
                    description: "A tombstone requires authoritative sync metadata."
                )
            }
            return ClientRemoteRecord(
                content: .tombstone(clientID: clientID),
                version: version,
                changeSequence: changeSequence
            )
        }

        guard let displayName else {
            throw missingClientField(.displayName)
        }
        guard let status else {
            throw missingClientField(.status)
        }
        return ClientRemoteRecord(
            content: .live(
                ClientDTO(
                    id: id,
                    displayName: displayName,
                    taxIdentifier: taxIdentifier,
                    billingAddress: billingAddress,
                    status: status,
                    consentReference: consentReference
                )
            ),
            version: version,
            changeSequence: changeSequence
        )
    }

    private func remoteVersion() throws -> ClientRemoteVersion {
        guard let syncMetadata else { return .legacy }
        guard syncMetadata.revision > 0 else {
            throw clientDocumentDecodingError(
                codingPath: [
                    ClientDocumentCodingKey.syncMetadata,
                    ClientDocumentCodingKey.revision
                ],
                description: "A synchronized client revision must be positive."
            )
        }
        guard let operationID = UUID(
            uuidString: syncMetadata.lastOperationID
        ) else {
            throw clientDocumentDecodingError(
                codingPath: [
                    ClientDocumentCodingKey.syncMetadata,
                    ClientDocumentCodingKey.lastOperationID
                ],
                description: "The synchronized client operation identifier is invalid."
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
            throw clientDocumentDecodingError(
                codingPath: [
                    ClientDocumentCodingKey.syncMetadata,
                    ClientDocumentCodingKey.changeSequence
                ],
                description: "A synchronized change sequence must be positive."
            )
        }
        return sequence
    }

    private func missingClientField(
        _ key: ClientDocumentCodingKey
    ) -> DecodingError {
        clientDocumentDecodingError(
            codingPath: [key],
            description: "A live client requires \(key.stringValue)."
        )
    }
}

struct FirestoreClientSyncMetadataDTO: Decodable {
    let revision: Int64
    let lastOperationID: String
    let changeSequence: Int64?
}

struct FirestoreClientCounterDTO: Codable, Equatable {
    let changeSequence: Int64
}

enum FirestoreClientCounterState: Equatable {
    case unread
    case absent
    case value(Int64)
    case malformed
}

struct FirestoreClientAtomicWrite: Equatable {
    let record: ClientRemoteRecord
    let counter: FirestoreClientCounterDTO
}

enum FirestoreClientTransactionPlan: Equatable {
    case atomic(FirestoreClientAtomicWrite)
    case result(ClientRemoteMutationResult)
    case invalid(ClientSyncPolicyError)

    var atomicWrite: FirestoreClientAtomicWrite? {
        guard case .atomic(let write) = self else { return nil }
        return write
    }
}

private enum FirestoreClientTransactionOutcome: Codable {
    case result(ClientRemoteMutationResult)
    case invalid(ClientSyncPolicyError)
}

private enum ClientDocumentCodingKey: String, CodingKey {
    case id
    case displayName
    case status
    case syncMetadata = "_sync"
    case revision
    case lastOperationID
    case changeSequence
}

private extension ClientRemoteRecord {
    func withChangeSequence(_ changeSequence: Int64) -> ClientRemoteRecord {
        ClientRemoteRecord(
            content: content,
            version: version,
            changeSequence: changeSequence
        )
    }
}

private func clientDocumentDecodingError(
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
    if error is DecodingError || error is ClientSyncPolicyError {
        return error
    }
    if error is CancellationError { return CancellationError() }

    let providerError = error as NSError
    guard providerError.domain == FirestoreErrorDomain else {
        return ClientRemoteDataSourceError.unexpected
    }
    switch providerError.code {
    case FirestoreErrorCode.permissionDenied.rawValue:
        return ClientRemoteDataSourceError.permissionDenied
    case FirestoreErrorCode.unavailable.rawValue:
        return ClientRemoteDataSourceError.unavailable
    case FirestoreErrorCode.cancelled.rawValue:
        return CancellationError()
    default:
        return ClientRemoteDataSourceError.unexpected
    }
}
