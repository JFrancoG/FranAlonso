import Foundation
import Testing
@testable import FranAlonso

@Suite("Firestore client remote data source")
struct FirestoreClientRemoteDataSourceTests {
    @Test(
        "Environments resolve the approved Clients collection paths",
        arguments: [FirestoreEnvironment.develop, .production]
    )
    func environmentsResolveTheApprovedClientsCollectionPaths(
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

    @Test("Fetch returns decoded documents whose route identity matches the payload")
    func fetchReturnsDecodedDocumentsWhoseRouteIdentityMatchesThePayload() async throws {
        let expectedClient = firestoreClientDTO()
        let dataSource = makeFirestoreDataSource {
            [(documentID: expectedClient.id, payload: expectedClient)]
        }

        #expect(try await dataSource.fetchAll() == [expectedClient])
    }

    @Test("Upsert writes the exact payload under its stable identifier")
    func upsertWritesTheExactPayloadUnderItsStableIdentifier() async throws {
        let client = firestoreClientDTO()
        let writeGate = FirestoreClientWriteGate()
        let completionSpy = FirestoreClientCompletionSpy()
        let dataSource = makeFirestoreDataSource(
            writeDocument: { documentID, payload in
                await writeGate.write(documentID: documentID, payload: payload)
            }
        )

        async let operation: Void = upsert(
            client,
            through: dataSource,
            recordingCompletionIn: completionSpy
        )

        await writeGate.waitUntilReceived()

        #expect(await completionSpy.isCompleted == false)
        #expect(
            await writeGate.receivedWrites() == [
                FirestoreClientWrite(documentID: client.id, payload: client)
            ]
        )

        await writeGate.acknowledge()
        try await operation

        #expect(await completionSpy.isCompleted)
    }

    @Test("Permission denied is mapped to the provider-neutral error")
    func permissionDeniedIsMappedToTheProviderNeutralError() async {
        let dataSource = makeFirestoreDataSource {
            throw firestoreError(code: 7)
        }

        await #expect(throws: ClientRemoteDataSourceError.permissionDenied) {
            try await dataSource.fetchAll()
        }
    }

    @Test("Unavailable is mapped to the provider-neutral error")
    func unavailableIsMappedToTheProviderNeutralError() async {
        let dataSource = makeFirestoreDataSource {
            throw firestoreError(code: 14)
        }

        await #expect(throws: ClientRemoteDataSourceError.unavailable) {
            try await dataSource.fetchAll()
        }
    }

    @Test("Foreign failures are mapped to unexpected")
    func foreignFailuresAreMappedToUnexpected() async {
        let dataSource = makeFirestoreDataSource {
            throw NSError(domain: "TestTransport", code: 42)
        }

        await #expect(throws: ClientRemoteDataSourceError.unexpected) {
            try await dataSource.fetchAll()
        }
    }

    @Test("Fetch preserves a payload decoding error and its nested coding path")
    func fetchPreservesAPayloadDecodingErrorAndItsNestedCodingPath() async {
        let dataSource = makeFirestoreDataSource {
            throw try nestedPostalCodeDecodingError()
        }

        do {
            _ = try await dataSource.fetchAll()
            Issue.record("Expected the injected decoding error")
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

    @Test("Fetch rejects a route identifier that differs from the payload identifier")
    func fetchRejectsARouteIdentifierThatDiffersFromThePayloadIdentifier() async {
        let client = firestoreClientDTO()
        let dataSource = makeFirestoreDataSource {
            [(documentID: "another-client", payload: client)]
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

    @Test("Native task cancellation remains cancellation")
    func nativeTaskCancellationRemainsCancellation() async {
        let dataSource = makeFirestoreDataSource {
            throw CancellationError()
        }

        await #expect(throws: CancellationError.self) {
            try await dataSource.fetchAll()
        }
    }

    @Test("Firestore cancelled is translated to task cancellation")
    func firestoreCancelledIsTranslatedToTaskCancellation() async {
        let dataSource = makeFirestoreDataSource {
            throw firestoreError(code: 1)
        }

        await #expect(throws: CancellationError.self) {
            try await dataSource.fetchAll()
        }
    }
}

private struct FirestoreClientWrite: Equatable {
    let documentID: String
    let payload: ClientDTO
}

private actor FirestoreClientWriteGate {
    private var writes: [FirestoreClientWrite] = []
    private var receivedContinuations: [CheckedContinuation<Void, Never>] = []
    private var acknowledgementContinuation: CheckedContinuation<Void, Never>?

    func write(documentID: String, payload: ClientDTO) async {
        writes.append(FirestoreClientWrite(documentID: documentID, payload: payload))
        receivedContinuations.forEach { $0.resume() }
        receivedContinuations.removeAll()

        await withCheckedContinuation { continuation in
            acknowledgementContinuation = continuation
        }
    }

    func waitUntilReceived() async {
        guard writes.isEmpty else {
            return
        }

        await withCheckedContinuation { continuation in
            receivedContinuations.append(continuation)
        }
    }

    func acknowledge() {
        acknowledgementContinuation?.resume()
        acknowledgementContinuation = nil
    }

    func receivedWrites() -> [FirestoreClientWrite] {
        writes
    }
}

private actor FirestoreClientCompletionSpy {
    private(set) var isCompleted = false

    func recordCompletion() {
        isCompleted = true
    }
}

private func makeFirestoreDataSource(
    fetchDocuments: @escaping @Sendable () async throws -> [
        (documentID: String, payload: ClientDTO)
    ] = { [] },
    writeDocument: @escaping @Sendable (String, ClientDTO) async throws -> Void = { _, _ in }
) -> FirestoreClientRemoteDataSource {
    FirestoreClientRemoteDataSource(
        fetch: fetchDocuments,
        write: writeDocument
    )
}

private func firestoreClientDTO() -> ClientDTO {
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

private func upsert(
    _ client: ClientDTO,
    through dataSource: FirestoreClientRemoteDataSource,
    recordingCompletionIn completionSpy: FirestoreClientCompletionSpy
) async throws {
    try await dataSource.upsert(client)
    await completionSpy.recordCompletion()
}

private func firestoreError(code: Int) -> NSError {
    NSError(domain: "FIRFirestoreErrorDomain", code: code)
}

private func nestedPostalCodeDecodingError() throws -> DecodingError {
    do {
        _ = try JSONDecoder().decode(
            ClientDTO.self,
            from: Data(
                #"{"id":"AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE","displayName":"Ana Alonso","billingAddress":{"streetLine":"Calle Bailén, 33","postalCode":41001,"city":"Sevilla","province":"Sevilla"},"status":"draft"}"#.utf8
            )
        )
        throw TestFixtureError.expectedDecodingFailure
    } catch let error as DecodingError {
        return error
    }
}

private enum TestFixtureError: Error {
    case expectedDecodingFailure
}
