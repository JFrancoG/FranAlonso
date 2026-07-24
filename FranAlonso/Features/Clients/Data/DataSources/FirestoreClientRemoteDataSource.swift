import FirebaseFirestore

/// Adapts Firestore Clients documents to the provider-neutral remote contract.
struct FirestoreClientRemoteDataSource: ClientRemoteDataSource {
    private let fetchDocuments: @Sendable () async throws -> [
        (documentID: String, payload: ClientDTO)
    ]
    private let writeDocument: @Sendable (String, ClientDTO) async throws -> Void

    func fetchAll() async throws -> [ClientDTO] {
        do {
            return try await fetchDocuments().map { document in
                guard document.documentID == document.payload.id else {
                    throw DecodingError.dataCorrupted(
                        DecodingError.Context(
                            codingPath: [ClientDocumentCodingKey.id],
                            debugDescription: "The client identifier does not match its document path."
                        )
                    )
                }

                return document.payload
            }
        } catch {
            throw mapFirestoreError(error)
        }
    }

    func upsert(_ client: ClientDTO) async throws {
        do {
            try await writeDocument(client.id, client)
        } catch {
            throw mapFirestoreError(error)
        }
    }
}

extension FirestoreClientRemoteDataSource {
    init(
        fetch: @escaping @Sendable () async throws -> [
            (documentID: String, payload: ClientDTO)
        ],
        write: @escaping @Sendable (String, ClientDTO) async throws -> Void
    ) {
        fetchDocuments = fetch
        writeDocument = write
    }

    /// Creates the adapter for the Clients collection in an explicitly selected environment.
    ///
    /// - Parameters:
    ///   - firestore: The configured Firestore database instance.
    ///   - environment: The namespace that owns the Clients collection.
    init(firestore: Firestore, environment: FirestoreEnvironment) {
        self.init(
            collection: firestore.collection(Self.collectionPath(in: environment))
        )
    }

    /// Returns the Clients collection path for an explicitly selected environment.
    static func collectionPath(in environment: FirestoreEnvironment) -> String {
        "\(environment.rawValue)/collections/clients"
    }

    private init(collection: CollectionReference) {
        self.init(
            fetch: {
                let snapshot = try await collection.getDocuments(source: .server)

                return try snapshot.documents.map { document in
                    (
                        documentID: document.documentID,
                        payload: try document.data(as: ClientDTO.self)
                    )
                }
            },
            write: { documentID, payload in
                let document = collection.document(documentID)

                try await withCheckedThrowingContinuation {
                    (continuation: CheckedContinuation<Void, any Error>) in
                    do {
                        try document.setData(from: payload) { error in
                            if let error {
                                continuation.resume(throwing: error)
                            } else {
                                continuation.resume()
                            }
                        }
                    } catch {
                        continuation.resume(throwing: error)
                    }
                }
            }
        )
    }
}

private enum ClientDocumentCodingKey: String, CodingKey {
    case id
}

private func mapFirestoreError(_ error: any Error) -> any Error {
    if let decodingError = error as? DecodingError {
        return decodingError
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
