import FirebaseFirestore
import Foundation
import Testing
@testable import FranAlonso

@Suite("Firestore client remote data source")
struct FirestoreClientRemoteDataSourceTests {
    @Test(
        "Environments resolve the approved Clients collection paths",
        arguments: [FirestoreEnvironment.develop, .production]
    )
    func environmentsResolveApprovedClientsCollectionPaths(
        _ environment: FirestoreEnvironment
    ) {
        switch environment {
        case .develop:
            #expect(
                FirestoreClientRemoteDataSource.collectionPath(in: environment)
                    == "develop/collections/clients"
            )
        case .production:
            #expect(
                FirestoreClientRemoteDataSource.collectionPath(in: environment)
                    == "production/collections/clients"
            )
        }
    }

    @Test("Fetch returns records whose route identity matches the payload")
    func fetchReturnsRecordsWhoseRouteIdentityMatchesPayload() async throws {
        let expectedRecord = firestoreClientRecord()
        let dataSource = makeFirestoreDataSource {
            [(documentID: expectedRecord.client.id, record: expectedRecord)]
        }

        #expect(try await dataSource.fetchAll() == [expectedRecord])
    }

    @Test("Upsert requests a merged transaction and waits for acknowledgement")
    func upsertRequestsMergedTransactionAndWaitsForAcknowledgement() async throws {
        let operation = firestorePendingUpsert()
        let gate = FirestoreTransactionGate()
        let dataSource = makeFirestoreDataSource(
            transact: { receivedOperation, merge in
                await gate.transact(operation: receivedOperation, merge: merge)
            }
        )

        async let result = dataSource.upsert(operation)
        await gate.waitUntilReceived()

        #expect(
            await gate.receivedTransactions == [
                FirestoreTransactionRequest(
                    operation: operation,
                    merge: true
                )
            ]
        )
        await gate.acknowledge(
            .applied(
                ClientRemoteRecord(
                    client: operation.client,
                    version: .versioned(
                        revision: 1,
                        lastOperationID: operation.operationID
                    )
                )
            )
        )

        #expect(
            try await result == .applied(
                ClientRemoteRecord(
                    client: operation.client,
                    version: .versioned(
                        revision: 1,
                        lastOperationID: operation.operationID
                    )
                )
            )
        )
    }

    @Test("Upsert rejects an invalid payload identity before resolving its remote route")
    func upsertRejectsInvalidPayloadIdentityBeforeResolvingRemoteRoute() async {
        let validOperation = firestorePendingUpsert()
        let invalidOperation = ClientPendingUpsert(
            clientID: validOperation.clientID,
            operationID: validOperation.operationID,
            predecessorOperationID: nil,
            base: .absent,
            client: ClientDTO(
                id: "invalid/remote/path",
                displayName: validOperation.client.displayName,
                taxIdentifier: nil,
                billingAddress: nil,
                status: .draft,
                consentReference: nil
            )
        )
        let dataSource = makeFirestoreDataSource(
            transact: { _, _ in
                throw ClientRemoteDataSourceError.unexpected
            }
        )

        await #expect(throws: ClientSyncPolicyError.entityIdentityMismatch) {
            try await dataSource.upsert(invalidOperation)
        }
    }

    @Test("Provider encoding writes explicit nulls and a server revision transform")
    func providerEncodingWritesExplicitNullsAndServerRevisionTransform() throws {
        let operation = firestorePendingUpsert()
        let writeDTO = FirestoreClientWriteDTO(operation)
        let fields = try Firestore.Encoder().encode(writeDTO)

        #expect(fields["taxIdentifier"] is NSNull)
        #expect(fields["billingAddress"] is NSNull)
        #expect(fields["consentReference"] is NSNull)
        #expect(fields["_sync"] != nil)
        #expect(
            writeDTO.syncMetadata.lastOperationID
                == operation.operationID.uuidString
        )
    }

    @Test("Partial sync metadata is invalid rather than legacy")
    func partialSyncMetadataIsInvalidRatherThanLegacy() {
        let payload = Data(
            #"{"id":"56000000-0000-0000-0000-000000000001","displayName":"Partial metadata","status":"draft","_sync":{"revision":1}}"#.utf8
        )

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                FirestoreClientDocumentDTO.self,
                from: payload
            )
        }
    }

    @Test("Fetch rejects a route identifier that differs from the payload identifier")
    func fetchRejectsRouteIdentifierDifferentFromPayloadIdentifier() async {
        let record = firestoreClientRecord()
        let dataSource = makeFirestoreDataSource {
            [(documentID: "another-client", record: record)]
        }

        do {
            _ = try await dataSource.fetchAll()
            Issue.record("Expected the mismatched route identity to fail")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["id"])
        } catch {
            Issue.record("Unexpected fetch error: \(error)")
        }
    }

    @Test("Permission denied is mapped to the provider-neutral error")
    func permissionDeniedIsMappedToProviderNeutralError() async {
        let dataSource = makeFirestoreDataSource {
            throw firestoreError(code: 7)
        }

        await #expect(throws: ClientRemoteDataSourceError.permissionDenied) {
            try await dataSource.fetchAll()
        }
    }

    @Test("Unavailable is mapped to the provider-neutral error")
    func unavailableIsMappedToProviderNeutralError() async {
        let dataSource = makeFirestoreDataSource {
            throw firestoreError(code: 14)
        }

        await #expect(throws: ClientRemoteDataSourceError.unavailable) {
            try await dataSource.fetchAll()
        }
    }

    @Test("Native task cancellation remains cancellation")
    func nativeTaskCancellationRemainsCancellation() async {
        let dataSource = makeFirestoreDataSource {
            throw CancellationError()
        }

        await #expect(throws: CancellationError.self) {
            try await dataSource.fetchAll()
        }
    }
}

private struct FirestoreTransactionRequest: Equatable {
    let operation: ClientPendingUpsert
    let merge: Bool
}

private actor FirestoreTransactionGate {
    private var transactions: [FirestoreTransactionRequest] = []
    private var receivedContinuations: [CheckedContinuation<Void, Never>] = []
    private var acknowledgementContinuation: CheckedContinuation<
        ClientRemoteUpsertResult,
        Never
    >?

    var receivedTransactions: [FirestoreTransactionRequest] { transactions }

    func transact(
        operation: ClientPendingUpsert,
        merge: Bool
    ) async -> ClientRemoteUpsertResult {
        transactions.append(
            FirestoreTransactionRequest(operation: operation, merge: merge)
        )
        receivedContinuations.forEach { $0.resume() }
        receivedContinuations.removeAll()
        return await withCheckedContinuation { continuation in
            acknowledgementContinuation = continuation
        }
    }

    func waitUntilReceived() async {
        guard transactions.isEmpty else {
            return
        }
        await withCheckedContinuation { continuation in
            receivedContinuations.append(continuation)
        }
    }

    func acknowledge(_ result: ClientRemoteUpsertResult) {
        acknowledgementContinuation?.resume(returning: result)
        acknowledgementContinuation = nil
    }
}

private func makeFirestoreDataSource(
    fetch: @escaping @Sendable () async throws -> [
        (documentID: String, record: ClientRemoteRecord)
    ] = { [] },
    transact: @escaping @Sendable (
        ClientPendingUpsert,
        Bool
    ) async throws -> ClientRemoteUpsertResult = { operation, _ in
        .applied(
            ClientRemoteRecord(
                client: operation.client,
                version: .versioned(
                    revision: 1,
                    lastOperationID: operation.operationID
                )
            )
        )
    }
) -> FirestoreClientRemoteDataSource {
    FirestoreClientRemoteDataSource(fetch: fetch, transact: transact)
}

private func firestorePendingUpsert() -> ClientPendingUpsert {
    let client = ClientDTO(
        id: "56000000-0000-0000-0000-000000000001",
        displayName: "Ana Alonso",
        taxIdentifier: nil,
        billingAddress: nil,
        status: .draft,
        consentReference: nil
    )
    return ClientPendingUpsert(
        clientID: UUID(uuidString: client.id)!,
        operationID: UUID(
            uuidString: "57000000-0000-0000-0000-000000000001"
        )!,
        predecessorOperationID: nil,
        base: .absent,
        client: client
    )
}

private func firestoreClientRecord() -> ClientRemoteRecord {
    ClientRemoteRecord(
        client: firestorePendingUpsert().client,
        version: .legacy
    )
}

private func firestoreError(code: Int) -> NSError {
    NSError(domain: "FIRFirestoreErrorDomain", code: code)
}
