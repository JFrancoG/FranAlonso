import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Clients local-first repository")
struct DefaultClientRepositoryTests {
    @Test("A pending upsert persists the client and its operation snapshot together")
    func pendingUpsertPersistsClientAndOperationSnapshotTogether() throws {
        let container = try makeRepositoryContainer()
        let context = ModelContext(container)
        let client = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000001",
            displayName: "Ana Alonso"
        )
        let operationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000001"
        )

        try ClientLocalDataSource().persistPendingUpsert(
            client,
            operationID: operationID,
            in: context
        )

        let verificationContext = ModelContext(container)
        let operation = try #require(
            verificationContext.fetch(
                FetchDescriptor<ClientPendingUpsertModel>()
            ).only
        )
        #expect(
            try ClientLocalDataSource().fetchAll(in: verificationContext) == [client]
        )
        #expect(operation.clientID == client.id.rawValue)
        #expect(operation.operationID == operationID)
        #expect(operation.payloadVersion == 1)
        #expect(try operation.decodePayload() == ClientDTO(client))
    }

    @Test("A rejected save rolls back the attempted client and pending operation")
    func rejectedSaveRollsBackAttemptedMutation() throws {
        let schema = Schema([
            ClientModel.self,
            ClientPendingUpsertModel.self,
            ClientPendingDeleteModel.self,
            ClientRemoteStateModel.self,
            ClientSyncConflictModel.self,
            ClientSyncCursorModel.self
        ])
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-ReadOnly-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directoryURL,
            withIntermediateDirectories: true
        )
        defer {
            try? FileManager.default.removeItem(at: directoryURL)
        }
        let storeURL = directoryURL.appending(
            path: "Clients.store",
            directoryHint: .notDirectory
        )
        let writableConfiguration = ModelConfiguration(
            "WritableClients",
            schema: schema,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        _ = try ModelContainer(
            for: schema,
            configurations: [writableConfiguration]
        )
        let readOnlyConfiguration = ModelConfiguration(
            "ReadOnlyClients",
            schema: schema,
            url: storeURL,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(
            for: schema,
            configurations: [readOnlyConfiguration]
        )
        let context = ModelContext(container)
        context.autosaveEnabled = false
        let client = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000009",
            displayName: "Rejected write"
        )

        do {
            try ClientLocalDataSource().persistPendingUpsert(
                client,
                operationID: try repositoryUUID(
                    "40000000-0000-0000-0000-000000000009"
                ),
                in: context
            )
            Issue.record("A read-only container unexpectedly accepted a save")
        } catch {}

        #expect(!context.hasChanges)
        let verificationContext = ModelContext(container)
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ClientModel>()
            ) == 0
        )
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ClientPendingUpsertModel>()
            ) == 0
        )
    }

    @Test("Existing caller changes are preserved instead of joined to a pending upsert")
    func existingCallerChangesArePreserved() throws {
        let container = try makeRepositoryContainer()
        let corruptionContext = ModelContext(container)
        corruptionContext.insert(
            ClientModel(
                id: try repositoryUUID(
                    "30000000-0000-0000-0000-000000000013"
                ),
                displayName: "Corrupt durable row",
                taxIdentifier: nil,
                billingStreetLine: nil,
                billingPostalCode: nil,
                billingCity: nil,
                billingProvince: nil,
                statusRawValue: "suspended",
                consentReference: nil
            )
        )
        try corruptionContext.save()
        let operationContext = ModelContext(container)
        operationContext.autosaveEnabled = false
        let unrelatedClient = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000014",
            displayName: "Unrelated draft"
        )
        operationContext.insert(ClientModel(unrelatedClient))
        let attemptedClient = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000015",
            displayName: "Attempted pending upsert"
        )

        #expect(throws: ClientLocalDataSourceError.contextHasUncommittedChanges) {
            try ClientLocalDataSource().persistPendingUpsert(
                attemptedClient,
                operationID: try repositoryUUID(
                    "40000000-0000-0000-0000-000000000015"
                ),
                in: operationContext
            )
        }

        #expect(operationContext.hasChanges)
        let operationContextIDs = Set(
            try operationContext.fetch(
                FetchDescriptor<ClientModel>()
            ).map(\.id)
        )
        #expect(operationContextIDs.contains(unrelatedClient.id.rawValue))
        #expect(!operationContextIDs.contains(attemptedClient.id.rawValue))
        let verificationContext = ModelContext(container)
        let durableClients = try verificationContext.fetch(
            FetchDescriptor<ClientModel>()
        )
        #expect(durableClients.map(\.id) == [try repositoryUUID(
            "30000000-0000-0000-0000-000000000013"
        )])
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ClientPendingUpsertModel>()
            ) == 0
        )
    }

    @Test("An identical pending upsert preserves its operation identity")
    func identicalPendingUpsertPreservesOperationIdentity() throws {
        let container = try makeRepositoryContainer()
        let dataSource = ClientLocalDataSource()
        let client = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000002",
            displayName: "Same snapshot"
        )
        let originalOperationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000002"
        )
        let replacementOperationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            client,
            operationID: originalOperationID,
            in: ModelContext(container)
        )

        try dataSource.persistPendingUpsert(
            client,
            operationID: replacementOperationID,
            in: ModelContext(container)
        )

        let operation = try #require(
            ModelContext(container).fetch(
                FetchDescriptor<ClientPendingUpsertModel>()
            ).only
        )
        #expect(operation.operationID == originalOperationID)
        #expect(try operation.decodePayload() == ClientDTO(client))
    }

    @Test("A changed pending upsert appends an immutable causal successor")
    func changedPendingUpsertAppendsImmutableCausalSuccessor() throws {
        let container = try makeRepositoryContainer()
        let dataSource = ClientLocalDataSource()
        let identifier = "30000000-0000-0000-0000-000000000003"
        let initialClient = try repositoryClient(
            id: identifier,
            displayName: "Initial snapshot"
        )
        let updatedClient = try repositoryClient(
            id: identifier,
            displayName: "Updated snapshot"
        )
        let originalOperationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000004"
        )
        let updatedOperationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000005"
        )
        try dataSource.persistPendingUpsert(
            initialClient,
            operationID: originalOperationID,
            in: ModelContext(container)
        )

        try dataSource.persistPendingUpsert(
            updatedClient,
            operationID: updatedOperationID,
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        let operations = try verificationContext.fetch(
            FetchDescriptor<ClientPendingUpsertModel>()
        )
        #expect(operations.count == 2)
        let originalOperation = try #require(
            operations.first { $0.operationID == originalOperationID }
        )
        let updatedOperation = try #require(
            operations.first { $0.operationID == updatedOperationID }
        )
        #expect(originalOperation.predecessorOperationID == nil)
        #expect(try originalOperation.decodePayload() == ClientDTO(initialClient))
        #expect(updatedOperation.predecessorOperationID == originalOperationID)
        #expect(try updatedOperation.decodePayload() == ClientDTO(updatedClient))
        #expect(
            try dataSource.fetchAll(in: verificationContext) == [updatedClient]
        )
    }

    @Test("Repository observation publishes its local write")
    func repositoryObservationPublishesItsLocalWrite() async throws {
        let container = try makeRepositoryContainer()
        let repository = makeRepository(
            container: container,
            operationID: try repositoryUUID(
                "40000000-0000-0000-0000-000000000006"
            )
        )
        let client = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000004",
            displayName: "Repository route"
        )
        let stream = await repository.observeClients()
        var observation = stream.makeAsyncIterator()

        #expect(try await observation.next() == [])
        try await repository.saveClient(client)

        #expect(try await observation.next() == [client])
    }

    @Test("A delayed change signal reloads the current SwiftData snapshot")
    func delayedChangeSignalReloadsCurrentSnapshot() async throws {
        let container = try makeRepositoryContainer()
        let persistenceActor = ClientPersistenceActor(
            modelContainer: container
        )
        let observationSignal = ClientObservationSignal()
        let operationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000010"
        )
        let repository = DefaultClientRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            operationID: { operationID }
        )
        let client = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000010",
            displayName: "Newest durable snapshot"
        )
        let stream = await repository.observeClients()
        var observation = stream.makeAsyncIterator()
        #expect(try await observation.next() == [])

        try await persistenceActor.persistPendingUpsert(
            client,
            operationID: operationID
        )
        await observationSignal.publishChange()

        #expect(try await observation.next() == [client])
    }

    @Test("A mapping failure prevents the new local write from being committed")
    func mappingFailurePreventsCommit() async throws {
        let container = try makeRepositoryContainer()
        let corruptionContext = ModelContext(container)
        corruptionContext.insert(
            ClientModel(
                id: try repositoryUUID(
                    "30000000-0000-0000-0000-000000000011"
                ),
                displayName: "Corrupt existing row",
                taxIdentifier: nil,
                billingStreetLine: nil,
                billingPostalCode: nil,
                billingCity: nil,
                billingProvince: nil,
                statusRawValue: "suspended",
                consentReference: nil
            )
        )
        try corruptionContext.save()
        let client = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000012",
            displayName: "Must not commit"
        )
        let repository = makeRepository(
            container: container,
            operationID: try repositoryUUID(
                "40000000-0000-0000-0000-000000000012"
            )
        )

        await #expect(
            throws: ClientMappingError.invalidPersistedStatus("suspended")
        ) {
            try await repository.saveClient(client)
        }

        let verificationContext = ModelContext(container)
        let clientModels = try verificationContext.fetch(
            FetchDescriptor<ClientModel>()
        )
        #expect(clientModels.map(\.id) == [try repositoryUUID(
            "30000000-0000-0000-0000-000000000011"
        )])
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ClientPendingUpsertModel>()
            ) == 0
        )
    }

    @MainActor
    @Test("The contextual route matches the repository and updates its observation")
    func contextualRouteMatchesRepositoryAndUpdatesObservation() async throws {
        let repositoryContainer = try makeRepositoryContainer()
        let contextualContainer = try makeRepositoryContainer()
        let operationID = try repositoryUUID(
            "40000000-0000-0000-0000-000000000007"
        )
        let repositorySignal = ClientObservationSignal()
        let contextualSignal = ClientObservationSignal()
        let repository = DefaultClientRepository(
            persistenceActor: ClientPersistenceActor(
                modelContainer: repositoryContainer
            ),
            observationSignal: repositorySignal,
            operationID: { operationID }
        )
        let contextualRepository = DefaultClientRepository(
            persistenceActor: ClientPersistenceActor(
                modelContainer: contextualContainer
            ),
            observationSignal: contextualSignal,
            operationID: { operationID }
        )
        let adapter = ClientContextualPersistenceAdapter(
            observationSignal: contextualSignal,
            operationID: { operationID }
        )
        let client = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000005",
            displayName: "Both routes"
        )
        let stream = await contextualRepository.observeClients()
        var contextualObservation = stream.makeAsyncIterator()
        #expect(try await contextualObservation.next() == [])

        try await repository.saveClient(client)
        try await adapter.save(
            client,
            in: contextualContainer.mainContext
        )

        #expect(try await contextualObservation.next() == [client])
        let repositoryState = try persistedState(in: repositoryContainer)
        let contextualState = try persistedState(in: contextualContainer)
        #expect(repositoryState == contextualState)
    }

    @Test("Cancelling an observation releases its pending iteration")
    func cancellingObservationReleasesPendingIteration() async throws {
        let repository = makeRepository(
            container: try makeRepositoryContainer(),
            operationID: try repositoryUUID(
                "40000000-0000-0000-0000-000000000008"
            )
        )
        let started = AsyncStream.makeStream(of: Void.self)
        let pendingIteration = Task {
            let stream = await repository.observeClients()
            var observation = stream.makeAsyncIterator()
            _ = try await observation.next()
            started.continuation.yield()
            return try await observation.next()
        }
        var startedIterator = started.stream.makeAsyncIterator()
        _ = await startedIterator.next()

        pendingIteration.cancel()

        switch await pendingIteration.result {
        case .success(nil):
            break
        case .failure(let error):
            #expect(error is CancellationError)
        case .success(.some):
            Issue.record("A cancelled observation unexpectedly emitted a snapshot")
        }
    }

    @Test("Live dependencies observe the supplied SwiftData container")
    func liveDependenciesObserveTheSuppliedSwiftDataContainer() async throws {
        let container = try makeRepositoryContainer()
        let client = try repositoryClient(
            id: "30000000-0000-0000-0000-000000000006",
            displayName: "Live composition"
        )
        try ClientLocalDataSource().upsert(
            client,
            in: ModelContext(container)
        )
        let dependencies = AppDependencies.live(modelContainer: container)
        let stream = await dependencies.observeClients()
        var observation = stream.makeAsyncIterator()

        #expect(try await observation.next() == [client])
    }
}

private struct PersistedClientState: Equatable {
    let clients: [Client]
    let operationID: UUID
    let payloadVersion: Int
    let payload: ClientDTO
}

private func makeRepository(
    container: ModelContainer,
    operationID: UUID
) -> DefaultClientRepository {
    DefaultClientRepository(
        persistenceActor: ClientPersistenceActor(modelContainer: container),
        observationSignal: ClientObservationSignal(),
        operationID: { operationID }
    )
}

private func makeRepositoryContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(
        for: Schema([
            ClientModel.self,
            ClientPendingUpsertModel.self,
            ClientPendingDeleteModel.self,
            ClientRemoteStateModel.self,
            ClientSyncConflictModel.self,
            ClientSyncCursorModel.self
        ])
    )
}

private func persistedState(in container: ModelContainer) throws -> PersistedClientState {
    let context = ModelContext(container)
    let operation = try #require(
        context.fetch(FetchDescriptor<ClientPendingUpsertModel>()).only
    )

    return PersistedClientState(
        clients: try ClientLocalDataSource().fetchAll(in: context),
        operationID: operation.operationID,
        payloadVersion: operation.payloadVersion,
        payload: try operation.decodePayload()
    )
}

private func repositoryClient(id: String, displayName: String) throws -> Client {
    Client.draft(
        id: ClientID(rawValue: try repositoryUUID(id)),
        displayName: displayName
    )
}

private func repositoryUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var only: Element? {
        count == 1 ? first : nil
    }
}
