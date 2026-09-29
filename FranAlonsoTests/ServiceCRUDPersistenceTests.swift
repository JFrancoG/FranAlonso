import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service CRUD local acceptance", .timeLimit(.minutes(1)))
struct ServiceCRUDPersistenceTests {
    @Test
    @MainActor
    func `a reused operation identity rolls back an edit without changing accepted commercial values`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let operationID = UUID()
        let adapter = ServiceContextualPersistenceAdapter(
            observationSignal: ServiceObservationSignal(),
            operationID: { operationID }
        )
        let id = ServiceID(rawValue: UUID())
        _ = try await adapter.create(id: id, profile: serviceCRUDProfile(name: "Accepted"), in: container.mainContext)
        let dataSource = ServiceLocalDataSource()
        let pending = try dataSource.pendingOperations(in: container.mainContext)

        await #expect(throws: ServiceError.persistenceUnavailable) {
            try await adapter.update(id: id, profile: serviceCRUDProfile(name: "Rejected"), in: container.mainContext)
        }

        let verification = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verification) == [makeService(id: id.rawValue, name: "Accepted")])
        #expect(try dataSource.pendingOperations(in: verification) == pending)
        #expect(!container.mainContext.hasChanges)
    }

    @Test(arguments: [false, true])
    @MainActor
    func `both write routes replace every commercial field and retain inactive product links`(
        _ contextual: Bool
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ServicePersistenceActor(modelContainer: container)
        let signal = ServiceObservationSignal()
        let repository = DefaultServiceRepository(persistenceActor: actor, observationSignal: signal)
        let adapter = ServiceContextualPersistenceAdapter(observationSignal: signal)
        let id = ServiceID(rawValue: UUID())
        let linkedID = ProductID(rawValue: UUID())
        let initial = try serviceCRUDProfile(name: "Before")
        let changed = try ServiceProfile(
            name: "  Champú  especial  ",
            type: .product,
            linkedProductID: linkedID,
            price: Money(amount: Decimal(string: "47.83")!, currency: .usd),
            taxRate: TaxRate(percentage: Decimal(string: "7.25")!),
            discount: nil
        )

        if contextual {
            _ = try await adapter.create(id: id, profile: initial, in: container.mainContext)
            try await adapter.deactivate(id, in: container.mainContext)
            _ = try await adapter.update(id: id, profile: changed, in: container.mainContext)
        } else {
            _ = try await repository.createService(id: id, profile: initial)
            try await repository.deactivateService(id)
            _ = try await repository.updateService(id: id, profile: changed)
        }

        let expected = try makeService(
            id: id.rawValue,
            name: "Champú  especial",
            type: .product,
            linkedProductID: linkedID.rawValue,
            priceAmount: Decimal(string: "47.83")!,
            currency: .usd,
            taxPercentage: Decimal(string: "7.25")!,
            discountPercentage: nil,
            status: .inactive
        )
        #expect(try await repository.service(id: id) == expected)
        let pending = try await actor.pendingUpserts()
        try #require(pending.count == 3)
        let persisted = try ServiceLocalDataSource().fetchAll(in: ModelContext(container))
        #expect(persisted == [expected])
        let payload = try #require(pending.last).service
        #expect(payload.price.amount.decimal == Decimal(string: "47.83"))
        #expect(payload.taxRate.percentage.decimal == Decimal(string: "7.25"))
        #expect(payload.discount == nil)
        #expect(payload.linkedProductID == linkedID.rawValue.uuidString)

        let identifiers = pending.map(\.operationID)
        try await repository.deactivateService(id)
        #expect(try await actor.pendingUpserts().map(\.operationID) == identifiers)
        #expect(try await repository.service(id: id) == expected)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ProductModel>()) == 0)
    }

    @Test(arguments: [false, true])
    func `an identity retained only by remote state or pending work cannot be reused`(_ remote: Bool) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let context = ModelContext(container)
        let original = try makeService()
        let dataSource = ServiceLocalDataSource()
        if remote {
            context.insert(try ServiceRemoteStateModel(record: ServiceRemoteRecord(
                service: ServiceDTO(original),
                version: .versioned(revision: 3, lastOperationID: UUID())
            )))
        } else {
            context.insert(try ServicePendingUpsertModel(
                serviceID: original.id.rawValue,
                operationID: UUID(),
                predecessorOperationID: nil,
                base: .absent,
                payload: ServiceDTO(original)
            ))
        }
        try context.save()
        let pending = try dataSource.pendingOperations(in: context)

        #expect(throws: ServiceError.alreadyExists) {
            try dataSource.createService(
                id: original.id,
                profile: serviceCRUDProfile(name: "Replacement"),
                operationID: UUID(),
                in: context
            )
        }

        #expect(try dataSource.fetchAll(in: ModelContext(container)).isEmpty)
        #expect(try dataSource.pendingOperations(in: context) == pending)
    }

    @Test
    func `prior cancellation cannot mutate the actor source or its causal queue`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ServicePersistenceActor(modelContainer: container)
        let repository = DefaultServiceRepository(
            persistenceActor: actor,
            observationSignal: ServiceObservationSignal()
        )
        let original = try makeService()
        try await actor.upsert(original)
        let profile = try serviceCRUDProfile(name: "Cancelled")
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            await #expect(throws: CancellationError.self) {
                try await repository.updateService(id: original.id, profile: profile)
            }
            await #expect(throws: CancellationError.self) {
                try await repository.deactivateService(original.id)
            }
            await #expect(throws: CancellationError.self) {
                try await repository.createService(id: ServiceID(rawValue: UUID()), profile: profile)
            }
            await #expect(throws: CancellationError.self) {
                try await repository.service(id: original.id)
            }
        }
        task.cancel()
        gate.continuation.finish()
        await task.value

        #expect(try await actor.fetchAll() == [original])
        #expect(try await actor.pendingOperations().isEmpty)
    }

    @Test
    func `CRUD publishes committed snapshots and deactivation retains an upsert chain`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ServicePersistenceActor(modelContainer: container)
        let repository = DefaultServiceRepository(
            persistenceActor: actor,
            observationSignal: ServiceObservationSignal()
        )
        var observation = await repository.observeServices().makeAsyncIterator()
        #expect(try await observation.next() == [])
        let id = ServiceID(rawValue: UUID())

        let created = try await repository.createService(id: id, profile: serviceCRUDProfile(name: "First"))
        #expect(try await observation.next() == [created])
        let edited = try await repository.updateService(id: id, profile: serviceCRUDProfile(name: "Edited"))
        #expect(try await observation.next() == [edited])
        try await repository.deactivateService(id)
        let inactive = try makeService(id: id.rawValue, name: "Edited", status: .inactive)
        #expect(try await observation.next() == [inactive])
        let operationIDs = try await actor.pendingOperations().map(\.operationID)
        try await repository.deactivateService(id)

        #expect(try await repository.service(id: id) == inactive)
        #expect(try await actor.pendingOperations().map(\.operationID) == operationIDs)
        let upserts = try await actor.pendingUpserts()
        try #require(upserts.count == 3)
        #expect(upserts.last?.predecessorOperationID == upserts[1].operationID)
        let verification = ModelContext(container)
        #expect(try ServiceLocalDataSource().fetchAll(in: verification) == [inactive])
        #expect(try verification.fetchCount(FetchDescriptor<ServicePendingDeleteModel>()) == 0)
    }

    @Test
    func `duplicate and missing identities leave the accepted service and queue unchanged`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ServicePersistenceActor(modelContainer: container)
        let repository = DefaultServiceRepository(
            persistenceActor: actor,
            observationSignal: ServiceObservationSignal()
        )
        let id = ServiceID(rawValue: UUID())
        let profile = try serviceCRUDProfile(name: "Original")
        let original = try await repository.createService(id: id, profile: profile)
        let operations = try await actor.pendingOperations()

        await #expect(throws: ServiceError.alreadyExists) {
            try await repository.createService(id: id, profile: serviceCRUDProfile(name: "Replacement"))
        }
        await #expect(throws: ServiceError.notFound) {
            try await repository.updateService(id: ServiceID(rawValue: UUID()), profile: profile)
        }
        await #expect(throws: ServiceError.notFound) {
            try await repository.deactivateService(ServiceID(rawValue: UUID()))
        }

        #expect(try await repository.service(id: id) == original)
        #expect(try await actor.pendingOperations() == operations)
    }

    @Test(arguments: [false, true])
    func `pending and remote tombstones cannot be recreated edited or deactivated`(_ remote: Bool) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ServicePersistenceActor(modelContainer: container)
        let id = ServiceID(rawValue: UUID())
        if remote {
            try await actor.recordRemoteObservation(ServiceRemoteRecord(
                content: .tombstone(serviceID: id.rawValue),
                version: .versioned(revision: 2, lastOperationID: UUID()),
                changeSequence: 2
            ))
        } else {
            try await actor.upsert(makeService(id: id.rawValue, name: "Removed", status: .active))
            try await actor.persistPendingDelete(id, operationID: UUID())
        }
        let repository = DefaultServiceRepository(
            persistenceActor: actor,
            observationSignal: ServiceObservationSignal()
        )
        let pendingBefore = try await actor.pendingOperations()
        let profile = try serviceCRUDProfile(name: "Resurrection attempt")

        #expect(try await repository.service(id: id) == nil)
        await #expect(throws: ServiceError.alreadyExists) {
            try await repository.createService(id: id, profile: profile)
        }
        await #expect(throws: ServiceError.deleted) {
            try await repository.updateService(id: id, profile: profile)
        }
        await #expect(throws: ServiceError.deleted) {
            try await repository.deactivateService(id)
        }

        #expect(try await actor.pendingOperations() == pendingBefore)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ServiceModel>()) == 0)
    }

    @Test
    func `an acknowledged inactive service is not queued again by repeated deactivation`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ServicePersistenceActor(modelContainer: container)
        let inactive = try makeService(id: UUID(), name: "Retained", status: .inactive)
        let operationID = UUID()
        try await actor.persistPendingUpsert(inactive, operationID: operationID)
        let record = ServiceRemoteRecord(
            service: try ServiceDTO(inactive),
            version: .versioned(revision: 1, lastOperationID: operationID)
        )
        try await actor.acknowledge(operationID: operationID, record: record)
        let repository = DefaultServiceRepository(
            persistenceActor: actor,
            observationSignal: ServiceObservationSignal()
        )

        try await repository.deactivateService(inactive.id)

        #expect(try await repository.service(id: inactive.id) == inactive)
        #expect(try await actor.pendingOperations().isEmpty)
        let states = try ModelContext(container).fetch(FetchDescriptor<ServiceRemoteStateModel>())
        #expect(try #require(states.first).decodeRecord() == record)
    }

    @Test
    @MainActor
    func `contextual commands share the causal route and preserve current inactive state`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ServicePersistenceActor(modelContainer: container)
        let signal = ServiceObservationSignal()
        let repository = DefaultServiceRepository(persistenceActor: actor, observationSignal: signal)
        let adapter = ServiceContextualPersistenceAdapter(observationSignal: signal)
        let id = ServiceID(rawValue: UUID())
        var observation = await repository.observeServices().makeAsyncIterator()
        #expect(try await observation.next() == [])

        let created = try await adapter.create(
            id: id,
            profile: serviceCRUDProfile(name: "Before"),
            in: container.mainContext
        )
        #expect(try await observation.next() == [created])
        try await adapter.deactivate(id, in: container.mainContext)
        #expect(try await observation.next() == [makeService(id: id.rawValue, name: "Before", status: .inactive)])
        let edited = try await adapter.update(
            id: id,
            profile: serviceCRUDProfile(name: "After"),
            in: container.mainContext
        )
        #expect(try await observation.next() == [makeService(id: id.rawValue, name: "After", status: .inactive)])

        #expect(edited.status == .inactive)
        #expect(try ServiceLocalDataSource().fetchAll(in: ModelContext(container)) == [edited])
        #expect(try await actor.pendingUpserts().count == 3)
    }

    @Test(arguments: [ServiceStatus.active, .inactive])
    func `conflicts block renaming and deactivation without modifying the queued snapshot`(
        _ status: ServiceStatus
    ) async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let actor = ServicePersistenceActor(modelContainer: container)
        let original = try makeService(id: UUID(), name: "Local", status: status)
        let operationID = UUID()
        try await actor.persistPendingUpsert(original, operationID: operationID)
        let operation = try #require(try await actor.pendingUpserts().first)
        let remote = try makeService(id: original.id.rawValue, name: "Remote", status: .active)
        try await actor.recordConflict(
            operation: operation,
            reason: .baseChanged,
            remoteRecord: ServiceRemoteRecord(
                service: try ServiceDTO(remote),
                version: .versioned(revision: 4, lastOperationID: UUID())
            )
        )
        let repository = DefaultServiceRepository(
            persistenceActor: actor,
            observationSignal: ServiceObservationSignal()
        )

        await #expect(throws: ServiceError.conflict) {
            try await repository.updateService(id: original.id, profile: serviceCRUDProfile(name: "Blocked"))
        }
        await #expect(throws: ServiceError.conflict) {
            try await repository.deactivateService(original.id)
        }

        #expect(try await repository.service(id: original.id) == original)
        #expect(try await actor.pendingOperations().map(\.operationID) == [operationID])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ServiceSyncConflictModel>()) == 1)
    }

    @Test
    @MainActor
    func `a dirty caller context is rejected without discarding unsaved work`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let context = container.mainContext
        context.autosaveEnabled = false
        let unrelated = try makeService(id: UUID(), name: "Unsaved", status: .active)
        context.insert(try ServiceModel(unrelated))
        let adapter = ServiceContextualPersistenceAdapter(observationSignal: ServiceObservationSignal())

        await #expect(throws: ServiceError.persistenceUnavailable) {
            try await adapter.create(
                id: ServiceID(rawValue: UUID()),
                profile: serviceCRUDProfile(name: "Rejected"),
                in: context
            )
        }

        #expect(context.hasChanges)
        #expect(try context.fetch(FetchDescriptor<ServiceModel>()).map(\.id) == [unrelated.id.rawValue])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ServiceModel>()) == 0)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<ServicePendingUpsertModel>()) == 0)
    }

    @Test
    @MainActor
    func `a rejected durable save rolls back service and causal work and exposes a neutral error`() async throws {
        let schema = Schema.franAlonso
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-ServiceCRUD-ReadOnly-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appending(path: "Services.store", directoryHint: .notDirectory)
        let writable = ModelConfiguration(
            "WritableServiceCRUD",
            schema: schema,
            url: url,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        _ = try ModelContainer(for: schema, configurations: [writable])
        let readOnly = ModelConfiguration(
            "ReadOnlyServiceCRUD",
            schema: schema,
            url: url,
            allowsSave: false,
            cloudKitDatabase: .none
        )
        let container = try ModelContainer(for: schema, configurations: [readOnly])
        let context = container.mainContext
        context.autosaveEnabled = false
        let adapter = ServiceContextualPersistenceAdapter(observationSignal: ServiceObservationSignal())

        await #expect(throws: ServiceError.persistenceUnavailable) {
            try await adapter.create(
                id: ServiceID(rawValue: UUID()),
                profile: serviceCRUDProfile(name: "Rejected"),
                in: context
            )
        }

        #expect(!context.hasChanges)
        #expect(try ServiceLocalDataSource().fetchAll(in: context).isEmpty)
        #expect(try context.fetchCount(FetchDescriptor<ServicePendingUpsertModel>()) == 0)
        let verification = ModelContext(container)
        #expect(try verification.fetchCount(FetchDescriptor<ServiceModel>()) == 0)
        #expect(try verification.fetchCount(FetchDescriptor<ServicePendingUpsertModel>()) == 0)
        #expect(try verification.fetchCount(FetchDescriptor<ServicePendingDeleteModel>()) == 0)
    }
}

private func serviceCRUDProfile(name: String) throws -> ServiceProfile {
    try ServiceProfile(
        name: name,
        type: .professional,
        price: Money(amount: 29.95, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: Discount(percentage: 10)
    )
}
