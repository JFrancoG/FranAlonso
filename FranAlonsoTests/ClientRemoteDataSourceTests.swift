import Foundation
import Testing
@testable import FranAlonso

@Suite("Client remote data source")
struct ClientRemoteDataSourceTests {
    @Test("Fetch returns the configured server records")
    func fetchReturnsConfiguredServerRecords() async throws {
        let expectedRecords = [
            ClientRemoteRecord(client: remoteClientDTO(), version: .legacy)
        ]
        let dataSource = ClientRemoteDataSourceFake(records: expectedRecords)

        #expect(try await dataSource.fetchAll() == expectedRecords)
    }

    @Test("Upsert records the immutable operation after acknowledgement")
    func upsertRecordsImmutableOperationAfterAcknowledgement() async throws {
        let operation = remotePendingUpsert()
        let dataSource = ClientRemoteDataSourceFake()

        let result = try await dataSource.upsert(operation)

        #expect(await dataSource.receivedUpserts() == [operation])
        #expect(
            result == .applied(
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

    @Test("Fetch propagates a permission denial without provider types")
    func fetchPropagatesPermissionDenialWithoutProviderTypes() async {
        let dataSource = ClientRemoteDataSourceFake(
            fetchError: ClientRemoteDataSourceError.permissionDenied
        )

        await #expect(throws: ClientRemoteDataSourceError.permissionDenied) {
            try await dataSource.fetchAll()
        }
    }

    @Test("Offline server fetch propagates unavailable")
    func offlineServerFetchPropagatesUnavailable() async {
        let dataSource = ClientRemoteDataSourceFake(
            fetchError: ClientRemoteDataSourceError.unavailable
        )

        await #expect(throws: ClientRemoteDataSourceError.unavailable) {
            try await dataSource.fetchAll()
        }
    }

    @Test("Fetch preserves an invalid payload coding path")
    func fetchPreservesInvalidPayloadCodingPath() async {
        let decodingError: DecodingError

        do {
            _ = try JSONDecoder().decode(
                ClientDTO.self,
                from: invalidRemoteClientPayload()
            )
            Issue.record("Expected an invalid postalCode payload")
            return
        } catch let error as DecodingError {
            decodingError = error
        } catch {
            Issue.record("Unexpected fixture error: \(error)")
            return
        }

        let dataSource = ClientRemoteDataSourceFake(fetchError: decodingError)

        do {
            _ = try await dataSource.fetchAll()
            Issue.record("Expected the configured decoding error")
        } catch DecodingError.typeMismatch(_, let context) {
            #expect(
                context.codingPath.map(\.stringValue) == [
                    "billingAddress",
                    "postalCode"
                ]
            )
        } catch {
            Issue.record("Unexpected fetch error: \(error)")
        }
    }
}

private actor ClientRemoteDataSourceFake: ClientRemoteDataSource {
    private let records: [ClientRemoteRecord]
    private let fetchError: (any Error)?
    private var upserts: [ClientPendingUpsert] = []

    init(
        records: [ClientRemoteRecord] = [],
        fetchError: (any Error)? = nil
    ) {
        self.records = records
        self.fetchError = fetchError
    }

    func fetchAll() async throws -> [ClientRemoteRecord] {
        if let fetchError {
            throw fetchError
        }
        return records
    }

    func upsert(
        _ operation: ClientPendingUpsert
    ) async throws -> ClientRemoteUpsertResult {
        upserts.append(operation)
        return .applied(
            ClientRemoteRecord(
                client: operation.client,
                version: .versioned(
                    revision: 1,
                    lastOperationID: operation.operationID
                )
            )
        )
    }

    func receivedUpserts() -> [ClientPendingUpsert] {
        upserts
    }
}

private func remotePendingUpsert() -> ClientPendingUpsert {
    ClientPendingUpsert(
        clientID: UUID(uuidString: remoteClientDTO().id)!,
        operationID: UUID(
            uuidString: "AB000000-0000-0000-0000-000000000001"
        )!,
        predecessorOperationID: nil,
        base: .absent,
        client: remoteClientDTO()
    )
}

private func remoteClientDTO() -> ClientDTO {
    ClientDTO(
        id: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
        displayName: "Ana Alonso",
        taxIdentifier: "12345678Z",
        billingAddress: BillingAddressDTO(
            streetLine: "Calle Bailén, 33",
            postalCode: "41001",
            city: "Sevilla",
            province: "Sevilla"
        ),
        status: .active,
        consentReference: "consents/ana-alonso/signed.pdf"
    )
}

private func invalidRemoteClientPayload() -> Data {
    Data(
        #"{"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE","displayName":"Ana Alonso","billingAddress":{"streetLine":"Calle Bailén, 33","postalCode":41001,"city":"Sevilla","province":"Sevilla"},"status":"draft"}"#.utf8
    )
}
