import Foundation
import Testing
@testable import FranAlonso

@Suite("Client CRUD use cases")
struct ClientCRUDUseCaseTests {
    @Test
    func `creation persists a normalized draft that can be reopened`() async throws {
        let repository = InMemoryClientRepository()
        let id = clientCRUDID(1)
        let profile = try ClientProfile(displayName: "  Ángela Ejemplo \n", taxIdentifier: "TEST-001")

        let created = try await CreateClientUseCase(repository: repository)(id: id, profile: profile)
        let reopened = try await GetClientUseCase(repository: repository)(id)
        let stream = await repository.observeClients()
        var iterator = stream.makeAsyncIterator()

        #expect(created == reopened)
        #expect(reopened.id == id)
        #expect(reopened.displayName == "Ángela Ejemplo")
        #expect(reopened.taxIdentifier == "TEST-001")
        #expect(reopened.status == .draft)
        #expect(try await iterator.next() == [reopened])
    }

    @Test(arguments: ["", " ", "\n\t  "])
    func `whitespace only names cannot enter the editable profile`(_ name: String) {
        #expect(throws: ClientError.invalidDisplayName) {
            try ClientProfile(displayName: name)
        }
    }

    @Test
    func `editing an active client changes profile fields and preserves its consent`() async throws {
        let original = try clientCRUDActiveClient()
        let repository = InMemoryClientRepository(clients: [original])
        let address = BillingAddress(
            streetLine: "Calle Prueba 20",
            postalCode: "28000",
            city: "Ciudad Ejemplo",
            province: "Provincia Ejemplo"
        )
        let profile = try ClientProfile(
            displayName: "  Ángela Actualizada  ",
            taxIdentifier: "TEST-UPDATED",
            billingAddress: address
        )

        let updated = try await UpdateClientUseCase(repository: repository)(id: original.id, profile: profile)
        let reopened = try await GetClientUseCase(repository: repository)(original.id)

        #expect(updated == reopened)
        #expect(reopened.id == original.id)
        #expect(reopened.displayName == "Ángela Actualizada")
        #expect(reopened.taxIdentifier == "TEST-UPDATED")
        #expect(reopened.billingAddress == address)
        #expect(reopened.status == original.status)
    }

    @Test
    func `editing clears optional profile fields without discarding pending consent`() async throws {
        let original = Client(
            id: clientCRUDID(2),
            displayName: "Cliente Pendiente",
            taxIdentifier: "TEST-PENDING",
            billingAddress: BillingAddress(
                streetLine: "Calle Prueba 10",
                postalCode: "28000",
                city: "Ciudad Ejemplo",
                province: "Provincia Ejemplo"
            ),
            status: .consentPendingUpload
        )
        let repository = InMemoryClientRepository(clients: [original])
        let profile = try ClientProfile(displayName: "Cliente Corregido")

        _ = try await UpdateClientUseCase(repository: repository)(id: original.id, profile: profile)
        let reopened = try await GetClientUseCase(repository: repository)(original.id)

        #expect(reopened.displayName == "Cliente Corregido")
        #expect(reopened.taxIdentifier == nil)
        #expect(reopened.billingAddress == nil)
        #expect(reopened.status == .consentPendingUpload)
    }

    @Test
    func `a duplicate identity does not replace the existing active client`() async throws {
        let original = try clientCRUDActiveClient()
        let repository = InMemoryClientRepository(clients: [original])
        let profile = try ClientProfile(displayName: "Replacement Attempt")

        await #expect(throws: ClientError.alreadyExists) {
            try await CreateClientUseCase(repository: repository)(id: original.id, profile: profile)
        }

        #expect(try await repository.client(id: original.id) == original)
    }

    @Test
    func `clients may share a name and tax identifier when their identities differ`() async throws {
        let repository = InMemoryClientRepository()
        let profile = try ClientProfile(displayName: "Cliente Ejemplo", taxIdentifier: "TEST-SHARED")
        let create = CreateClientUseCase(repository: repository)

        _ = try await create(id: clientCRUDID(1), profile: profile)
        _ = try await create(id: clientCRUDID(2), profile: profile)
        let stream = await repository.observeClients()
        var iterator = stream.makeAsyncIterator()
        let clients = try #require(try await iterator.next())

        #expect(clients.map(\.id) == [clientCRUDID(1), clientCRUDID(2)])
    }

    @Test
    func `missing client lookup reports not found`() async {
        let repository = InMemoryClientRepository()

        await #expect(throws: ClientError.notFound) {
            try await GetClientUseCase(repository: repository)(clientCRUDID(9))
        }
    }

    @Test
    func `lookup selects the requested identity from the local collection`() async throws {
        let first = try clientCRUDActiveClient()
        let selected = Client.draft(id: clientCRUDID(2), displayName: "Cliente Seleccionado")
        let repository = InMemoryClientRepository(clients: [first, selected])

        let reopened = try await GetClientUseCase(repository: repository)(clientCRUDID(2))

        #expect(reopened == selected)
    }

    @Test
    func `editing a missing identity does not create a client`() async throws {
        let original = try clientCRUDActiveClient()
        let repository = InMemoryClientRepository(clients: [original])
        let profile = try ClientProfile(displayName: "Missing Client")

        await #expect(throws: ClientError.notFound) {
            try await UpdateClientUseCase(repository: repository)(id: clientCRUDID(9), profile: profile)
        }

        #expect(try await repository.client(id: clientCRUDID(9)) == nil)
        #expect(try await repository.client(id: original.id) == original)
    }

    @Test
    func `deactivation is idempotent and excludes only the selected client`() async throws {
        let original = try clientCRUDActiveClient()
        let other = Client.draft(id: clientCRUDID(2), displayName: "Cliente Conservado")
        let repository = InMemoryClientRepository(clients: [original, other])
        let deactivate = DeactivateClientUseCase(repository: repository)

        try await deactivate(original.id)
        try await deactivate(original.id)
        let stream = await repository.observeClients()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == [other])
        #expect(try await repository.client(id: original.id) == nil)
        await #expect(throws: ClientError.notFound) {
            try await GetClientUseCase(repository: repository)(original.id)
        }
    }

    @Test
    func `deactivating a missing identity reports not found and preserves the collection`() async throws {
        let original = try clientCRUDActiveClient()
        let repository = InMemoryClientRepository(clients: [original])

        await #expect(throws: ClientError.notFound) {
            try await DeactivateClientUseCase(repository: repository)(clientCRUDID(9))
        }

        #expect(try await repository.client(id: original.id) == original)
    }

    @Test
    func `editing or recreating a deactivated identity cannot resurrect it`() async throws {
        let original = try clientCRUDActiveClient()
        let repository = InMemoryClientRepository(clients: [original])
        let profile = try ClientProfile(displayName: "Resurrection Attempt")
        try await DeactivateClientUseCase(repository: repository)(original.id)

        await #expect(throws: ClientError.deactivated) {
            try await UpdateClientUseCase(repository: repository)(id: original.id, profile: profile)
        }
        await #expect(throws: ClientError.alreadyExists) {
            try await CreateClientUseCase(repository: repository)(id: original.id, profile: profile)
        }

        #expect(try await repository.client(id: original.id) == nil)
    }

    @Test
    func `cancelled creation leaves no client`() async throws {
        let repository = InMemoryClientRepository()
        let profile = try ClientProfile(displayName: "Cancelled Client")
        let id = clientCRUDID(1)

        await #expect(throws: CancellationError.self) {
            try await runPreCancelledClientOperation {
                _ = try await CreateClientUseCase(repository: repository)(id: id, profile: profile)
            }
        }

        #expect(try await repository.client(id: id) == nil)
    }

    @Test
    func `cancelled editing preserves the previous client`() async throws {
        let original = try clientCRUDActiveClient()
        let repository = InMemoryClientRepository(clients: [original])
        let profile = try ClientProfile(displayName: "Cancelled Change")

        await #expect(throws: CancellationError.self) {
            try await runPreCancelledClientOperation {
                _ = try await UpdateClientUseCase(repository: repository)(id: original.id, profile: profile)
            }
        }

        #expect(try await repository.client(id: original.id) == original)
    }

    @Test
    func `cancelled deactivation preserves the visible client`() async throws {
        let original = try clientCRUDActiveClient()
        let repository = InMemoryClientRepository(clients: [original])

        await #expect(throws: CancellationError.self) {
            try await runPreCancelledClientOperation {
                try await DeactivateClientUseCase(repository: repository)(original.id)
            }
        }

        #expect(try await repository.client(id: original.id) == original)
    }

    @Test
    func `prior cancellation takes precedence over repository failure for every CRUD operation`() async throws {
        let repository = ClientCRUDFailingRepository(error: ClientError.persistenceUnavailable)
        let profile = try ClientProfile(displayName: "Cancelled Client")
        let id = clientCRUDID(1)

        await #expect(throws: CancellationError.self) {
            try await runPreCancelledClientOperation {
                _ = try await CreateClientUseCase(repository: repository)(id: id, profile: profile)
            }
        }
        await #expect(throws: CancellationError.self) {
            try await runPreCancelledClientOperation {
                _ = try await GetClientUseCase(repository: repository)(id)
            }
        }
        await #expect(throws: CancellationError.self) {
            try await runPreCancelledClientOperation {
                _ = try await UpdateClientUseCase(repository: repository)(id: id, profile: profile)
            }
        }
        await #expect(throws: CancellationError.self) {
            try await runPreCancelledClientOperation {
                try await DeactivateClientUseCase(repository: repository)(id)
            }
        }
    }

    @Test(arguments: [ClientError.conflict, .persistenceUnavailable])
    func `CRUD operations propagate domain failures`(_ error: ClientError) async throws {
        let repository = ClientCRUDFailingRepository(error: error)
        let profile = try ClientProfile(displayName: "Cliente Ejemplo")
        let id = clientCRUDID(1)

        await #expect(throws: error) {
            try await CreateClientUseCase(repository: repository)(id: id, profile: profile)
        }
        await #expect(throws: error) {
            try await GetClientUseCase(repository: repository)(id)
        }
        await #expect(throws: error) {
            try await UpdateClientUseCase(repository: repository)(id: id, profile: profile)
        }
        await #expect(throws: error) {
            try await DeactivateClientUseCase(repository: repository)(id)
        }
    }
}

private struct ClientCRUDFailingRepository: ClientRepository {
    let error: any Error

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: error)
        }
    }

    func saveClient(_ client: Client) async throws {
        throw error
    }

    func client(id: ClientID) async throws -> Client? {
        throw error
    }

    func createClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        throw error
    }

    func updateClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        throw error
    }

    func deactivateClient(_ id: ClientID) async throws {
        throw error
    }
}

private func clientCRUDID(_ suffix: Int) -> ClientID {
    ClientID(rawValue: UUID(uuidString: "08010000-0000-0000-0000-00000000000\(suffix)")!)
}

private func clientCRUDActiveClient() throws -> Client {
    Client(
        id: clientCRUDID(1),
        displayName: "Ángela Original",
        taxIdentifier: "TEST-ORIGINAL",
        billingAddress: nil,
        status: .active(consentReference: try ClientConsentReference(rawValue: "consent-test-01"))
    )
}

private func runPreCancelledClientOperation(
    _ operation: @escaping @Sendable () async throws -> Void
) async throws {
    let gate = AsyncStream<Void>.makeStream()
    let task = Task {
        var iterator = gate.stream.makeAsyncIterator()
        _ = await iterator.next()
        try await operation()
    }

    task.cancel()
    gate.continuation.finish()
    try await task.value
}
