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
}

private actor ClientRepositoryFake: ClientRepository {
    private let clients: [Client]
    private var callCount = 0

    init(clients: [Client]) {
        self.clients = clients
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        callCount += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(clients)
            continuation.finish()
        }
    }

    func observationCallCount() -> Int {
        callCount
    }
}
