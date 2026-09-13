import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Client CRUD local-first acceptance")
struct ClientCRUDPersistenceTests {
    @Test("CRUD publishes committed SwiftData snapshots and preserves the causal chain")
    func crudPublishesLocalSnapshots() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ClientPersistenceActor(modelContainer: container)
        let repository = DefaultClientRepository(persistenceActor: actor, observationSignal: ClientObservationSignal())
        var observation = await repository.observeClients().makeAsyncIterator()
        #expect(try await observation.next() == [])

        let id = ClientID(rawValue: UUID())
        let created = try await repository.createClient(id: id, profile: ClientProfile(displayName: "First profile"))
        #expect(try await observation.next() == [created])
        let edited = try await repository.updateClient(id: id, profile: ClientProfile(displayName: "Edited profile"))
        #expect(try await observation.next() == [edited])
        try await repository.deactivateClient(id)
        #expect(try await observation.next() == [])
        #expect(try await repository.client(id: id) == nil)

        let context = ModelContext(container)
        let retained = try #require(context.fetch(FetchDescriptor<ClientModel>()).first)
        #expect(try retained.toDomain() == edited)
        let operations = try await actor.pendingOperations()
        #expect(operations.count == 3)
        guard case .delete(let deletion) = operations.last else {
            Issue.record("Expected the causal deletion after both profile edits")
            return
        }
        #expect(deletion.predecessorOperationID == operations[1].operationID)
    }

    @Test("Contextual editing preserves consent and publishes through the shared local observation")
    @MainActor
    func contextualEditingPreservesConsent() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let signal = ClientObservationSignal()
        let repository = DefaultClientRepository(
            persistenceActor: ClientPersistenceActor(modelContainer: container),
            observationSignal: signal
        )
        let adapter = ClientContextualPersistenceAdapter(observationSignal: signal)
        let original = Client(
            id: ClientID(rawValue: UUID()),
            displayName: "Before edit",
            taxIdentifier: nil,
            billingAddress: nil,
            status: .active(consentReference: try ClientConsentReference(rawValue: "fixture-consent/context"))
        )
        try ClientLocalDataSource().upsert(original, in: ModelContext(container))
        var observation = await repository.observeClients().makeAsyncIterator()
        #expect(try await observation.next() == [original])

        let edited = try await adapter.update(
            id: original.id,
            profile: ClientProfile(displayName: "After edit", taxIdentifier: "SYNTHETIC-02"),
            in: container.mainContext
        )
        #expect(try await observation.next() == [edited])
        #expect(edited.status == original.status)
        #expect(edited.id == original.id)
        #expect(edited.displayName == "After edit")
        try await adapter.deactivate(original.id, in: container.mainContext)
        #expect(try await observation.next() == [])
        #expect(try ModelContext(container).fetch(FetchDescriptor<ClientModel>()).first?.toDomain() == edited)
    }

    @Test("Rejected CRUD leaves existing caller changes and durable storage untouched")
    @MainActor
    func dirtyContextRejectsCRUDWithoutDiscardingCallerChanges() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let context = container.mainContext
        context.autosaveEnabled = false
        let unrelated = Client.draft(id: ClientID(rawValue: UUID()), displayName: "Unsaved caller work")
        context.insert(ClientModel(unrelated))
        let adapter = ClientContextualPersistenceAdapter(observationSignal: ClientObservationSignal())

        await #expect(throws: ClientError.persistenceUnavailable) {
            try await adapter.create(
                id: ClientID(rawValue: UUID()),
                profile: ClientProfile(displayName: "Rejected profile"),
                in: context
            )
        }

        #expect(context.hasChanges)
        #expect(try context.fetch(FetchDescriptor<ClientModel>()).map(\.id) == [unrelated.id.rawValue])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientModel>()) == 0)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 0)
    }

    @Test("Local CRUD reports duplicate, missing and deactivated identities without new operations")
    func rejectedIdentitiesDoNotCreateOperations() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ClientPersistenceActor(modelContainer: container)
        let repository = DefaultClientRepository(persistenceActor: actor, observationSignal: ClientObservationSignal())
        let id = ClientID(rawValue: UUID())
        let profile = try ClientProfile(displayName: "Original profile")
        _ = try await repository.createClient(id: id, profile: profile)

        await #expect(throws: ClientError.alreadyExists) {
            try await repository.createClient(id: id, profile: ClientProfile(displayName: "Duplicate replacement"))
        }
        await #expect(throws: ClientError.notFound) {
            try await repository.updateClient(id: ClientID(rawValue: UUID()), profile: profile)
        }
        await #expect(throws: ClientError.notFound) {
            try await repository.deactivateClient(ClientID(rawValue: UUID()))
        }
        #expect(try await actor.pendingOperations().count == 1)
        try await repository.deactivateClient(id)
        try await repository.deactivateClient(id)
        await #expect(throws: ClientError.deactivated) {
            try await repository.updateClient(id: id, profile: profile)
        }
        #expect(try await actor.pendingOperations().count == 2)
    }

    @Test
    func `a persisted conflict rejects profile editing without a new operation`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ClientPersistenceActor(modelContainer: container)
        let repository = DefaultClientRepository(persistenceActor: actor, observationSignal: ClientObservationSignal())
        let id = ClientID(rawValue: UUID(uuidString: "08010002-0000-0000-0000-000000000001")!)
        let operationID = UUID(uuidString: "08010002-0000-0000-0000-000000000002")!
        let original = Client.draft(id: id, displayName: "Local profile in conflict")
        try await actor.persistPendingUpsert(original, operationID: operationID)
        let operation = try #require(try await actor.pendingUpserts().first)
        let remoteRecord = ClientRemoteRecord(
            client: ClientDTO(Client.draft(id: id, displayName: "Concurrent remote profile")),
            version: .versioned(revision: 4, lastOperationID: UUID(uuidString: "08010002-0000-0000-0000-000000000003")!)
        )
        try await actor.recordConflict(operation: operation, reason: .baseChanged, remoteRecord: remoteRecord)

        await #expect(throws: ClientError.conflict) {
            try await repository.updateClient(id: id, profile: ClientProfile(displayName: "Blocked profile change"))
        }

        #expect(try await repository.client(id: id) == original)
        #expect(try await actor.pendingOperations().map(\.operationID) == [operationID])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ClientSyncConflictModel>()) == 1)
    }

    @Test
    @MainActor
    func `a rejected durable save maps the failure and rolls back the profile and queue`() async throws {
        let schema = Schema.franAlonso
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-ClientCRUD-ReadOnly-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        let storeURL = directoryURL.appending(path: "Clients.store", directoryHint: .notDirectory)
        let writableConfiguration = ModelConfiguration(
            "WritableClientCRUD",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        _ = try ModelContainer(for: schema, configurations: [writableConfiguration])
        let readOnlyConfiguration = ModelConfiguration(
            "ReadOnlyClientCRUD",
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [readOnlyConfiguration])
        let context = container.mainContext
        context.autosaveEnabled = false
        let adapter = ClientContextualPersistenceAdapter(observationSignal: ClientObservationSignal())
        let id = ClientID(rawValue: UUID(uuidString: "08010002-0000-0000-0000-000000000004")!)

        await #expect(throws: ClientError.persistenceUnavailable) {
            try await adapter.create(id: id, profile: ClientProfile(displayName: "Rejected profile"), in: context)
        }

        #expect(!context.hasChanges)
        #expect(try ClientLocalDataSource().fetchAll(in: context).isEmpty)
        #expect(try ClientLocalDataSource().client(id: id, in: context) == nil)
        #expect(try context.fetchCount(FetchDescriptor<ClientModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 0)
        let verificationContext = ModelContext(container)
        #expect(try verificationContext.fetchCount(FetchDescriptor<ClientModel>()) == 0)
        #expect(try verificationContext.fetchCount(FetchDescriptor<ClientPendingUpsertModel>()) == 0)
        #expect(try verificationContext.fetchCount(FetchDescriptor<ClientPendingDeleteModel>()) == 0)
    }
}
