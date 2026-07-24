import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Client persistence actor")
struct ClientPersistenceActorTests {
    @Test("Concurrent upserts serialize and return detached Domain snapshots")
    func concurrentUpsertsSerializeAndReturnDetachedDomainSnapshots() async throws {
        let container = try makeClientPersistenceContainer()
        let persistenceActor = ClientPersistenceActor(modelContainer: container)
        let clients = [
            Client.draft(
                id: try persistenceClientID("20000000-0000-0000-0000-000000000001"),
                displayName: "Beatriz Alonso"
            ),
            Client.draft(
                id: try persistenceClientID("20000000-0000-0000-0000-000000000002"),
                displayName: "Ana Alonso"
            ),
            Client.draft(
                id: try persistenceClientID("20000000-0000-0000-0000-000000000003"),
                displayName: "Carmen Alonso"
            )
        ]

        try await withThrowingTaskGroup(of: Void.self) { group in
            for client in clients {
                group.addTask {
                    try await persistenceActor.upsert(client)
                }
            }

            try await group.waitForAll()
        }

        let snapshots: [Client] = try await persistenceActor.fetchAll()
        let expectedClients = clients.sorted { $0.displayName < $1.displayName }
        #expect(snapshots == expectedClients)
    }

    @Test("An actor save is visible from an independently owned context")
    func actorSaveIsVisibleFromAnIndependentlyOwnedContext() async throws {
        let container = try makeClientPersistenceContainer()
        let persistenceActor = ClientPersistenceActor(modelContainer: container)
        let client = Client.draft(
            id: try persistenceClientID("20000000-0000-0000-0000-000000000004"),
            displayName: "Independent context"
        )

        try await persistenceActor.upsert(client)

        let verificationContext = ModelContext(container)
        let persistedClients = try ClientLocalDataSource().fetchAll(
            in: verificationContext
        )
        #expect(persistedClients == [client])
    }

    @Test("Delete removes a stable identifier through the actor boundary")
    func deleteRemovesAStableIdentifierThroughTheActorBoundary() async throws {
        let container = try makeClientPersistenceContainer()
        let persistenceActor = ClientPersistenceActor(modelContainer: container)
        let client = Client.draft(
            id: try persistenceClientID("20000000-0000-0000-0000-000000000005"),
            displayName: "Client to delete"
        )
        try await persistenceActor.upsert(client)

        try await persistenceActor.delete(client.id)

        let verificationContext = ModelContext(container)
        #expect(
            try ClientLocalDataSource().fetchAll(in: verificationContext).isEmpty
        )
    }
}

private func makeClientPersistenceContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: Schema([ClientModel.self]))
}

private func persistenceClientID(_ value: String) throws -> ClientID {
    ClientID(rawValue: try #require(UUID(uuidString: value)))
}
