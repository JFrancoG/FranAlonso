import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service commands through synchronization", .timeLimit(.minutes(1)))
struct ServiceCRUDSyncIntegrationTests {
    @Test
    func `CRUD converges to one inactive remote document and repeated deactivation does not write`() async throws {
        let fixture = try ServiceCRUDSyncFixture()
        let id = ServiceID(rawValue: try serviceSyncUUID("01"))
        let createID = try serviceSyncUUID("11")
        let editID = try serviceSyncUUID("12")
        let deactivateID = try serviceSyncUUID("13")
        let read = fixture.repository(operationID: createID)
        _ = try await CreateServiceUseCase(repository: read)(id: id, profile: serviceSyncProfile(name: "Before"))
        _ = try await UpdateServiceUseCase(repository: fixture.repository(operationID: editID))(
            id: id,
            profile: serviceSyncProfile(name: "After", product: true)
        )
        let deactivate = DeactivateServiceUseCase(repository: fixture.repository(operationID: deactivateID))
        try await deactivate(id)
        let remote = ServiceSyncRemoteFake()
        let engine = fixture.engine(remote: remote)

        try await engine.synchronize()
        try await engine.synchronize()
        try await deactivate(id)
        try await engine.synchronize()

        let expected = try ServiceRemoteRecord(
            service: serviceSyncExpectedDTO(id: id, name: "After", status: .inactive),
            version: .versioned(revision: 3, lastOperationID: deactivateID),
            changeSequence: 3
        )
        #expect(await remote.record(for: id.rawValue) == expected)
        #expect(await remote.recordCount == 1)
        #expect(await remote.appliedOperationIDs == [createID, editID, deactivateID])
        #expect(await remote.receivedOperationIDs == [createID, editID, deactivateID])
        #expect(try await fixture.actor.pendingOperations().isEmpty)
        let local = try await GetServiceUseCase(repository: read)(id)
        #expect(try local == serviceSyncExpected(id: id, name: "After", status: .inactive))
        #expect(try ModelContext(fixture.container).fetchCount(FetchDescriptor<ServicePendingDeleteModel>()) == 0)
    }

    @Test
    @MainActor
    func `an older acknowledgement preserves contextual edits and deactivation`() async throws {
        let fixture = try ServiceCRUDSyncFixture()
        let id = ServiceID(rawValue: try serviceSyncUUID("02"))
        let createID = try serviceSyncUUID("21")
        let editID = try serviceSyncUUID("22")
        let deactivateID = try serviceSyncUUID("23")
        let repository = fixture.repository(operationID: createID)
        let created = try await CreateServiceUseCase(repository: repository)(
            id: id,
            profile: serviceSyncProfile(name: "Before acknowledgement", product: true)
        )
        var observation = await repository.observeServices().makeAsyncIterator()
        #expect(try await observation.next() == [created])
        let gate = ServiceSyncAcknowledgementGate()
        let remote = ServiceSyncRemoteFake(acknowledgementGate: gate)
        let engine = fixture.engine(remote: remote)
        let adapter = ServiceContextualPersistenceAdapter(
            observationSignal: fixture.signal,
            operationID: { deactivateID }
        )
        let editAdapter = ServiceContextualPersistenceAdapter(
            observationSignal: fixture.signal,
            operationID: { editID }
        )
        async let synchronization: Void = serviceSyncAwaitingAcknowledgement(engine, gate: gate)
        let reachedAcknowledgement = await gate.waitUntilBlockedOrFinished()
        do {
            try #require(reachedAcknowledgement, "Synchronization ended before reaching the remote acknowledgement.")
            _ = try await editAdapter.update(
                id: id,
                profile: serviceSyncProfile(name: "Retained profile"),
                in: fixture.container.mainContext
            )
            try await adapter.deactivate(id, in: fixture.container.mainContext)
        } catch {
            await gate.release()
            _ = try? await synchronization
            throw error
        }
        await gate.release()
        try await synchronization

        let inactive = try serviceSyncExpected(id: id, name: "Retained profile", status: .inactive, product: false)
        #expect(try await repository.service(id: id) == inactive)
        let pending = try await fixture.actor.pendingUpserts()
        try #require(pending.count == 2)
        #expect(pending.map(\.operationID) == [editID, deactivateID])
        #expect(pending.map(\.predecessorOperationID) == [createID, editID])
        #expect(pending.map(\.service) == [
            try serviceSyncExpectedDTO(id: id, name: "Retained profile", status: .active, product: false),
            try serviceSyncExpectedDTO(id: id, name: "Retained profile", status: .inactive, product: false)
        ])
        var observed = try await observation.next()
        while let snapshot = observed, snapshot != [inactive] {
            observed = try await observation.next()
        }
        #expect(observed == [inactive])

        try await engine.synchronize()

        #expect(try await repository.service(id: id) == inactive)
        #expect(try await fixture.actor.pendingOperations().isEmpty)
        #expect(try await remote.record(for: id.rawValue) == ServiceRemoteRecord(
            service: serviceSyncExpectedDTO(id: id, name: "Retained profile", status: .inactive, product: false),
            version: .versioned(revision: 3, lastOperationID: deactivateID),
            changeSequence: 3
        ))
        #expect(await remote.appliedOperationIDs == [createID, editID, deactivateID])
    }

    @Test
    func `a pulled conflict preserves the command chain and blocks only that service`() async throws {
        let fixture = try ServiceCRUDSyncFixture()
        let id = ServiceID(rawValue: try serviceSyncUUID("03"))
        let createID = try serviceSyncUUID("31")
        let editID = try serviceSyncUUID("32")
        let deactivateID = try serviceSyncUUID("33")
        let remoteID = try serviceSyncUUID("34")
        let repository = fixture.repository(operationID: createID)
        _ = try await CreateServiceUseCase(repository: repository)(
            id: id,
            profile: serviceSyncProfile(name: "Original")
        )
        let remote = ServiceSyncRemoteFake()
        let engine = fixture.engine(remote: remote)
        try await engine.synchronize()
        _ = try await UpdateServiceUseCase(repository: fixture.repository(operationID: editID))(
            id: id,
            profile: serviceSyncProfile(name: "Local edit", product: true)
        )
        try await DeactivateServiceUseCase(repository: fixture.repository(operationID: deactivateID))(id)
        let before = try await fixture.actor.pendingOperations()
        let concurrent = try ServiceRemoteRecord(
            service: serviceSyncExpectedDTO(id: id, name: "Concurrent remote", status: .active, product: false),
            version: .versioned(revision: 2, lastOperationID: remoteID),
            changeSequence: 2
        )
        try await remote.receive(concurrent)

        try await engine.synchronize()

        let local = try await repository.service(id: id)
        #expect(try local == serviceSyncExpected(id: id, name: "Local edit", status: .inactive))
        #expect(try await fixture.actor.pendingOperations() == before)
        let context = ModelContext(fixture.container)
        let conflicts = try context.fetch(FetchDescriptor<ServiceSyncConflictModel>())
        try #require(conflicts.count == 1)
        let conflict = try #require(conflicts.first)
        #expect(try conflict.decodeLocalService() == serviceSyncExpectedDTO(
            id: id,
            name: "Local edit",
            status: .active
        ))
        #expect(try conflict.decodeRemoteRecord() == concurrent)
        await #expect(throws: ServiceError.conflict) {
            try await UpdateServiceUseCase(repository: repository)(id: id, profile: serviceSyncProfile(name: "Blocked"))
        }
        await #expect(throws: ServiceError.conflict) {
            try await DeactivateServiceUseCase(repository: repository)(id)
        }

        let otherID = ServiceID(rawValue: try serviceSyncUUID("04"))
        let otherOperationID = try serviceSyncUUID("41")
        _ = try await CreateServiceUseCase(repository: fixture.repository(operationID: otherOperationID))(
            id: otherID,
            profile: serviceSyncProfile(name: "Still operable")
        )
        try await engine.synchronize()

        #expect(try await fixture.actor.pendingOperations() == before)
        #expect(await remote.record(for: id.rawValue) == concurrent)
        #expect(await remote.record(for: otherID.rawValue)?.liveService?.name == "Still operable")
        #expect(await remote.appliedOperationIDs == [createID, otherOperationID])
        #expect(await remote.receivedOperationIDs == [createID, otherOperationID])
    }

    @Test
    func `a pulled tombstone disappears from local observation and cannot be restored by CRUD`() async throws {
        let fixture = try ServiceCRUDSyncFixture()
        let id = ServiceID(rawValue: try serviceSyncUUID("05"))
        let createID = try serviceSyncUUID("51")
        let editID = try serviceSyncUUID("52")
        let deactivateID = try serviceSyncUUID("53")
        let deleteID = try serviceSyncUUID("54")
        let repository = fixture.repository(operationID: createID)
        _ = try await CreateServiceUseCase(repository: repository)(
            id: id,
            profile: serviceSyncProfile(name: "Original")
        )
        let remote = ServiceSyncRemoteFake()
        let engine = fixture.engine(remote: remote)
        try await engine.synchronize()
        _ = try await UpdateServiceUseCase(repository: fixture.repository(operationID: editID))(
            id: id,
            profile: serviceSyncProfile(name: "Pending edit", product: true)
        )
        try await DeactivateServiceUseCase(repository: fixture.repository(operationID: deactivateID))(id)
        let before = try await fixture.actor.pendingOperations()
        var observation = await ObserveServicesUseCase(repository: repository)().makeAsyncIterator()
        #expect(try await observation.next() == [serviceSyncExpected(id: id, name: "Pending edit", status: .inactive)])
        let tombstone = ServiceRemoteRecord(
            content: .tombstone(serviceID: id.rawValue),
            version: .versioned(revision: 2, lastOperationID: deleteID),
            changeSequence: 2
        )
        try await remote.receive(tombstone)

        try await engine.synchronize()

        #expect(try await observation.next() == [])
        #expect(try await GetServiceUseCase(repository: repository)(id) == nil)
        await #expect(throws: ServiceError.alreadyExists) {
            try await CreateServiceUseCase(repository: repository)(id: id, profile: serviceSyncProfile(name: "Restore"))
        }
        await #expect(throws: ServiceError.deleted) {
            try await UpdateServiceUseCase(repository: repository)(id: id, profile: serviceSyncProfile(name: "Restore"))
        }
        await #expect(throws: ServiceError.deleted) {
            try await DeactivateServiceUseCase(repository: repository)(id)
        }
        try await engine.synchronize()

        #expect(try await fixture.actor.pendingOperations() == before)
        #expect(try await repository.service(id: id) == nil)
        let conflicts = try ModelContext(fixture.container).fetch(FetchDescriptor<ServiceSyncConflictModel>())
        try #require(conflicts.count == 1)
        let conflict = try #require(conflicts.first)
        #expect(try conflict.decodeLocalService() == serviceSyncExpectedDTO(
            id: id,
            name: "Pending edit",
            status: .active
        ))
        #expect(try conflict.decodeRemoteRecord() == tombstone)
        #expect(await remote.record(for: id.rawValue) == tombstone)
        #expect(await remote.appliedOperationIDs == [createID])
        #expect(await remote.receivedOperationIDs == [createID])
    }
}

private struct ServiceCRUDSyncFixture {
    let container: ModelContainer
    let actor: ServicePersistenceActor
    let signal: ServiceObservationSignal

    func repository(operationID: UUID) -> DefaultServiceRepository {
        DefaultServiceRepository(
            persistenceActor: actor,
            observationSignal: signal,
            operationID: { operationID }
        )
    }

    func engine(remote: ServiceSyncRemoteFake) -> ServiceSyncEngine {
        ServiceSyncEngine(
            persistenceActor: actor,
            remoteDataSource: remote,
            observationSignal: signal,
            timing: SyncTiming(
                now: { Date(timeIntervalSinceReferenceDate: 1_000) },
                sleep: { _ in },
                jitterFactor: { 1 }
            )
        )
    }
}

private extension ServiceCRUDSyncFixture {
    init() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        self.init(
            container: container,
            actor: ServicePersistenceActor(modelContainer: container),
            signal: ServiceObservationSignal()
        )
    }
}

private func serviceSyncUUID(_ suffix: String) throws -> UUID {
    try #require(UUID(uuidString: "10020000-0000-0000-0000-0000000000\(suffix)"))
}

private func serviceSyncProfile(name: String, product: Bool = false) throws -> ServiceProfile {
    try ServiceProfile(
        name: name,
        type: product ? .product : .professional,
        linkedProductID: product ? ProductID(rawValue: serviceSyncUUID("99")) : nil,
        price: Money(amount: #require(Decimal(string: product ? "47.83" : "62.14")), currency: product ? .usd : .eur),
        taxRate: TaxRate(percentage: #require(Decimal(string: product ? "7.25" : "19"))),
        discount: product ? Discount(percentage: #require(Decimal(string: "12.5"))) : nil
    )
}

private func serviceSyncExpected(
    id: ServiceID,
    name: String,
    status: ServiceStatus,
    product: Bool = true
) throws -> Service {
    try Service(
        id: id,
        name: name,
        type: product ? .product : .professional,
        linkedProductID: product ? ProductID(rawValue: serviceSyncUUID("99")) : nil,
        price: Money(amount: #require(Decimal(string: product ? "47.83" : "62.14")), currency: product ? .usd : .eur),
        taxRate: TaxRate(percentage: #require(Decimal(string: product ? "7.25" : "19"))),
        discount: product ? Discount(percentage: #require(Decimal(string: "12.5"))) : nil,
        status: status
    )
}

private func serviceSyncExpectedDTO(
    id: ServiceID,
    name: String,
    status: ServiceStatusDTO,
    product: Bool = true
) throws -> ServiceDTO {
    try ServiceDTO(
        id: id.rawValue.uuidString,
        name: name,
        type: product ? .product : .professional,
        linkedProductID: product ? serviceSyncUUID("99").uuidString : nil,
        price: ServiceMoneyDTO(
            amount: CanonicalDecimalDTO(canonicalString: product ? "47.83" : "62.14"),
            currency: product ? .usd : .eur
        ),
        taxRate: ServiceTaxRateDTO(percentage: CanonicalDecimalDTO(canonicalString: product ? "7.25" : "19")),
        discount: product ? ServiceDiscountDTO(percentage: CanonicalDecimalDTO(canonicalString: "12.5")) : nil,
        status: status
    )
}

private func serviceSyncAwaitingAcknowledgement(
    _ engine: ServiceSyncEngine,
    gate: ServiceSyncAcknowledgementGate
) async throws {
    do {
        try await engine.synchronize()
        await gate.finishSynchronization()
    } catch {
        await gate.finishSynchronization()
        throw error
    }
}
