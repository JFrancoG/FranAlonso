import Foundation
import Testing
@testable import FranAlonso

@Suite("Client remote data source")
struct ClientRemoteDataSourceTests {
    @Test("Fetch returns the configured server response")
    func fetchReturnsTheConfiguredServerResponse() async throws {
        let expectedClients = [remoteClientDTO()]
        let dataSource = ClientRemoteDataSourceFake(clients: expectedClients)

        #expect(try await dataSource.fetchAll() == expectedClients)
    }

    @Test("Upsert records the payload after configured remote acknowledgement")
    func upsertRecordsThePayloadAfterConfiguredRemoteAcknowledgement() async throws {
        let client = remoteClientDTO()
        let dataSource = ClientRemoteDataSourceFake()

        try await dataSource.upsert(client)

        #expect(await dataSource.receivedUpserts() == [client])
    }

    @Test("Fetch propagates a permission denial without provider types")
    func fetchPropagatesAPermissionDenialWithoutProviderTypes() async {
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
    func fetchPreservesAnInvalidPayloadCodingPath() async {
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
    private let clients: [ClientDTO]
    private let fetchError: (any Error)?
    private var upserts: [ClientDTO] = []

    init(
        clients: [ClientDTO] = [],
        fetchError: (any Error)? = nil
    ) {
        self.clients = clients
        self.fetchError = fetchError
    }

    func fetchAll() async throws -> [ClientDTO] {
        if let fetchError {
            throw fetchError
        }
        return clients
    }

    func upsert(_ client: ClientDTO) async throws {
        upserts.append(client)
    }

    func receivedUpserts() -> [ClientDTO] {
        upserts
    }
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
        #"""
        {
          "id": "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE",
          "displayName": "Ana Alonso",
          "billingAddress": {
            "streetLine": "Calle Bailén, 33",
            "postalCode": 41001,
            "city": "Sevilla",
            "province": "Sevilla"
          },
          "status": "draft"
        }
        """#.utf8
    )
}
