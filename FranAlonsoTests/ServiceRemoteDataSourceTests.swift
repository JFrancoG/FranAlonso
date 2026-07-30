import Foundation
import Testing
@testable import FranAlonso

@Suite("Service remote data source")
struct ServiceRemoteDataSourceTests {
    @Test("Fetch returns the configured server records")
    func fetchReturnsConfiguredServerRecords() async throws {
        let expectedRecords = [
            ServiceRemoteRecord(service: try remoteServiceDTO(), version: .legacy)
        ]
        let dataSource = ServiceRemoteDataSourceFake(records: expectedRecords)

        #expect(
            try await dataSource.fetchChanges(after: nil)
                == ServiceRemoteChangeBatch(
                    records: expectedRecords,
                    nextCursor: ServiceSyncCursor(changeSequence: 0)
                )
        )
    }

    @Test("Upsert records the immutable operation after acknowledgement")
    func upsertRecordsImmutableOperationAfterAcknowledgement() async throws {
        let operation = try remotePendingUpsert()
        let dataSource = ServiceRemoteDataSourceFake()

        let result = try await dataSource.apply(.upsert(operation))

        #expect(await dataSource.receivedUpserts() == [operation])
        #expect(
            result == .applied(
                ServiceRemoteRecord(
                    service: operation.service,
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
        let dataSource = ServiceRemoteDataSourceFake(
            fetchError: ServiceRemoteDataSourceError.permissionDenied
        )

        await #expect(throws: ServiceRemoteDataSourceError.permissionDenied) {
            try await dataSource.fetchChanges(after: nil)
        }
    }

    @Test("Offline server fetch propagates unavailable")
    func offlineServerFetchPropagatesUnavailable() async {
        let dataSource = ServiceRemoteDataSourceFake(
            fetchError: ServiceRemoteDataSourceError.unavailable
        )

        await #expect(throws: ServiceRemoteDataSourceError.unavailable) {
            try await dataSource.fetchChanges(after: nil)
        }
    }

    @Test("Fetch preserves an invalid payload coding path")
    func fetchPreservesInvalidPayloadCodingPath() async {
        let decodingError: DecodingError

        do {
            _ = try JSONDecoder().decode(
                ServiceDTO.self,
                from: invalidRemoteServicePayload()
            )
            Issue.record("Expected an invalid Service status payload")
            return
        } catch let error as DecodingError {
            decodingError = error
        } catch {
            Issue.record("Unexpected fixture error: \(error)")
            return
        }

        let dataSource = ServiceRemoteDataSourceFake(fetchError: decodingError)

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

private actor ServiceRemoteDataSourceFake: ServiceRemoteDataSource {
    private let records: [ServiceRemoteRecord]
    private let fetchError: (any Error)?
    private var upserts: [ServicePendingUpsert] = []

    init(
        records: [ServiceRemoteRecord] = [],
        fetchError: (any Error)? = nil
    ) {
        self.records = records
        self.fetchError = fetchError
    }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        if let fetchError {
            throw fetchError
        }
        return ServiceRemoteChangeBatch(
            records: records,
            nextCursor: cursor ?? ServiceSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        guard case .upsert(let upsert) = operation else {
            throw ServiceRemoteDataSourceError.unexpected
        }
        upserts.append(upsert)
        return .applied(
            ServiceRemoteRecord(
                service: upsert.service,
                version: .versioned(
                    revision: 1,
                    lastOperationID: upsert.operationID
                ),
                changeSequence: 1
            )
        )
    }

    func receivedUpserts() -> [ServicePendingUpsert] {
        upserts
    }
}

private func remotePendingUpsert() throws -> ServicePendingUpsert {
    let service = try remoteServiceDTO()

    return ServicePendingUpsert(
        serviceID: UUID(uuidString: service.id)!,
        operationID: UUID(
            uuidString: "AB000000-0000-0000-0000-000000000001"
        )!,
        predecessorOperationID: nil,
        base: .absent,
        service: service
    )
}

private func remoteServiceDTO() throws -> ServiceDTO {
    try makeServiceDTO(
        id: UUID(uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE")!,
        name: "Ana Alonso",
        discountPercentage: nil
    )
}

private func invalidRemoteServicePayload() -> Data {
    Data(
        #"{"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE","name":"Ana Alonso","type":"professional","linkedProductID":null,"price":{"amount":"29.95","currency":"EUR"},"taxRate":{"percentage":"21"},"discount":null,"status":7}"#.utf8
    )
}
