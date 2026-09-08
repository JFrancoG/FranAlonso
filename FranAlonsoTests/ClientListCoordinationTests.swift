import Foundation
import Testing
@testable import FranAlonso

@Suite("Client list search and navigation")
@MainActor
struct ClientListCoordinationTests {
    @Test
    func `search follows the current query and each new local snapshot`() async throws {
        let first = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Ángela")
        let second = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Beatriz")
        let repository = InMemoryClientRepository(clients: [first, second])
        let model = ClientListViewModel(observeClients: ObserveClientsUseCase(repository: repository))
        model.query = "angela"
        await model.load()
        #expect(model.visibleClients == [first])

        model.query = "beatriz"
        #expect(model.visibleClients == [second])
        let added = try await repository.createClient(
            id: ClientID(rawValue: UUID()),
            profile: ClientProfile(displayName: "Beatriz del Sur")
        )
        await model.load()
        #expect(model.visibleClients == [second, added])
        #expect(model.state == .content([first, second, added]))
    }

    @Test
    func `no search matches stays distinct from an empty source`() async throws {
        let client = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Ana")
        let repository = InMemoryClientRepository(clients: [client])
        let model = ClientListViewModel(observeClients: ObserveClientsUseCase(repository: repository))
        model.query = "missing"
        await model.load()
        #expect(model.hasNoSearchResults)
        #expect(model.state == .content([client]))

        try await repository.deactivateClient(client.id)
        await model.load()
        #expect(model.state == .empty)
        #expect(!model.hasNoSearchResults)
    }

    @Test
    func `creation keeps its identity and an old dismissal cannot close a new session`() throws {
        var identifiers = [
            UUID(uuidString: "08020000-0000-0000-0000-000000000001")!,
            UUID(uuidString: "08020000-0000-0000-0000-000000000002")!,
            UUID(uuidString: "08020000-0000-0000-0000-000000000003")!,
            UUID(uuidString: "08020000-0000-0000-0000-000000000004")!
        ]
        let model = ClientListViewModel(
            observeClients: ObserveClientsUseCase(repository: InMemoryClientRepository()),
            makeID: {
                identifiers.removeFirst()
            }
        )
        model.beginCreatingClient()
        let first = try #require(model.formDestination)
        model.beginCreatingClient()
        #expect(model.formDestination == first)

        model.finishFormSession(first.id)
        model.beginCreatingClient()
        let second = try #require(model.formDestination)
        #expect(second.id != first.id)
        #expect(second.clientID != first.clientID)
        model.finishFormSession(first.id)
        #expect(model.formDestination == second)
    }

    @Test
    func `editing only opens clients visible in the current search`() async throws {
        let client = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Ana")
        let model = ClientListViewModel(
            observeClients: ObserveClientsUseCase(repository: InMemoryClientRepository(clients: [client]))
        )
        await model.load()
        model.query = "missing"
        model.beginEditingClient(client.id)
        #expect(model.formDestination == nil)
        model.query = "ana"
        model.beginEditingClient(client.id)
        let destination = try #require(model.formDestination)
        #expect(destination.mode == .edit)
        #expect(destination.clientID == client.id)
    }

    @Test(arguments: [ObsoleteObservation.value, .failure, .finished, .cancelled], [false, true])
    func `a replaced observation cannot overwrite the new one`(
        outcome: ObsoleteObservation,
        delaysIterator: Bool
    ) async {
        let newest = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Current snapshot")
        let repository = DelayedClientListRepository(current: newest, delaysIterator: delaysIterator)
        let model = ClientListViewModel(observeClients: ObserveClientsUseCase(repository: repository))
        let oldLoad = Task {
            await model.load()
        }
        await repository.waitForFirstRequest()
        await model.load()
        if outcome == .cancelled {
            oldLoad.cancel()
        }
        await repository.releaseFirst(outcome)
        await oldLoad.value
        #expect(model.state == .content([newest]))
    }

    @Test
    func `a snapshot arriving after query editing uses the latest query`() async {
        let client = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Current snapshot")
        let repository = DelayedClientListRepository(current: client)
        let model = ClientListViewModel(observeClients: ObserveClientsUseCase(repository: repository))
        let loading = Task {
            await model.load()
        }
        await repository.waitForFirstRequest()
        model.query = "no match"
        await repository.releaseFirst(.value)
        await loading.value
        #expect(model.visibleClients.isEmpty)
        #expect(model.hasNoSearchResults)
    }
}

enum ObsoleteObservation {
    case value
    case failure
    case finished
    case cancelled
}

private actor DelayedClientListRepository: ClientRepository {
    private let current: Client
    private let delaysIterator: Bool
    private var callCount = 0
    private var firstRequest: CheckedContinuation<AsyncThrowingStream<[Client], any Error>, Never>?
    private var firstElement: CheckedContinuation<[Client]?, any Error>?
    private var hasRequestedElement = false
    private var started: CheckedContinuation<Void, Never>?

    init(current: Client, delaysIterator: Bool = false) {
        self.current = current
        self.delaysIterator = delaysIterator
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        callCount += 1
        if callCount == 1 {
            if delaysIterator {
                return AsyncThrowingStream(unfolding: {
                    try await self.delayedElement()
                })
            }
            return await withCheckedContinuation { continuation in
                firstRequest = continuation
                started?.resume()
                started = nil
            }
        }
        return AsyncThrowingStream { continuation in
            continuation.yield([current])
            continuation.finish()
        }
    }

    func waitForFirstRequest() async {
        guard firstRequest == nil, firstElement == nil else { return }
        await withCheckedContinuation {
            started = $0
        }
    }

    func releaseFirst(_ outcome: ObsoleteObservation) {
        if let firstElement {
            self.firstElement = nil
            switch outcome {
            case .value, .cancelled:
                let obsolete = Client.draft(id: current.id, displayName: "Obsolete snapshot")
                firstElement.resume(returning: [obsolete])
            case .failure:
                firstElement.resume(throwing: ClientError.persistenceUnavailable)
            case .finished:
                firstElement.resume(returning: nil)
            }
            return
        }
        firstRequest?.resume(returning: AsyncThrowingStream { continuation in
            switch outcome {
            case .value, .cancelled:
                continuation.yield([Client.draft(id: ClientID(rawValue: UUID()), displayName: "Old snapshot")])
                continuation.finish()
            case .failure:
                continuation.finish(throwing: ClientError.persistenceUnavailable)
            case .finished:
                continuation.finish()
            }
        })
        firstRequest = nil
    }

    private func delayedElement() async throws -> [Client]? {
        guard !hasRequestedElement else { return nil }
        hasRequestedElement = true
        return try await withCheckedThrowingContinuation { continuation in
            firstElement = continuation
            started?.resume()
            started = nil
        }
    }

    func client(id: ClientID) async throws -> Client? {
        throw ClientError.persistenceUnavailable
    }

    func saveClient(_ client: Client) async throws {
        throw ClientError.persistenceUnavailable
    }

    func deactivateClient(_ id: ClientID) async throws {
        throw ClientError.persistenceUnavailable
    }

    func createClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        throw ClientError.persistenceUnavailable
    }

    func updateClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        throw ClientError.persistenceUnavailable
    }
}
