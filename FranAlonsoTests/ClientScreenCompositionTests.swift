import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Client screen dependency composition", .timeLimit(.minutes(1)))
@MainActor
struct ClientScreenCompositionTests {
#if FRANALONSO_AUTH_FIXTURE
    @Test
    func `local screen forms share the observed container and enqueue each mutation once`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let dependencies = AppDependencies.local(
            modelContainer: container,
            analyticsDataSource: ScreenCompositionAnalytics(),
            crashDataSource: ScreenCompositionCrash()
        )

        try await verifyScreenMutations(dependencies, container: container, initialClients: [])
    }
#endif

    @Test
    func `interactive preview forms update the same seeded source observed by their screen`() async throws {
        let context = try AppPreviewModifier.makeSharedContext()

        try await verifyScreenMutations(
            context.dependencies,
            container: context.modelContainer,
            initialClients: AppPreviewFixtures.standard.clients
        )
    }

    @Test(arguments: ReadOnlyMutation.allCases, ReadOnlyComposition.allCases)
    func `read only client compositions reject writes without touching the supplied context`(
        mutation: ReadOnlyMutation,
        composition: ReadOnlyComposition
    ) async throws {
        let original = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Snapshot client")
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let dependencies: AppDependencies
        switch composition {
        case .snapshot:
            dependencies = .preview(clients: [original])
#if FRANALONSO_AUTH_FIXTURE
        case .injectedLocal:
            dependencies = .local(
                modelContainer: container,
                analyticsDataSource: ScreenCompositionAnalytics(),
                crashDataSource: ScreenCompositionCrash(),
                clientRepository: InMemoryClientRepository(clients: [original])
            )
#endif
        }
        let destination = ClientFormDestination(
            id: UUID(),
            clientID: mutation == .create ? ClientID(rawValue: UUID()) : original.id,
            mode: mutation == .create ? .create : .edit
        )
        let model = dependencies.makeClientForm(destination)
        await model.load()
        if mutation != .create {
            #expect(model.fields.displayName == "Snapshot client")
        }
        model.fields.displayName = "Rejected change"

        if mutation == .deactivate {
            await model.deactivate(in: container.mainContext)
            #expect(model.state == .failed(.deactivate, .persistenceUnavailable))
        } else {
            await model.save(in: container.mainContext)
            #expect(model.state == .failed(.save, .persistenceUnavailable))
        }

        var observation = await dependencies.observeClients().makeAsyncIterator()
        #expect(try await observation.next() == [original])
        #expect(try await observation.next() == nil)
        let verificationContext = ModelContext(container)
        #expect(try verificationContext.fetchCount(FetchDescriptor<ClientModel>()) == 0)
        #expect(try ClientLocalDataSource().pendingOperations(in: verificationContext).isEmpty)
    }

    enum ReadOnlyMutation: CaseIterable {
        case create
        case edit
        case deactivate
    }

    enum ReadOnlyComposition: CaseIterable {
        case snapshot
#if FRANALONSO_AUTH_FIXTURE
        case injectedLocal
#endif
    }

    private func verifyScreenMutations(
        _ dependencies: AppDependencies,
        container: ModelContainer,
        initialClients: [Client]
    ) async throws {
        var observation = await dependencies.observeClients().makeAsyncIterator()
        #expect(try await observation.next() == initialClients)
        let clientID = ClientID(rawValue: UUID())
        let creating = dependencies.makeClientForm(ClientFormDestination(id: UUID(), clientID: clientID, mode: .create))
        creating.fields.displayName = "Public form creation"
        await creating.save(in: container.mainContext)

        let afterCreation = try #require(try await observation.next())
        let created = try #require(afterCreation.first { $0.id == clientID })
        #expect(created.displayName == "Public form creation")
        #expect(created.status == .draft)
        #expect(afterCreation.count == initialClients.count + 1)
        #expect(creating.state == .saved(created))
        #expect(try pendingCount(in: container) == 1)

        let editing = dependencies.makeClientForm(ClientFormDestination(id: UUID(), clientID: clientID, mode: .edit))
        await editing.load()
        #expect(editing.fields.displayName == "Public form creation")
        editing.fields.displayName = "Public form revision"
        await editing.save(in: container.mainContext)

        let afterEditing = try #require(try await observation.next())
        let edited = try #require(afterEditing.first { $0.id == clientID })
        #expect(edited.displayName == "Public form revision")
        #expect(edited.status == .draft)
        #expect(afterEditing.count == initialClients.count + 1)
        #expect(editing.state == .saved(edited))
        #expect(try pendingCount(in: container) == 2)

        let deactivating = dependencies.makeClientForm(
            ClientFormDestination(id: UUID(), clientID: clientID, mode: .edit)
        )
        await deactivating.load()
        await deactivating.deactivate(in: container.mainContext)

        #expect(deactivating.state == .deactivated)
        #expect(try await observation.next() == initialClients)
        #expect(try pendingCount(in: container) == 3)
        let persisted = try ModelContext(container).fetch(FetchDescriptor<ClientModel>())
        let retained = try #require(persisted.first { $0.id == clientID.rawValue })
        #expect(try retained.toDomain().displayName == "Public form revision")
        #expect(persisted.count == initialClients.count + 1)
    }

    private func pendingCount(in container: ModelContainer) throws -> Int {
        try ClientLocalDataSource().pendingOperations(in: ModelContext(container)).count
    }
}

private struct ScreenCompositionAnalytics: AnalyticsDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) {}

    func log(_ event: AnalyticsEvent) {}
}

private struct ScreenCompositionCrash: CrashDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) {}

    func record(_ diagnostic: CrashDiagnostic) {}
}
