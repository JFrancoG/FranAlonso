import Foundation
import Testing
@testable import FranAlonso

@Suite("Observe clients use case")
struct ObserveClientsUseCaseTests {
    @Test("Delegates client observation to the repository")
    func delegatesClientObservationToTheRepository() async throws {
        let expectedClients = [
            Client.draft(
                id: ClientID(
                    rawValue: UUID(
                        uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
                    )!
                ),
                displayName: "Ana Alonso"
            )
        ]
        let repository = ClientRepositoryFake(clients: expectedClients)
        let useCase = ObserveClientsUseCase(repository: repository)

        let stream = await useCase()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == expectedClients)
        #expect(try await iterator.next() == nil)
        #expect(await repository.observationCallCount() == 1)
    }

    @Test("Delegates local client persistence to the repository")
    func delegatesLocalClientPersistenceToTheRepository() async throws {
        let client = Client.draft(
            id: ClientID(
                rawValue: UUID(
                    uuidString: "BBBBBBBB-CCCC-DDDD-EEEE-FFFFFFFFFFFF"
                )!
            ),
            displayName: "Bea Alonso"
        )
        let repository = ClientRepositoryFake(clients: [])
        let useCase = SaveClientUseCase(repository: repository)

        try await useCase(client)

        #expect(await repository.savedClients() == [client])
        #expect(await repository.saveCallCount() == 1)
        requireClientUseCaseSendable(useCase)
    }

    @Test("In-memory saves appear in later observations")
    func inMemorySavesAppearInLaterObservations() async throws {
        let client = Client.draft(
            id: ClientID(
                rawValue: UUID(
                    uuidString: "CCCCCCCC-DDDD-EEEE-FFFF-AAAAAAAAAAAA"
                )!
            ),
            displayName: "Carla Alonso"
        )
        let repository = InMemoryClientRepository()
        let saveClient = SaveClientUseCase(repository: repository)
        let observeClients = ObserveClientsUseCase(repository: repository)

        try await saveClient(client)
        let stream = await observeClients()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == [client])
        #expect(try await iterator.next() == nil)
    }

    @Test("In-memory saves replace matching client identity")
    func inMemorySavesReplaceMatchingClientIdentity() async throws {
        let id = ClientID(
            rawValue: UUID(
                uuidString: "DDDDDDDD-EEEE-FFFF-AAAA-BBBBBBBBBBBB"
            )!
        )
        let original = Client.draft(id: id, displayName: "Diana")
        let updated = Client.draft(id: id, displayName: "Diana Alonso")
        let repository = InMemoryClientRepository(clients: [original])
        let saveClient = SaveClientUseCase(repository: repository)
        let observeClients = ObserveClientsUseCase(repository: repository)

        try await saveClient(updated)
        let stream = await observeClients()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == [updated])
        #expect(try await iterator.next() == nil)
    }
}

private actor ClientRepositoryFake: ClientRepository {
    private var clients: [Client]
    private var observationCalls = 0
    private var saveCalls = 0
    private var persistedClients: [Client] = []

    init(clients: [Client]) {
        self.clients = clients
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        observationCalls += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(clients)
            continuation.finish()
        }
    }

    func saveClient(_ client: Client) async throws {
        saveCalls += 1
        persistedClients.append(client)
    }

    func observationCallCount() -> Int {
        observationCalls
    }

    func saveCallCount() -> Int {
        saveCalls
    }

    func savedClients() -> [Client] {
        persistedClients
    }
}

private func requireClientUseCaseSendable<Value: Sendable>(_ value: Value) {}
