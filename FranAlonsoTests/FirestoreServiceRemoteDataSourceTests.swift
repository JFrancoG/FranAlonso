import FirebaseFirestore
import Foundation
import Testing
@testable import FranAlonso

@Suite("Firestore Service remote data source")
struct FirestoreServiceRemoteDataSourceTests {
    @Test(
        "Environments resolve Services and sync metadata paths",
        arguments: [FirestoreEnvironment.develop, .production]
    )
    func environmentsResolveApprovedPaths(_ environment: FirestoreEnvironment) {
        #expect(
            environment.collectionPath(for: .services)
                == "\(environment.rawValue)/collections/services"
        )
        #expect(
            environment.syncMetadataDocumentPath(for: .services)
                == "\(environment.rawValue)/collections/syncMetadata/services"
        )
    }

    @Test("Bootstrap includes legacy records and starts its cursor at zero")
    func bootstrapIncludesLegacyRecord() async throws {
        let expectedRecord = try firestoreServiceRecord()
        let dataSource = makeFirestoreDataSource(fetch: { cursor in
            #expect(cursor == nil)
            return [(documentID: expectedRecord.id, record: expectedRecord)]
        })

        #expect(
            try await dataSource.fetchChanges(after: nil)
                == ServiceRemoteChangeBatch(
                    records: [expectedRecord],
                    nextCursor: ServiceSyncCursor(changeSequence: 0)
                )
        )
    }

    @Test("Incremental fetch forwards its cursor and advances to the largest sequence")
    func incrementalFetchAdvancesToLargestSequence() async throws {
        let records = [
            try firestoreServiceRecord(changeSequence: 6),
            try firestoreServiceRecord(
                serviceID: firestoreUUID(
                    "58000000-0000-0000-0000-000000000002"
                ),
                changeSequence: 9
            )
        ]
        let gate = FirestoreServiceFetchGate(records: records)
        let dataSource = makeFirestoreDataSource(fetch: { cursor in
            await gate.fetch(after: cursor)
        })

        let batch = try await dataSource.fetchChanges(
            after: ServiceSyncCursor(changeSequence: 4)
        )

        #expect(
            await gate.receivedCursors
                == [ServiceSyncCursor(changeSequence: 4)]
        )
        #expect(batch.records == records)
        #expect(batch.nextCursor == ServiceSyncCursor(changeSequence: 9))
    }

    @Test("A mutation waits for its transaction acknowledgement")
    func mutationWaitsForTransactionAcknowledgement() async throws {
        let operation = ServicePendingOperation.upsert(
            try firestorePendingUpsert()
        )
        let gate = FirestoreServiceTransactionGate()
        let dataSource = makeFirestoreDataSource(transact: { operation in
            await gate.transact(operation: operation)
        })
        let acknowledged = try firestoreServiceRecord(
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
    func invalidUpsertIdentityIsRejectedBeforeRemoteRoute() async throws {
        let valid = try firestorePendingUpsert()
        let invalid = ServicePendingUpsert(
            serviceID: valid.serviceID,
            operationID: valid.operationID,
            predecessorOperationID: nil,
            base: .absent,
            service: ServiceDTO(
                id: "invalid/remote/path",
                name: valid.service.name,
                type: valid.service.type,
                linkedProductID: valid.service.linkedProductID,
                price: valid.service.price,
                taxRate: valid.service.taxRate,
                discount: valid.service.discount,
                status: valid.service.status
            )
        )

        await #expect(throws: ServiceSyncPolicyError.entityIdentityMismatch) {
            try await makeFirestoreDataSource().apply(.upsert(invalid))
        }
    }

    @Test("A live write contains the complete nested Service snapshot and sync metadata")
    func liveWriteContainsCompleteBusinessSnapshot() throws {
        let linkedProductID = firestoreUUID(
            "59000000-0000-0000-0000-000000000001"
        )
        let record = try firestoreServiceRecord(
            type: .product,
            linkedProductID: linkedProductID,
            revision: 2,
            operationID: firestoreUUID(
                "5A000000-0000-0000-0000-000000000002"
            ),
            changeSequence: 9
        )

        let fields = try Firestore.Encoder().encode(
            FirestoreServiceWriteDTO(record)
        )
        let price = try #require(fields["price"] as? [String: Any])
        let taxRate = try #require(fields["taxRate"] as? [String: Any])
        let discount = try #require(fields["discount"] as? [String: Any])
        let sync = try #require(fields["_sync"] as? [String: Any])

        #expect(fields["id"] as? String == record.id)
        #expect(fields["_deleted"] as? Bool == false)
        #expect(fields["name"] as? String == "Corte y peinado")
        #expect(fields["type"] as? String == "product")
        #expect(fields["linkedProductID"] as? String == linkedProductID.uuidString)
        #expect(price["amount"] as? String == "29.95")
        #expect(price["currency"] as? String == "EUR")
        #expect(taxRate["percentage"] as? String == "21")
        #expect(discount["percentage"] as? String == "10")
        #expect(fields["status"] as? String == "active")
        #expect(sync["revision"] as? Int64 == 2)
        #expect(
            sync["lastOperationID"] as? String
                == "5A000000-0000-0000-0000-000000000002"
        )
        #expect(sync["changeSequence"] as? Int64 == 9)
    }

    @Test("A complete live document reconstructs the exact nested Service snapshot")
    func completeLiveDocumentReconstructsNestedSnapshot() throws {
        let serviceID = firestoreUUID(
            "58000000-0000-0000-0000-000000000001"
        )
        let linkedProductID = firestoreUUID(
            "59000000-0000-0000-0000-000000000001"
        )
        let operationID = firestoreUUID(
            "5A000000-0000-0000-0000-000000000002"
        )
        let payload = Data(
            #"{"id":"58000000-0000-0000-0000-000000000001","_deleted":false,"name":"Corte y peinado","type":"product","linkedProductID":"59000000-0000-0000-0000-000000000001","price":{"amount":"29.95","currency":"EUR"},"taxRate":{"percentage":"21"},"discount":{"percentage":"10"},"status":"active","_sync":{"revision":2,"lastOperationID":"5A000000-0000-0000-0000-000000000002","changeSequence":9}}"#.utf8
        )

        let document = try JSONDecoder().decode(
            FirestoreServiceDocumentDTO.self,
            from: payload
        )

        #expect(
            try document.toRemoteRecord(documentID: serviceID.uuidString)
                == firestoreServiceRecord(
                    serviceID: serviceID,
                    type: .product,
                    linkedProductID: linkedProductID,
                    revision: 2,
                    operationID: operationID,
                    changeSequence: 9
                )
        )
    }

    @Test("A full-replacement live projection omits stale optional fields")
    func fullReplacementProjectionOmitsStaleOptionalFields() throws {
        let record = try firestoreServiceRecord(
            discountPercentage: nil,
            revision: 2,
            operationID: firestoreUUID(
                "5A000000-0000-0000-0000-000000000003"
            ),
            changeSequence: 10
        )

        let fields = try Firestore.Encoder().encode(
            FirestoreServiceWriteDTO(record)
        )

        #expect(fields["type"] as? String == "professional")
        #expect(fields["linkedProductID"] == nil)
        #expect(fields["discount"] == nil)
        #expect(
            Set(fields.keys) == [
                "id", "_deleted", "name", "type", "price", "taxRate",
                "status", "_sync"
            ]
        )
    }

    @Test("A tombstone write contains no Service business fields")
    func tombstoneWriteContainsNoServiceBusinessFields() throws {
        let operationID = firestoreUUID(
            "5A000000-0000-0000-0000-000000000004"
        )
        let record = ServiceRemoteRecord(
            content: .tombstone(
                serviceID: try firestorePendingUpsert().serviceID
            ),
            version: .versioned(
                revision: 3,
                lastOperationID: operationID
            ),
            changeSequence: 11
        )

        let fields = try Firestore.Encoder().encode(
            FirestoreServiceWriteDTO(record)
        )

        #expect(fields["_deleted"] as? Bool == true)
        for businessKey in [
            "name", "type", "linkedProductID", "price", "taxRate",
            "discount", "status"
        ] {
            #expect(fields[businessKey] == nil)
        }
    }

    @Test("Counter progression rejects negative and exhausted values")
    func counterProgressionFailsClosed() throws {
        #expect(
            try FirestoreServiceRemoteDataSource.nextChangeSequence(after: nil)
                == 1
        )
        #expect(
            try FirestoreServiceRemoteDataSource.nextChangeSequence(after: 8)
                == 9
        )
        #expect(throws: ServiceSyncPolicyError.invalidChangeSequence) {
            try FirestoreServiceRemoteDataSource.nextChangeSequence(after: -1)
        }
        #expect(throws: ServiceSyncPolicyError.changeSequenceOverflow) {
            try FirestoreServiceRemoteDataSource.nextChangeSequence(
                after: Int64.max
            )
        }
    }

    @Test("Transaction planning emits one atomic Service-and-counter pair")
    func transactionPlanningWritesServiceAndCounterTogether() throws {
        let upsert = ServicePendingOperation.upsert(
            try firestorePendingUpsert()
        )
        let upsertPlan = try FirestoreServiceRemoteDataSource.transactionPlan(
            for: upsert,
            against: nil,
            counter: .absent,
            policy: ServiceSyncPolicy()
        )
        let upsertWrite = try #require(upsertPlan.atomicWrite)
        #expect(upsertWrite.record.isLive)
        #expect(upsertWrite.record.changeSequence == 1)
        #expect(
            upsertWrite.counter
                == FirestoreServiceCounterDTO(changeSequence: 1)
        )

        let delete = ServicePendingOperation.delete(
            ServicePendingDelete(
                serviceID: upsert.serviceID,
                operationID: firestoreUUID(
                    "5A000000-0000-0000-0000-000000000005"
                ),
                predecessorOperationID: nil,
                base: .versioned(1)
            )
        )
        let liveRemote = try firestoreServiceRecord(
            revision: 1,
            operationID: upsert.operationID,
            changeSequence: 1
        )
        let deletePlan = try FirestoreServiceRemoteDataSource.transactionPlan(
            for: delete,
            against: liveRemote,
            counter: .value(1),
            policy: ServiceSyncPolicy()
        )
        let deleteWrite = try #require(deletePlan.atomicWrite)
        #expect(deleteWrite.record.isTombstone)
        #expect(deleteWrite.record.changeSequence == 2)
        #expect(
            deleteWrite.counter
                == FirestoreServiceCounterDTO(changeSequence: 2)
        )
    }

    @Test("Invalid counter states produce no transaction write plan")
    func invalidCounterStatesProduceNoWrites() throws {
        let operation = ServicePendingOperation.upsert(
            try firestorePendingUpsert()
        )

        for counter in [
            FirestoreServiceCounterState.value(-1),
            .value(Int64.max),
            .malformed
        ] {
            #expect(throws: (any Error).self) {
                let plan = try FirestoreServiceRemoteDataSource.transactionPlan(
                    for: operation,
                    against: nil,
                    counter: counter,
                    policy: ServiceSyncPolicy()
                )
                #expect(plan.atomicWrite == nil)
            }
        }
    }

    @Test("Malformed counter and partial sync metadata remain decoding failures")
    func malformedMetadataRemainsDecodingFailure() {
        let partialService = Data(
            #"{"id":"58000000-0000-0000-0000-000000000001","name":"Partial metadata","type":"professional","price":{"amount":"29.95","currency":"EUR"},"taxRate":{"percentage":"21"},"status":"active","_sync":{"revision":1}}"#.utf8
        )
        let malformedCounter = Data(#"{"changeSequence":"nine"}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                FirestoreServiceDocumentDTO.self,
                from: partialService
            )
        }
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                FirestoreServiceCounterDTO.self,
                from: malformedCounter
            )
        }
    }

    @Test("Fetch rejects a route identifier different from its payload")
    func fetchRejectsMismatchedRouteIdentity() async throws {
        let record = try firestoreServiceRecord()
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            [(documentID: "another-service", record: record)]
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
    func incrementalBatchRejectsMissingSequence() async throws {
        let record = try firestoreServiceRecord()
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            [(documentID: record.id, record: record)]
        })

        await #expect(throws: ServiceSyncPolicyError.invalidChangeSequence) {
            try await dataSource.fetchChanges(
                after: ServiceSyncCursor(changeSequence: 1)
            )
        }
    }

    @Test(
        "Firestore provider errors map to stable Service transport errors",
        arguments: firestoreProviderFailureFixtures
    )
    fileprivate func providerErrorsPreserveStableMeaning(_ fixture: FirestoreProviderFailureFixture) async {
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            throw firestoreError(code: fixture.code)
        })

        do {
            _ = try await dataSource.fetchChanges(after: nil)
            Issue.record("Expected provider error \(fixture.code)")
        } catch let error as ServiceRemoteDataSourceError {
            #expect(error == fixture.expected)
        } catch {
            Issue.record("Unexpected mapped error: \(error)")
        }
    }

    @Test("Unknown provider failures map to the stable unexpected error")
    func unknownProviderFailureMapsToUnexpected() async {
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            throw firestoreError(code: 999)
        })

        await #expect(throws: ServiceRemoteDataSourceError.unexpected) {
            try await dataSource.fetchChanges(after: nil)
        }
    }

    @Test("Cancellation remains cancellation across the Firestore boundary")
    func cancellationPreservesMeaning() async {
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            throw CancellationError()
        })

        await #expect(throws: CancellationError.self) {
            try await dataSource.fetchChanges(after: nil)
        }
    }

    @Test("Firestore cancellation also becomes structured cancellation")
    func providerCancellationBecomesStructuredCancellation() async {
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            throw firestoreError(code: 1)
        })

        await #expect(throws: CancellationError.self) {
            try await dataSource.fetchChanges(after: nil)
        }
    }
}

private actor FirestoreServiceFetchGate {
    private let records: [ServiceRemoteRecord]
    private var cursors: [ServiceSyncCursor?] = []

    init(records: [ServiceRemoteRecord]) {
        self.records = records
    }

    var receivedCursors: [ServiceSyncCursor?] { cursors }

    func fetch(after cursor: ServiceSyncCursor?) -> [(documentID: String, record: ServiceRemoteRecord)] {
        cursors.append(cursor)
        return records.map { (documentID: $0.id, record: $0) }
    }
}

private actor FirestoreServiceTransactionGate {
    private var operations: [ServicePendingOperation] = []
    private var receivedContinuations: [CheckedContinuation<Void, Never>] = []
    private var acknowledgementContinuation: CheckedContinuation<ServiceRemoteMutationResult, Never>?

    var receivedOperations: [ServicePendingOperation] { operations }

    func transact(operation: ServicePendingOperation) async -> ServiceRemoteMutationResult {
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

    func acknowledge(_ result: ServiceRemoteMutationResult) {
        acknowledgementContinuation?.resume(returning: result)
        acknowledgementContinuation = nil
    }
}

private struct FirestoreProviderFailureFixture: Sendable,
    CustomTestStringConvertible {
    let code: Int
    let expected: ServiceRemoteDataSourceError

    var testDescription: String { "Firestore error \(code)" }
}

private let firestoreProviderFailureFixtures = [
    FirestoreProviderFailureFixture(code: 7, expected: .permissionDenied),
    FirestoreProviderFailureFixture(code: 4, expected: .deadlineExceeded),
    FirestoreProviderFailureFixture(code: 8, expected: .resourceExhausted),
    FirestoreProviderFailureFixture(code: 10, expected: .aborted),
    FirestoreProviderFailureFixture(code: 14, expected: .unavailable)
]

private func makeFirestoreDataSource(
    fetch: @escaping @Sendable (ServiceSyncCursor?) async throws -> [
        (documentID: String, record: ServiceRemoteRecord)
    ] = { _ in [] },
    transact: @escaping @Sendable (
        ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult = { operation in
        let content: ServiceRemoteContent
        switch operation {
        case .upsert(let upsert):
            content = .live(upsert.service)
        case .delete(let delete):
            content = .tombstone(serviceID: delete.serviceID)
        }
        return .applied(
            ServiceRemoteRecord(
                content: content,
                version: .versioned(
                    revision: 1,
                    lastOperationID: operation.operationID
                ),
                changeSequence: 1
            )
        )
    }
) -> FirestoreServiceRemoteDataSource {
    FirestoreServiceRemoteDataSource(fetch: fetch, transact: transact)
}

private func firestorePendingUpsert() throws -> ServicePendingUpsert {
    let service = try firestoreServiceDTO()
    return ServicePendingUpsert(
        serviceID: firestoreUUID(service.id),
        operationID: firestoreUUID(
            "5A000000-0000-0000-0000-000000000001"
        ),
        predecessorOperationID: nil,
        base: .absent,
        service: service
    )
}

private func firestoreServiceRecord(
    serviceID: UUID = firestoreUUID("58000000-0000-0000-0000-000000000001"),
    type: ServiceType = .professional,
    linkedProductID: UUID? = nil,
    discountPercentage: Decimal? = 10,
    revision: Int64? = nil,
    operationID: UUID? = nil,
    changeSequence: Int64? = nil
) throws -> ServiceRemoteRecord {
    let version: ServiceRemoteVersion
    if let revision, let operationID {
        version = .versioned(
            revision: revision,
            lastOperationID: operationID
        )
    } else {
        version = .legacy
    }
    return ServiceRemoteRecord(
        service: try firestoreServiceDTO(
            serviceID: serviceID,
            type: type,
            linkedProductID: linkedProductID,
            discountPercentage: discountPercentage
        ),
        version: version,
        changeSequence: changeSequence
    )
}

private func firestoreServiceDTO(
    serviceID: UUID = firestoreUUID("58000000-0000-0000-0000-000000000001"),
    type: ServiceType = .professional,
    linkedProductID: UUID? = nil,
    discountPercentage: Decimal? = 10
) throws -> ServiceDTO {
    try makeServiceDTO(
        id: serviceID,
        type: type,
        linkedProductID: linkedProductID,
        discountPercentage: discountPercentage
    )
}

private func firestoreUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private func firestoreError(code: Int) -> NSError {
    NSError(domain: "FIRFirestoreErrorDomain", code: code)
}
