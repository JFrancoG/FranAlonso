import FirebaseFirestore
import Foundation
import Testing
@testable import FranAlonso

@Suite("Firestore product remote data source")
struct FirestoreProductRemoteDataSourceTests {
    @Test(
        "Environments resolve Products and sync metadata paths",
        arguments: [FirestoreEnvironment.develop, .production]
    )
    func environmentsResolveApprovedPaths(_ environment: FirestoreEnvironment) {
        #expect(
            environment.collectionPath(for: .products)
                == "\(environment.rawValue)/collections/products"
        )
        #expect(
            environment.syncMetadataDocumentPath(for: .products)
                == "\(environment.rawValue)/collections/syncMetadata/products"
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
        let expectedRecord = firestoreProductRecord()
        let dataSource = makeFirestoreDataSource(fetch: { cursor in
            #expect(cursor == nil)
            return [(documentID: expectedRecord.id, record: expectedRecord)]
        })

        #expect(
            try await dataSource.fetchChanges(after: nil)
                == ProductRemoteChangeBatch(
                    records: [expectedRecord],
                    nextCursor: ProductSyncCursor(changeSequence: 0)
                )
        )
    }

    @Test("Incremental fetch forwards its cursor and advances to the largest sequence")
    func incrementalFetchAdvancesCursor() async throws {
        let gate = FirestoreFetchGate(
            record: firestoreProductRecord(changeSequence: 6)
        )
        let dataSource = makeFirestoreDataSource(fetch: { cursor in
            await gate.fetch(after: cursor)
        })

        let batch = try await dataSource.fetchChanges(
            after: ProductSyncCursor(changeSequence: 4)
        )

        #expect(
            await gate.receivedCursors
                == [ProductSyncCursor(changeSequence: 4)]
        )
        #expect(batch.nextCursor == ProductSyncCursor(changeSequence: 6))
    }

    @Test("A mutation waits for its transaction acknowledgement")
    func mutationWaitsForTransactionAcknowledgement() async throws {
        let operation = ProductPendingOperation.upsert(firestorePendingUpsert())
        let gate = FirestoreTransactionGate()
        let dataSource = makeFirestoreDataSource(transact: { operation in
            await gate.transact(operation: operation)
        })
        let acknowledged = firestoreProductRecord(
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
        let invalid = ProductPendingUpsert(
            productID: valid.productID,
            operationID: valid.operationID,
            predecessorOperationID: nil,
            base: .absent,
            product: ProductDTO(
                id: "invalid/remote/path",
                name: valid.product.name,
                status: .active
            )
        )

        await #expect(throws: ProductSyncPolicyError.entityIdentityMismatch) {
            try await makeFirestoreDataSource().apply(.upsert(invalid))
        }
    }

    @Test("A live write contains business fields and authoritative sync metadata")
    func liveWriteContainsBusinessFieldsAndSyncMetadata() throws {
        let record = firestoreProductRecord(
            revision: 2,
            operationID: firestoreUUID(
                "57000000-0000-0000-0000-000000000002"
            ),
            changeSequence: 9
        )
        let fields = try Firestore.Encoder().encode(
            FirestoreProductWriteDTO(record)
        )

        #expect(fields["_deleted"] as? Bool == false)
        #expect(fields["name"] as? String == "Ana Alonso")
        #expect(fields["_sync"] != nil)
    }

    @Test("A tombstone write contains no Product business fields")
    func tombstoneWriteContainsNoProductBusinessFields() throws {
        let operationID = firestoreUUID(
            "57000000-0000-0000-0000-000000000003"
        )
        let record = ProductRemoteRecord(
            content: .tombstone(
                productID: firestorePendingUpsert().productID
            ),
            version: .versioned(
                revision: 3,
                lastOperationID: operationID
            ),
            changeSequence: 10
        )
        let fields = try Firestore.Encoder().encode(
            FirestoreProductWriteDTO(record)
        )

        #expect(fields["_deleted"] as? Bool == true)
        #expect(fields["name"] == nil)
        #expect(fields["status"] == nil)
    }

    @Test("Counter progression fails closed for invalid and exhausted values")
    func counterProgressionFailsClosed() throws {
        #expect(
            try FirestoreProductRemoteDataSource.nextChangeSequence(after: nil)
                == 1
        )
        #expect(
            try FirestoreProductRemoteDataSource.nextChangeSequence(after: 8)
                == 9
        )
        #expect(throws: ProductSyncPolicyError.invalidChangeSequence) {
            try FirestoreProductRemoteDataSource.nextChangeSequence(after: -1)
        }
        #expect(throws: ProductSyncPolicyError.changeSequenceOverflow) {
            try FirestoreProductRemoteDataSource.nextChangeSequence(
                after: Int64.max
            )
        }
    }

    @Test("Transaction planning writes product and counter as one atomic pair")
    func transactionPlanningWritesProductAndCounterTogether() throws {
        let upsert = ProductPendingOperation.upsert(firestorePendingUpsert())
        let upsertPlan = try FirestoreProductRemoteDataSource.transactionPlan(
            for: upsert,
            against: nil,
            counter: .absent,
            policy: ProductSyncPolicy()
        )
        let upsertWrite = try #require(upsertPlan.atomicWrite)
        #expect(upsertWrite.record.isLive)
        #expect(upsertWrite.record.changeSequence == 1)
        #expect(upsertWrite.counter == FirestoreProductCounterDTO(changeSequence: 1))

        let delete = ProductPendingOperation.delete(
            ProductPendingDelete(
                productID: upsert.productID,
                operationID: firestoreUUID(
                    "57000000-0000-0000-0000-000000000004"
                ),
                predecessorOperationID: nil,
                base: .versioned(1)
            )
        )
        let liveRemote = firestoreProductRecord(
            revision: 1,
            operationID: upsert.operationID,
            changeSequence: 1
        )
        let deletePlan = try FirestoreProductRemoteDataSource.transactionPlan(
            for: delete,
            against: liveRemote,
            counter: .value(1),
            policy: ProductSyncPolicy()
        )
        let deleteWrite = try #require(deletePlan.atomicWrite)
        #expect(deleteWrite.record.isTombstone)
        #expect(deleteWrite.record.changeSequence == 2)
        #expect(deleteWrite.counter == FirestoreProductCounterDTO(changeSequence: 2))
    }

    @Test("Invalid counter states produce no transaction write plan")
    func invalidCounterStatesProduceNoWrites() {
        let operation = ProductPendingOperation.upsert(firestorePendingUpsert())

        for counter in [
            FirestoreProductCounterState.value(-1),
            .value(Int64.max),
            .malformed
        ] {
            #expect(throws: (any Error).self) {
                let plan = try FirestoreProductRemoteDataSource.transactionPlan(
                    for: operation,
                    against: nil,
                    counter: counter,
                    policy: ProductSyncPolicy()
                )
                #expect(plan.atomicWrite == nil)
            }
        }
    }

    @Test("Malformed counter and partial sync metadata remain decoding failures")
    func malformedMetadataRemainsDecodingFailure() {
        let partialProduct = Data(
            #"{"id":"56000000-0000-0000-0000-000000000001","name":"Partial metadata","status":"active","_sync":{"revision":1}}"#.utf8
        )
        let malformedCounter = Data(#"{"changeSequence":"nine"}"#.utf8)

        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                FirestoreProductDocumentDTO.self,
                from: partialProduct
            )
        }
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder().decode(
                FirestoreProductCounterDTO.self,
                from: malformedCounter
            )
        }
    }

    @Test("Fetch rejects a route identifier different from its payload")
    func fetchRejectsMismatchedRouteIdentity() async {
        let record = firestoreProductRecord()
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            [(documentID: "another-product", record: record)]
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
        let record = firestoreProductRecord()
        let dataSource = makeFirestoreDataSource(fetch: { _ in
            [(documentID: record.id, record: record)]
        })

        await #expect(throws: ProductSyncPolicyError.invalidChangeSequence) {
            try await dataSource.fetchChanges(
                after: ProductSyncCursor(changeSequence: 1)
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

        await #expect(throws: ProductRemoteDataSourceError.permissionDenied) {
            try await permissionDenied.fetchChanges(after: nil)
        }
        await #expect(throws: ProductRemoteDataSourceError.deadlineExceeded) {
            try await deadlineExceeded.fetchChanges(after: nil)
        }
        await #expect(throws: ProductRemoteDataSourceError.resourceExhausted) {
            try await resourceExhausted.fetchChanges(after: nil)
        }
        await #expect(throws: ProductRemoteDataSourceError.aborted) {
            try await aborted.fetchChanges(after: nil)
        }
        await #expect(throws: ProductRemoteDataSourceError.unavailable) {
            try await unavailable.fetchChanges(after: nil)
        }
        await #expect(throws: CancellationError.self) {
            try await cancelled.fetchChanges(after: nil)
        }
    }
}

private actor FirestoreFetchGate {
    private let record: ProductRemoteRecord
    private var cursors: [ProductSyncCursor?] = []

    init(record: ProductRemoteRecord) {
        self.record = record
    }

    var receivedCursors: [ProductSyncCursor?] { cursors }

    func fetch(after cursor: ProductSyncCursor?) -> [(documentID: String, record: ProductRemoteRecord)] {
        cursors.append(cursor)
        return [(documentID: record.id, record: record)]
    }
}

private actor FirestoreTransactionGate {
    private var operations: [ProductPendingOperation] = []
    private var receivedContinuations: [CheckedContinuation<Void, Never>] = []
    private var acknowledgementContinuation: CheckedContinuation<ProductRemoteMutationResult, Never>?

    var receivedOperations: [ProductPendingOperation] { operations }

    func transact(operation: ProductPendingOperation) async -> ProductRemoteMutationResult {
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

    func acknowledge(_ result: ProductRemoteMutationResult) {
        acknowledgementContinuation?.resume(returning: result)
        acknowledgementContinuation = nil
    }
}

private func makeFirestoreDataSource(
    fetch: @escaping @Sendable (ProductSyncCursor?) async throws -> [
        (documentID: String, record: ProductRemoteRecord)
    ] = { _ in [] },
    transact: @escaping @Sendable (
        ProductPendingOperation
    ) async throws -> ProductRemoteMutationResult = { operation in
        let content: ProductRemoteContent
        switch operation {
        case .upsert(let upsert): content = .live(upsert.product)
        case .delete(let delete):
            content = .tombstone(productID: delete.productID)
        }
        return .applied(
            ProductRemoteRecord(
                content: content,
                version: .versioned(
                    revision: 1,
                    lastOperationID: operation.operationID
                ),
                changeSequence: 1
            )
        )
    }
) -> FirestoreProductRemoteDataSource {
    FirestoreProductRemoteDataSource(fetch: fetch, transact: transact)
}

private func firestorePendingUpsert() -> ProductPendingUpsert {
    let product = ProductDTO(
        id: "56000000-0000-0000-0000-000000000001",
        name: "Ana Alonso",
        status: .active
    )
    return ProductPendingUpsert(
        productID: firestoreUUID(product.id),
        operationID: firestoreUUID(
            "57000000-0000-0000-0000-000000000001"
        ),
        predecessorOperationID: nil,
        base: .absent,
        product: product
    )
}

private func firestoreProductRecord(
    revision: Int64? = nil,
    operationID: UUID? = nil,
    changeSequence: Int64? = nil
) -> ProductRemoteRecord {
    let version: ProductRemoteVersion
    if let revision, let operationID {
        version = .versioned(
            revision: revision,
            lastOperationID: operationID
        )
    } else {
        version = .legacy
    }
    return ProductRemoteRecord(
        product: firestorePendingUpsert().product,
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
