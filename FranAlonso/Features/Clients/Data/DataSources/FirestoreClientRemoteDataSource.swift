import FirebaseFirestore

/// Adapts Firestore Clients documents to the provider-neutral remote contract.
actor FirestoreClientRemoteDataSource: ClientRemoteDataSource {
    private let fetchDocuments: () async throws -> [
        (documentID: String, record: ClientRemoteRecord)
    ]
    private let transactUpsert: (
        ClientPendingUpsert,
        Bool
    ) async throws -> ClientRemoteUpsertResult

    init(
        fetch: @escaping () async throws -> [
            (documentID: String, record: ClientRemoteRecord)
        ],
        transact: @escaping (
            ClientPendingUpsert,
            Bool
        ) async throws -> ClientRemoteUpsertResult
    ) {
        fetchDocuments = fetch
        transactUpsert = transact
    }

    /// Creates the adapter for the Clients collection in an explicitly selected environment.
    ///
    /// - Parameters:
    ///   - firestore: The configured Firestore database instance.
    ///   - environment: The namespace that owns the Clients collection.
    init(firestore: Firestore, environment: FirestoreEnvironment) {
        let collection = firestore.collection(
            Self.collectionPath(in: environment)
        )
        let policy = ClientSyncPolicy()

        fetchDocuments = {
            let snapshot = try await collection.getDocuments(source: .server)
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
        transactUpsert = { operation, merge in
            try await Self.runTransaction(
                operation,
                collection: collection,
                firestore: firestore,
                policy: policy,
                merge: merge
            )
        }
    }

    /// Creates the live adapter after the default Firebase app has been configured.
    ///
    /// - Parameter environment: The explicit backend namespace to use.
    init(environment: FirestoreEnvironment) {
        self.init(
            firestore: Firestore.firestore(),
            environment: environment
        )
    }

    func fetchAll() async throws -> [ClientRemoteRecord] {
        do {
            return try await fetchDocuments().map { document in
                guard document.documentID == document.record.client.id else {
                    throw clientDocumentDecodingError(
                        codingPath: [ClientDocumentCodingKey.id],
                        description: "The client identifier does not match its document path."
                    )
                }

                return document.record
            }
        } catch {
            throw mapFirestoreError(error)
        }
    }

    func upsert(
        _ operation: ClientPendingUpsert
    ) async throws -> ClientRemoteUpsertResult {
        do {
            guard UUID(uuidString: operation.client.id) == operation.clientID else {
                throw ClientSyncPolicyError.entityIdentityMismatch
            }
            return try await transactUpsert(operation, true)
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

    private static func runTransaction(
        _ operation: ClientPendingUpsert,
        collection: CollectionReference,
        firestore: Firestore,
        policy: ClientSyncPolicy,
        merge: Bool
    ) async throws -> ClientRemoteUpsertResult {
        let document = collection.document(operation.client.id)
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

                    let outcome: FirestoreClientTransactionOutcome
                    switch policy.decision(
                        for: operation,
                        against: remoteRecord
                    ) {
                    case .apply(let record):
                        try transaction.setData(
                            from: FirestoreClientWriteDTO(operation),
                            forDocument: document,
                            merge: merge
                        )
                        outcome = .result(.applied(record))
                    case .alreadyApplied(let record):
                        outcome = .result(.alreadyApplied(record))
                    case .conflict(let reason, let record):
                        outcome = .result(.conflict(reason, record))
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
                    if let error {
                        throw error
                    }
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
}

struct FirestoreClientWriteDTO: Encodable {
    let id: String
    let displayName: String
    @ExplicitNull var taxIdentifier: String?
    @ExplicitNull var billingAddress: BillingAddressDTO?
    let status: ClientStatusDTO
    @ExplicitNull var consentReference: String?
    let syncMetadata: FirestoreClientSyncWriteDTO

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case taxIdentifier
        case billingAddress
        case status
        case consentReference
        case syncMetadata = "_sync"
    }
}

extension FirestoreClientWriteDTO {
    init(_ operation: ClientPendingUpsert) {
        id = operation.client.id
        displayName = operation.client.displayName
        _taxIdentifier = ExplicitNull(
            wrappedValue: operation.client.taxIdentifier
        )
        _billingAddress = ExplicitNull(
            wrappedValue: operation.client.billingAddress
        )
        status = operation.client.status
        _consentReference = ExplicitNull(
            wrappedValue: operation.client.consentReference
        )
        syncMetadata = FirestoreClientSyncWriteDTO(
            revision: FieldValue.increment(Int64(1)),
            lastOperationID: operation.operationID.uuidString
        )
    }
}

struct FirestoreClientSyncWriteDTO: Encodable {
    let revision: FieldValue
    let lastOperationID: String
}

struct FirestoreClientDocumentDTO: Decodable {
    let id: String
    let displayName: String
    let taxIdentifier: String?
    let billingAddress: BillingAddressDTO?
    let status: ClientStatusDTO
    let consentReference: String?
    let syncMetadata: FirestoreClientSyncMetadataDTO?

    private enum CodingKeys: String, CodingKey {
        case id
        case displayName
        case taxIdentifier
        case billingAddress
        case status
        case consentReference
        case syncMetadata = "_sync"
    }

    /// Reconstructs a provider-neutral record after validating its route identity and metadata.
    func toRemoteRecord(documentID: String) throws -> ClientRemoteRecord {
        guard documentID == id else {
            throw clientDocumentDecodingError(
                codingPath: [ClientDocumentCodingKey.id],
                description: "The client identifier does not match its document path."
            )
        }
        let client = ClientDTO(
            id: id,
            displayName: displayName,
            taxIdentifier: taxIdentifier,
            billingAddress: billingAddress,
            status: status,
            consentReference: consentReference
        )
        guard let syncMetadata else {
            return ClientRemoteRecord(client: client, version: .legacy)
        }
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

        return ClientRemoteRecord(
            client: client,
            version: .versioned(
                revision: syncMetadata.revision,
                lastOperationID: operationID
            )
        )
    }
}

struct FirestoreClientSyncMetadataDTO: Decodable {
    let revision: Int64
    let lastOperationID: String
}

private enum FirestoreClientTransactionOutcome: Codable {
    case result(ClientRemoteUpsertResult)
    case invalid(ClientSyncPolicyError)
}

private enum ClientDocumentCodingKey: String, CodingKey {
    case id
    case syncMetadata = "_sync"
    case revision
    case lastOperationID
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

    if error is CancellationError {
        return CancellationError()
    }

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
