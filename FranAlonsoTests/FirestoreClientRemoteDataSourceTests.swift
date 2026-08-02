import FirebaseFirestore
import Foundation
import Testing
@testable import FranAlonso

@Suite("Firestore client remote data source")
struct FirestoreClientRemoteDataSourceTests {
    @Test(
        "Environments resolve Clients and sync metadata paths",
        arguments: [FirestoreEnvironment.develop, .production]
    )
    func environmentsResolveApprovedPaths(_ environment: FirestoreEnvironment) {
        #expect(
            environment.collectionPath(for: .clients)
                == "\(environment.rawValue)/collections/clients"
        )
        #expect(
            environment.syncMetadataDocumentPath(for: .clients)
                == "\(environment.rawValue)/collections/syncMetadata/clients"
        )
        #expect(
            environment.collectionPath(for: .products)
                == "\(environment.rawValue)/collections/products"
        )
        #expect(
            environment.syncMetadataDocumentPath(for: .products)
                == "\(environment.rawValue)/collections/syncMetadata/products"
        )
    }

    @Test("Bootstrap includes a legacy record and starts its cursor at zero")
    func bootstrapIncludesLegacyRecord() async throws {
        let expectedRecord = firestoreClientRecord()
        let dataSource = makeFirestoreDataSource(fetch: { cursor in
            #expect(cursor == nil)
            return [(documentID: expectedRecord.id, record: expectedRecord)]
        })

        #expect(
            try await dataSource.fetchChanges(after: nil)
                == ClientRemoteChangeBatch(
                    records: [expectedRecord],
                    nextCursor: ClientSyncCursor(changeSequence: 0)
                )
        )
    }

    @Test("Incremental fetch forwards its cursor and advances to the largest sequence")
    func incrementalFetchAdvancesCursor() async throws {
        let gate = FirestoreFetchGate(
            record: firestoreClientRecord(changeSequence: 6)
        )
        let dataSource = makeFirestoreDataSource(fetch: { cursor in
            await gate.fetch(after: cursor)
        })

        let batch = try await dataSource.fetchChanges(
            after: ClientSyncCursor(changeSequence: 4)
        )

        #expect(
            await gate.receivedCursors
                == [ClientSyncCursor(changeSequence: 4)]
        )
        #expect(batch.nextCursor == ClientSyncCursor(changeSequence: 6))
    }

    @Test("A mutation waits for its transaction acknowledgement")
    func mutationWaitsForTransactionAcknowledgement() async throws {
        let operation = ClientPendingOperation.upsert(firestorePendingUpsert())
        let gate = FirestoreTransactionGate()
        let dataSource = makeFirestoreDataSource(transact: { operation in
            await gate.transact(operation: operation)
        })
        let acknowledged = firestoreClientRecord(
            revision: 1,
            operationID: operation.operationID,
            changeSequence: 1
        )

        async let result = dataSource.apply(operation)
        await gate.waitUntilReceived()
        #expect(await gate.receivedOperations == [operation])
        await gate.acknowledge(.applied(acknowledged))

        #expect(try await result == .applied(acknowledged))
    }

    @Test("An invalid upsert identity is rejected before resolving its remote route")
    func invalidUpsertIdentityIsRejectedBeforeRemoteRoute() async {
        let valid = firestorePendingUpsert()
        let invalid = ClientPendingUpsert(
            clientID: valid.clientID,
            operationID: valid.operationID,
            predecessorOperationID: nil,
            base: .absent,
            client: ClientDTO(
                id: "invalid/remote/path",
                displayName: valid.client.displayName,
                taxIdentifier: nil,
                billingAddress: nil,
                status: .draft,
                consentReference: nil
            )
        )

        await #expect(throws: ClientSyncPolicyError.entityIdentityMismatch) {
            try await makeFirestoreDataSource().apply(.upsert(invalid))
        }
    }

    @Test("A live write contains business fields and authoritative sync metadata")
    func liveWriteContainsBusinessFieldsAndSyncMetadata() throws {
        let record = firestoreClientRecord(
            revision: 2,
            operationID: firestoreUUID(
                "57000000-0000-0000-0000-000000000002"
            ),
            changeSequence: 9
        )
        let fields = try Firestore.Encoder().encode(
            FirestoreClientWriteDTO(record)
        )

        #expect(fields["_deleted"] as? Bool == false)
        #expect(fields["displayName"] as? String == "Ana Alonso")
        #expect(fields["_sync"] != nil)
    }

    @Test("A tombstone write contains no client PII")
    func tombstoneWriteContainsNoClientPII() throws {
        let operationID = firestoreUUID(
            "57000000-0000-0000-0000-000000000003"
        )
        let record = ClientRemoteRecord(
            content: .tombstone(
                clientID: firestorePendingUpsert().clientID
            ),
            version: .versioned(
                revision: 3,
                lastOperationID: operationID
            ),
            changeSequence: 10
        )
        let fields = try Firestore.Encoder().encode(
            FirestoreClientWriteDTO(record)
        )

        #expect(fields["_deleted"] as? Bool == true)
        #expect(fields["displayName"] == nil)
        #expect(fields["taxIdentifier"] == nil)
        #expect(fields["billingAddress"] == nil)
        #expect(fields["status"] == nil)
        #expect(fields["consentReference"] == nil)
    }

    @Test("Counter progression fails closed for invalid and exhausted values")
    func counterProgressionFailsClosed() throws {
        #expect(
            try FirestoreClientRemoteDataSource.nextChangeSequence(after: nil)
                == 1
        )
        #expect(
            try FirestoreClientRemoteDataSource.nextChangeSequence(after: 8)
                == 9
        )
        #expect(throws: ClientSyncPolicyError.invalidChangeSequence) {
            try FirestoreClientRemoteDataSource.nextChangeSequence(after: -1)
        }
        #expect(throws: ClientSyncPolicyError.changeSequenceOverflow) {
            try FirestoreClientRemoteDataSource.nextChangeSequence(
                after: Int64.max
            )
        }
    }

    @Test("Transaction planning writes client and counter as one atomic pair")
    func transactionPlanningWritesClientAndCounterTogether() throws {
        let upsert = ClientPendingOperation.upsert(firestorePendingUpsert())
        let upsertPlan = try FirestoreClientRemoteDataSource.transactionPlan(
            for: upsert,
            against: nil,
            counter: .absent,
            policy: ClientSyncPolicy()
        )
        let upsertWrite = try #require(upsertPlan.atomicWrite)
        #expect(upsertWrite.record.isLive)
        #expect(upsertWrite.record.changeSequence == 1)
        #expect(upsertWrite.counter == FirestoreClientCounterDTO(changeSequence: 1))

        let delete = ClientPendingOperation.delete(
            ClientPendingDelete(
                clientID: upsert.clientID,
                operationID: firestoreUUID(
                    "57000000-0000-0000-0000-000000000004"
                ),
                predecessorOperationID: nil,
                base: .versioned(1)
            )
        )
        let liveRemote = firestoreClientRecord(
            revision: 1,
            operationID: upsert.operationID,
            changeSequence: 1
        )
        let deletePlan = try FirestoreClientRemoteDataSource.transactionPlan(
            for: delete,
            against: liveRemote,
            counter: .value(1),
            policy: ClientSyncPolicy()
        )
        let deleteWrite = try #require(deletePlan.atomicWrite)
        #expect(deleteWrite.record.isTombstone)
        #expect(deleteWrite.record.changeSequence == 2)
        #expect(deleteWrite.counter == FirestoreClientCounterDTO(changeSequence: 2))
    }

    @Test("Invalid counter states produce no transaction write plan")
    func invalidCounterStatesProduceNoWrites() {
        let operation = ClientPendingOperation.upsert(firestorePendingUpsert())

        for counter in [
            FirestoreClientCounterState.value(-1),
            .value(Int64.max),
            .malformed
        ] {
            #expect(throws: (any Error).self) {
                let plan = try FirestoreClientRemoteDataSource.transactionPlan(
                    for: operation,
                    against: nil,
                    counter: counter,
                    policy: ClientSyncPolicy()
                )
                #expect(plan.atomicWrite == nil)
            }
        }
    }

    @Test("Malformed counter and partial sync metadata remain decoding failures")
    func malformedMetadataRemainsDecodingFailure() {
        let partialClient = Data(
            #"{"id":"56000000-0000-0000-0000-000000000001","displayName":"Partial metadata","status":"draft","_sync":{"revision":1}}"#.utf8
        )
        let malformedCounter = Data(#"{"changeSequence":"nine"}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                FirestoreClientDocumentDTO.self,
                from: partialClient
            )
        }
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                FirestoreClientCounterDTO.self,
                from: malformedCounter
            )
        }
    }

    @Test("Fetch rejects a route identifier different from its payload")
    func fetchRejectsMismatchedRouteIdentity() async {
        let record = firestoreClientRecord()
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            [(documentID: "another-client", record: record)]
        })

        do {
            _ = try await dataSource.fetchChanges(after: nil)
            Issue.record("Expected the mismatched route identity to fail")
        } catch DecodingError.dataCorrupted(let context) {
            #expect(context.codingPath.map(\.stringValue) == ["id"])
        } catch {
            Issue.record("Unexpected fetch error: \(error)")
        }
    }

    @Test("An incremental batch rejects a document without change sequence")
    func incrementalBatchRejectsMissingSequence() async {
        let record = firestoreClientRecord()
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            [(documentID: record.id, record: record)]
        })

        await #expect(throws: ClientSyncPolicyError.invalidChangeSequence) {
            try await dataSource.fetchChanges(
                after: ClientSyncCursor(changeSequence: 1)
            )
        }
    }

    @Test("Provider errors and cancellation preserve their neutral meaning")
    func providerErrorsAndCancellationPreserveMeaning() async {
        let permissionDenied = makeFirestoreDataSource(fetch: { _ in
            throw firestoreError(code: 7)
        })
        let deadlineExceeded = makeFirestoreDataSource(fetch: { _ in
            throw firestoreError(code: 4)
        })
        let resourceExhausted = makeFirestoreDataSource(fetch: { _ in
            throw firestoreError(code: 8)
        })
        let aborted = makeFirestoreDataSource(fetch: { _ in
            throw firestoreError(code: 10)
        })
        let unavailable = makeFirestoreDataSource(fetch: { _ in
            throw firestoreError(code: 14)
        })
        let cancelled = makeFirestoreDataSource(fetch: { _ in
            throw CancellationError()
        })

        await #expect(throws: ClientRemoteDataSourceError.permissionDenied) {
            try await permissionDenied.fetchChanges(after: nil)
        }
        await #expect(throws: ClientRemoteDataSourceError.deadlineExceeded) {
            try await deadlineExceeded.fetchChanges(after: nil)
        }
        await #expect(throws: ClientRemoteDataSourceError.resourceExhausted) {
            try await resourceExhausted.fetchChanges(after: nil)
        }
        await #expect(throws: ClientRemoteDataSourceError.aborted) {
            try await aborted.fetchChanges(after: nil)
        }
        await #expect(throws: ClientRemoteDataSourceError.unavailable) {
            try await unavailable.fetchChanges(after: nil)
        }
        await #expect(throws: CancellationError.self) {
            try await cancelled.fetchChanges(after: nil)
        }
    }
}

private actor FirestoreFetchGate {
    private let record: ClientRemoteRecord
    private var cursors: [ClientSyncCursor?] = []

    init(record: ClientRemoteRecord) {
        self.record = record
    }

    var receivedCursors: [ClientSyncCursor?] { cursors }

    func fetch(after cursor: ClientSyncCursor?) -> [(documentID: String, record: ClientRemoteRecord)] {
        cursors.append(cursor)
        return [(documentID: record.id, record: record)]
    }
}

private actor FirestoreTransactionGate {
    private var operations: [ClientPendingOperation] = []
    private var receivedContinuations: [CheckedContinuation<Void, Never>] = []
    private var acknowledgementContinuation: CheckedContinuation<ClientRemoteMutationResult, Never>?

    var receivedOperations: [ClientPendingOperation] { operations }

    func transact(operation: ClientPendingOperation) async -> ClientRemoteMutationResult {
        operations.append(operation)
        receivedContinuations.forEach { $0.resume() }
        receivedContinuations.removeAll()
        return await withCheckedContinuation { continuation in
            acknowledgementContinuation = continuation
        }
    }

    func waitUntilReceived() async {
        guard operations.isEmpty else { return }
        await withCheckedContinuation { continuation in
            receivedContinuations.append(continuation)
        }
    }

    func acknowledge(_ result: ClientRemoteMutationResult) {
        acknowledgementContinuation?.resume(returning: result)
        acknowledgementContinuation = nil
    }
}

private func makeFirestoreDataSource(
    fetch: @escaping @Sendable (ClientSyncCursor?) async throws -> [
        (documentID: String, record: ClientRemoteRecord)
    ] = { _ in [] },
    transact: @escaping @Sendable (
        ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult = { operation in
        let content: ClientRemoteContent
        switch operation {
        case .upsert(let upsert): content = .live(upsert.client)
        case .delete(let delete):
            content = .tombstone(clientID: delete.clientID)
        }
        return .applied(
            ClientRemoteRecord(
                content: content,
                version: .versioned(
                    revision: 1,
                    lastOperationID: operation.operationID
                ),
                changeSequence: 1
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
        clientID: firestoreUUID(client.id),
        operationID: firestoreUUID(
            "57000000-0000-0000-0000-000000000001"
        ),
        predecessorOperationID: nil,
        base: .absent,
        client: client
    )
}

private func firestoreClientRecord(
    revision: Int64? = nil,
    operationID: UUID? = nil,
    changeSequence: Int64? = nil
) -> ClientRemoteRecord {
    let version: ClientRemoteVersion
    if let revision, let operationID {
        version = .versioned(
            revision: revision,
            lastOperationID: operationID
        )
    } else {
        version = .legacy
    }
    return ClientRemoteRecord(
        client: firestorePendingUpsert().client,
        version: version,
        changeSequence: changeSequence
    )
}

private func firestoreUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private func firestoreError(code: Int) -> NSError {
    NSError(domain: "FIRFirestoreErrorDomain", code: code)
}
