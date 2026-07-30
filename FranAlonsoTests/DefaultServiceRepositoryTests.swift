import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Services local-first repository")
struct DefaultServiceRepositoryTests {
    @Test("A pending upsert persists the Service and its operation snapshot together")
    func pendingUpsertPersistsServiceAndOperationSnapshotTogether() throws {
        let container = try makeServiceRepositoryContainer()
        let context = ModelContext(container)
        let service = try repositoryService(
            id: "53000000-0000-0000-0000-000000000001",
            name: "Corte y peinado"
        )
        let operationID = try repositoryUUID(
            "53100000-0000-0000-0000-000000000001"
        )

        try ServiceLocalDataSource().persistPendingUpsert(
            service,
            operationID: operationID,
            in: context
        )

        let verificationContext = ModelContext(container)
        let operation = try #require(
            verificationContext.fetch(
                FetchDescriptor<ServicePendingUpsertModel>()
            ).onlyServiceElement
        )
        #expect(
            try ServiceLocalDataSource().fetchAll(in: verificationContext)
                == [service]
        )
        #expect(operation.serviceID == service.id.rawValue)
        #expect(operation.operationID == operationID)
        #expect(operation.predecessorOperationID == nil)
        #expect(operation.payloadVersion == 1)
        #expect(try operation.decodePayload() == ServiceDTO(service))
    }

    @Test("A pending delete removes the Service and appends one durable tombstone")
    func pendingDeleteRemovesServiceAndAppendsDurableTombstone() throws {
        let container = try makeServiceRepositoryContainer()
        let dataSource = ServiceLocalDataSource()
        let service = try repositoryService(
            id: "53000000-0000-0000-0000-000000000002",
            name: "Service to delete"
        )
        let upsertOperationID = try repositoryUUID(
            "53100000-0000-0000-0000-000000000002"
        )
        let deleteOperationID = try repositoryUUID(
            "53100000-0000-0000-0000-000000000003"
        )
        try dataSource.persistPendingUpsert(
            service,
            operationID: upsertOperationID,
            in: ModelContext(container)
        )

        try dataSource.persistPendingDelete(
            service.id,
            operationID: deleteOperationID,
            in: ModelContext(container)
        )

        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)
        let deletion = try #require(
            verificationContext.fetch(
                FetchDescriptor<ServicePendingDeleteModel>()
            ).onlyServiceElement
        )
        #expect(deletion.serviceID == service.id.rawValue)
        #expect(deletion.operationID == deleteOperationID)
        #expect(deletion.predecessorOperationID == upsertOperationID)
        #expect(try deletion.decodeBase() == .absent)
        #expect(
            try dataSource.pendingOperations(in: verificationContext)
                .map(\.operationID) == [upsertOperationID, deleteOperationID]
        )

        try dataSource.persistPendingDelete(
            service.id,
            operationID: try repositoryUUID(
                "53100000-0000-0000-0000-000000000004"
            ),
            in: ModelContext(container)
        )

        let repeatedVerificationContext = ModelContext(container)
        let repeatedDeletions = try repeatedVerificationContext.fetch(
            FetchDescriptor<ServicePendingDeleteModel>()
        )
        #expect(repeatedDeletions.map(\.operationID) == [deleteOperationID])
    }

    @Test("A rejected save rolls back the attempted Service and pending operation")
    func rejectedSaveRollsBackAttemptedMutation() throws {
        let schema = serviceRepositorySchema()
        let directoryURL = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-Service-ReadOnly-\(UUID())",
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
            path: "Services.store",
            directoryHint: .notDirectory
        )
        let writableConfiguration = ModelConfiguration(
            "WritableServices",
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
            "ReadOnlyServices",
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
        let service = try repositoryService(
            id: "53000000-0000-0000-0000-000000000003",
            name: "Rejected write"
        )

        do {
            try ServiceLocalDataSource().persistPendingUpsert(
                service,
                operationID: try repositoryUUID(
                    "53100000-0000-0000-0000-000000000005"
                ),
                in: context
            )
            Issue.record("A read-only container unexpectedly accepted a save")
        } catch {}

        #expect(!context.hasChanges)
        let verificationContext = ModelContext(container)
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ServiceModel>()
            ) == 0
        )
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ServicePendingUpsertModel>()
            ) == 0
        )
    }

    @Test("A mapping failure rolls back a new local-first write")
    func mappingFailureRollsBackNewLocalFirstWrite() async throws {
        let container = try makeServiceRepositoryContainer()
        let corruptService = try repositoryService(
            id: "53000000-0000-0000-0000-000000000004",
            name: "Corrupt durable row"
        )
        let corruptModel = try ServiceModel(corruptService)
        corruptModel.statusRawValue = "suspended"
        let corruptionContext = ModelContext(container)
        corruptionContext.insert(corruptModel)
        try corruptionContext.save()
        let attemptedService = try repositoryService(
            id: "53000000-0000-0000-0000-000000000005",
            name: "Must not commit"
        )
        let repository = makeServiceRepository(
            container: container,
            operationID: try repositoryUUID(
                "53100000-0000-0000-0000-000000000006"
            )
        )

        await #expect(
            throws: ServiceMappingError.invalidPersistedStatus("suspended")
        ) {
            try await repository.saveService(attemptedService)
        }

        let verificationContext = ModelContext(container)
        #expect(
            try verificationContext.fetch(
                FetchDescriptor<ServiceModel>()
            ).map(\.id) == [corruptService.id.rawValue]
        )
        #expect(
            try verificationContext.fetchCount(
                FetchDescriptor<ServicePendingUpsertModel>()
            ) == 0
        )
    }

    @Test("Repository observation publishes its committed local Service write")
    func repositoryObservationPublishesItsCommittedLocalWrite() async throws {
        let container = try makeServiceRepositoryContainer()
        let repository = makeServiceRepository(
            container: container,
            operationID: try repositoryUUID(
                "53100000-0000-0000-0000-000000000007"
            )
        )
        let service = try repositoryService(
            id: "53000000-0000-0000-0000-000000000006",
            name: "Repository route"
        )
        let stream = await repository.observeServices()
        var observation = stream.makeAsyncIterator()

        #expect(try await observation.next() == [])
        try await repository.saveService(service)

        #expect(try await observation.next() == [service])
    }

    @Test("A delayed change signal reloads the current SwiftData Service snapshot")
    func delayedChangeSignalReloadsCurrentServiceSnapshot() async throws {
        let container = try makeServiceRepositoryContainer()
        let persistenceActor = ServicePersistenceActor(
            modelContainer: container
        )
        let observationSignal = ServiceObservationSignal()
        let operationID = try repositoryUUID(
            "53100000-0000-0000-0000-000000000008"
        )
        let repository = DefaultServiceRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            operationID: { operationID }
        )
        let service = try repositoryService(
            id: "53000000-0000-0000-0000-000000000007",
            name: "Newest durable snapshot"
        )
        let stream = await repository.observeServices()
        var observation = stream.makeAsyncIterator()
        #expect(try await observation.next() == [])

        try await persistenceActor.persistPendingUpsert(
            service,
            operationID: operationID
        )
        await observationSignal.publishChange()

        #expect(try await observation.next() == [service])
    }

    @MainActor
    @Test("The contextual route matches the repository and updates observation")
    func contextualRouteMatchesRepositoryAndUpdatesObservation() async throws {
        let repositoryContainer = try makeServiceRepositoryContainer()
        let contextualContainer = try makeServiceRepositoryContainer()
        let operationID = try repositoryUUID(
            "53100000-0000-0000-0000-000000000009"
        )
        let repositorySignal = ServiceObservationSignal()
        let contextualSignal = ServiceObservationSignal()
        let repository = DefaultServiceRepository(
            persistenceActor: ServicePersistenceActor(
                modelContainer: repositoryContainer
            ),
            observationSignal: repositorySignal,
            operationID: { operationID }
        )
        let contextualRepository = DefaultServiceRepository(
            persistenceActor: ServicePersistenceActor(
                modelContainer: contextualContainer
            ),
            observationSignal: contextualSignal,
            operationID: { operationID }
        )
        let adapter = ServiceContextualPersistenceAdapter(
            observationSignal: contextualSignal,
            operationID: { operationID }
        )
        let linkedProductID = try repositoryUUID(
            "53200000-0000-0000-0000-000000000008"
        )
        let service = try repositoryService(
            id: "53000000-0000-0000-0000-000000000008",
            name: "Both routes",
            type: .product,
            linkedProductID: linkedProductID,
            priceAmount: 49.9,
            currency: .usd,
            taxPercentage: 8.5,
            discountPercentage: nil,
            status: .inactive
        )
        let stream = await contextualRepository.observeServices()
        var contextualObservation = stream.makeAsyncIterator()
        #expect(try await contextualObservation.next() == [])

        try await repository.saveService(service)
        try await adapter.save(
            service,
            in: contextualContainer.mainContext
        )

        #expect(try await contextualObservation.next() == [service])
        #expect(
            try persistedServiceState(in: repositoryContainer)
                == persistedServiceState(in: contextualContainer)
        )
    }
}

private struct PersistedServiceState: Equatable {
    let services: [Service]
    let operationID: UUID
    let payloadVersion: Int
    let payload: ServiceDTO
}

private func makeServiceRepository(
    container: ModelContainer,
    operationID: UUID
) -> DefaultServiceRepository {
    DefaultServiceRepository(
        persistenceActor: ServicePersistenceActor(modelContainer: container),
        observationSignal: ServiceObservationSignal(),
        operationID: { operationID }
    )
}

private func serviceRepositorySchema() -> Schema {
    Schema([
        ServiceModel.self,
        ServicePendingUpsertModel.self,
        ServicePendingDeleteModel.self,
        ServiceRemoteStateModel.self,
        ServiceSyncConflictModel.self,
        ServiceSyncCursorModel.self
    ])
}

private func makeServiceRepositoryContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: serviceRepositorySchema())
}

private func persistedServiceState(
    in container: ModelContainer
) throws -> PersistedServiceState {
    let context = ModelContext(container)
    let operation = try #require(
        context.fetch(
            FetchDescriptor<ServicePendingUpsertModel>()
        ).onlyServiceElement
    )

    return PersistedServiceState(
        services: try ServiceLocalDataSource().fetchAll(in: context),
        operationID: operation.operationID,
        payloadVersion: operation.payloadVersion,
        payload: try operation.decodePayload()
    )
}

private func repositoryService(
    id: String,
    name: String,
    type: ServiceType = .professional,
    linkedProductID: UUID? = nil,
    priceAmount: Decimal = 29.95,
    currency: Currency = .eur,
    taxPercentage: Decimal = 21,
    discountPercentage: Decimal? = 10,
    status: ServiceStatus = .active
) throws -> Service {
    try makeService(
        id: repositoryUUID(id),
        name: name,
        type: type,
        linkedProductID: linkedProductID,
        priceAmount: priceAmount,
        currency: currency,
        taxPercentage: taxPercentage,
        discountPercentage: discountPercentage,
        status: status
    )
}

private func repositoryUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}

private extension Array {
    var onlyServiceElement: Element? {
        count == 1 ? first : nil
    }
}
