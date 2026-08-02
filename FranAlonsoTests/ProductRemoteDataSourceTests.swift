import Foundation
import Testing
@testable import FranAlonso

@Suite("Product remote data source")
struct ProductRemoteDataSourceTests {
    @Test("Fetch returns the configured server records")
    func fetchReturnsConfiguredServerRecords() async throws {
        let expectedRecords = [
            ProductRemoteRecord(product: remoteProductDTO(), version: .legacy)
        ]
        let dataSource = ProductRemoteDataSourceFake(records: expectedRecords)

        #expect(
            try await dataSource.fetchChanges(after: nil)
                == ProductRemoteChangeBatch(
                    records: expectedRecords,
                    nextCursor: ProductSyncCursor(changeSequence: 0)
                )
        )
    }

    @Test("Upsert records the immutable operation after acknowledgement")
    func upsertRecordsImmutableOperationAfterAcknowledgement() async throws {
        let operation = remotePendingUpsert()
        let dataSource = ProductRemoteDataSourceFake()

        let result = try await dataSource.apply(.upsert(operation))

        #expect(await dataSource.receivedUpserts() == [operation])
        #expect(
            result == .applied(
                ProductRemoteRecord(
                    product: operation.product,
                    version: .versioned(
                        revision: 1,
                        lastOperationID: operation.operationID
                    ),
                    changeSequence: 1
                )
            )
        )
    }

    @Test("Fetch propagates a permission denial without provider types")
    func fetchPropagatesPermissionDenialWithoutProviderTypes() async {
        let dataSource = ProductRemoteDataSourceFake(
            fetchError: ProductRemoteDataSourceError.permissionDenied
        )

        await #expect(throws: ProductRemoteDataSourceError.permissionDenied) {
            try await dataSource.fetchChanges(after: nil)
        }
    }

    @Test("Offline server fetch propagates unavailable")
    func offlineServerFetchPropagatesUnavailable() async {
        let dataSource = ProductRemoteDataSourceFake(
            fetchError: ProductRemoteDataSourceError.unavailable
        )

        await #expect(throws: ProductRemoteDataSourceError.unavailable) {
            try await dataSource.fetchChanges(after: nil)
        }
    }

    @Test("Fetch preserves an invalid payload coding path")
    func fetchPreservesInvalidPayloadCodingPath() async {
        let decodingError: DecodingError

        do {
            _ = try JSONDecoder().decode(
                ProductDTO.self,
                from: invalidRemoteProductPayload()
            )
            Issue.record("Expected an invalid Product status payload")
            return
        } catch let error as DecodingError {
            decodingError = error
        } catch {
            Issue.record("Unexpected fixture error: \(error)")
            return
        }

        let dataSource = ProductRemoteDataSourceFake(fetchError: decodingError)

        do {
            _ = try await dataSource.fetchChanges(after: nil)
            Issue.record("Expected the configured decoding error")
        } catch DecodingError.typeMismatch(_, let context) {
            #expect(context.codingPath.map(\.stringValue) == ["status"])
        } catch {
            Issue.record("Unexpected fetch error: \(error)")
        }
    }
}

private actor ProductRemoteDataSourceFake: ProductRemoteDataSource {
    private let records: [ProductRemoteRecord]
    private let fetchError: (any Error)?
    private var upserts: [ProductPendingUpsert] = []

    init(records: [ProductRemoteRecord] = [], fetchError: (any Error)? = nil) {
        self.records = records
        self.fetchError = fetchError
    }

    func fetchChanges(after cursor: ProductSyncCursor?) async throws -> ProductRemoteChangeBatch {
        if let fetchError {
            throw fetchError
        }
        return ProductRemoteChangeBatch(
            records: records,
            nextCursor: cursor ?? ProductSyncCursor(changeSequence: 0)
        )
    }

    func apply(_ operation: ProductPendingOperation) async throws -> ProductRemoteMutationResult {
        guard case .upsert(let upsert) = operation else { throw ProductRemoteDataSourceError.unexpected }
        upserts.append(upsert)
        return .applied(
            ProductRemoteRecord(
                product: upsert.product,
                version: .versioned(
                    revision: 1,
                    lastOperationID: upsert.operationID
                ),
                changeSequence: 1
            )
        )
    }

    func receivedUpserts() -> [ProductPendingUpsert] { upserts }
}

private func remotePendingUpsert() -> ProductPendingUpsert {
    ProductPendingUpsert(
        productID: UUID(uuidString: remoteProductDTO().id)!,
        operationID: UUID(
            uuidString: "AB000000-0000-0000-0000-000000000001"
        )!,
        predecessorOperationID: nil,
        base: .absent,
        product: remoteProductDTO()
    )
}

private func remoteProductDTO() -> ProductDTO {
    ProductDTO(
        id: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
        name: "Ana Alonso",
        status: .active
    )
}

private func invalidRemoteProductPayload() -> Data {
    Data(
        #"{"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE","name":"Ana Alonso","status":7}"#.utf8
    )
}
