import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Service CRUD durable synchronization", .timeLimit(.minutes(1)))
struct ServiceCRUDDurabilityTests {
    @Test
    @MainActor
    func `offline CRUD and push retry survive two store reopenings without duplicate remote writes`() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: UUID().uuidString,
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appending(path: "services.store")
        let fixture = ServiceDurabilityFixture(
            id: ServiceID(rawValue: try #require(UUID(uuidString: "10200000-0000-0000-0000-000000000001"))),
            creationID: try #require(UUID(uuidString: "10210000-0000-0000-0000-000000000001")),
            editID: try #require(UUID(uuidString: "10210000-0000-0000-0000-000000000002")),
            deactivationID: try #require(UUID(uuidString: "10210000-0000-0000-0000-000000000003"))
        )
        let start = Date(timeIntervalSinceReferenceDate: 12_000)
        let timing = ServiceRetryManualTiming(now: start)
        let remote = ServiceDurabilityRemote()
        let lifetime = ServiceDurabilityLifetime()

        let payloads = try await acceptOfflineServiceChain(
            at: storeURL,
            fixture: fixture,
            remote: remote,
            timing: timing,
            lifetime: lifetime
        )

        #expect(lifetime.container == nil)
        #expect(lifetime.persistenceActor == nil)
        #expect(lifetime.engine == nil)
        #expect(await remote.failedOperationIDs == Array(repeating: fixture.creationID, count: 3))
        #expect(await timing.recordedSleeps == [.seconds(1), .seconds(2)])
        #expect(await remote.storage.recordCount == 0)

        try await recoverReopenedServiceChain(
            at: storeURL,
            fixture: fixture,
            payloads: payloads,
            retryDeadline: start.addingTimeInterval(7),
            remote: remote,
            timing: timing,
            lifetime: lifetime
        )

        #expect(lifetime.container == nil)
        #expect(lifetime.persistenceActor == nil)
        #expect(lifetime.engine == nil)
        #expect(await timing.recordedSleeps == [.seconds(1), .seconds(2), .seconds(4)])
        #expect(await remote.storage.appliedOperationIDs == fixture.operationIDs)
        #expect(await remote.storage.receivedOperationIDs == fixture.operationIDs)
        #expect(await remote.storage.recordCount == 1)
        #expect(try await remote.storage.record(for: fixture.id.rawValue) == fixture.finalRemoteRecord)
        #expect(await remote.storage.requestedCursors == [
            nil,
            ServiceSyncCursor(changeSequence: 0),
            ServiceSyncCursor(changeSequence: 0)
        ])

        try verifyRecoveredServiceStore(at: storeURL, fixture: fixture, lifetime: lifetime)

        #expect(lifetime.container == nil)
    }
}

private struct ServiceDurabilityFixture {
    let id: ServiceID
    let creationID: UUID
    let editID: UUID
    let deactivationID: UUID

    var operationIDs: [UUID] { [creationID, editID, deactivationID] }
    var inactiveService: Service {
        get throws {
            try Service(
                id: id,
                name: "Edited offline",
                type: .product,
                linkedProductID: ProductID(rawValue: serviceDurabilityLinkID()),
                price: Money(amount: #require(Decimal(string: "47.83")), currency: .usd),
                taxRate: TaxRate(percentage: #require(Decimal(string: "7.25"))),
                discount: Discount(percentage: 0),
                status: .inactive
            )
        }
    }
    var finalRemoteRecord: ServiceRemoteRecord {
        get throws {
            try ServiceRemoteRecord(
                service: serviceDurabilityDTO(id: id, edited: true, status: .inactive),
                version: .versioned(revision: 3, lastOperationID: deactivationID),
                changeSequence: 3
            )
        }
    }
}

private struct ServiceDurabilityPayload: Equatable {
    let baseVersion: Int?
    let baseData: Data?
    let payloadVersion: Int
    let payloadData: Data
}

@MainActor
private final class ServiceDurabilityLifetime {
    weak var container: ModelContainer?
    weak var persistenceActor: ServicePersistenceActor?
    weak var engine: ServiceSyncEngine?
}

private actor ServiceDurabilityRemote: ServiceRemoteDataSource {
    let storage = ServiceSyncRemoteFake()
    private var unavailable = true
    private(set) var failedOperationIDs: [UUID] = []

    func fetchChanges(after cursor: ServiceSyncCursor?) async throws -> ServiceRemoteChangeBatch {
        try await storage.fetchChanges(after: cursor)
    }

    func apply(_ operation: ServicePendingOperation) async throws -> ServiceRemoteMutationResult {
        if unavailable {
            failedOperationIDs.append(operation.operationID)
            throw ServiceRemoteDataSourceError.unavailable
        }
        return try await storage.apply(operation)
    }

    func recover() {
        unavailable = false
    }
}

@MainActor
private func acceptOfflineServiceChain(
    at storeURL: URL,
    fixture: ServiceDurabilityFixture,
    remote: ServiceDurabilityRemote,
    timing: ServiceRetryManualTiming,
    lifetime: ServiceDurabilityLifetime
) async throws -> [UUID: ServiceDurabilityPayload] {
    let container = try serviceDurabilityContainer(at: storeURL)
    let persistenceActor = ServicePersistenceActor(modelContainer: container)
    let signal = ServiceObservationSignal()
    let creationRepository = DefaultServiceRepository(
        persistenceActor: persistenceActor,
        observationSignal: signal,
        operationID: { fixture.creationID }
    )
    let editRepository = DefaultServiceRepository(
        persistenceActor: persistenceActor,
        observationSignal: signal,
        operationID: { fixture.editID }
    )
    let deactivationRepository = DefaultServiceRepository(
        persistenceActor: persistenceActor,
        observationSignal: signal,
        operationID: { fixture.deactivationID }
    )
    _ = try await CreateServiceUseCase(repository: creationRepository)(
        id: fixture.id,
        profile: serviceDurabilityProfile(edited: false)
    )
    _ = try await UpdateServiceUseCase(repository: editRepository)(
        id: fixture.id,
        profile: serviceDurabilityProfile(edited: true)
    )
    try await DeactivateServiceUseCase(repository: deactivationRepository)(fixture.id)
    let engine = ServiceSyncEngine(
        persistenceActor: persistenceActor,
        remoteDataSource: remote,
        observationSignal: signal,
        timing: timing.dependency
    )
    lifetime.container = container
    lifetime.persistenceActor = persistenceActor
    lifetime.engine = engine

    await #expect(throws: ServiceRemoteDataSourceError.unavailable) {
        try await engine.synchronize()
    }

    #expect(try await GetServiceUseCase(repository: creationRepository)(fixture.id) == fixture.inactiveService)
    return try serviceDurabilityPayloads(in: ModelContext(container))
}

@MainActor
private func recoverReopenedServiceChain(
    at storeURL: URL,
    fixture: ServiceDurabilityFixture,
    payloads: [UUID: ServiceDurabilityPayload],
    retryDeadline: Date,
    remote: ServiceDurabilityRemote,
    timing: ServiceRetryManualTiming,
    lifetime: ServiceDurabilityLifetime
) async throws {
    let container = try serviceDurabilityContainer(at: storeURL)
    let persistenceActor = ServicePersistenceActor(modelContainer: container)
    let signal = ServiceObservationSignal()
    let repository = DefaultServiceRepository(persistenceActor: persistenceActor, observationSignal: signal)
    let context = ModelContext(container)
    let operations = try await persistenceActor.pendingUpserts()
    try #require(operations.count == 3)
    #expect(operations.map(\.operationID) == fixture.operationIDs)
    #expect(operations.map(\.serviceID) == Array(repeating: fixture.id.rawValue, count: 3))
    #expect(operations.map(\.predecessorOperationID) == [nil, fixture.creationID, fixture.editID])
    #expect(operations.map(\.base) == [.absent, .absent, .absent])
    #expect(try operations.map(\.service) == [
        serviceDurabilityDTO(id: fixture.id, edited: false, status: .active),
        serviceDurabilityDTO(id: fixture.id, edited: true, status: .active),
        serviceDurabilityDTO(id: fixture.id, edited: true, status: .inactive)
    ])
    #expect(try serviceDurabilityPayloads(in: context) == payloads)
    #expect(try await GetServiceUseCase(repository: repository)(fixture.id) == fixture.inactiveService)
    #expect(try await persistenceActor.cursor() == ServiceSyncCursor(changeSequence: 0))
    #expect(try context.fetchCount(FetchDescriptor<ServiceRemoteStateModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ServicePendingDeleteModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ServiceSyncRetryModel>()) == 1)
    #expect(try await persistenceActor.retryState(for: .operation(fixture.creationID)) == SyncRetryState(
        scope: .operation(fixture.creationID),
        backoffStep: 3,
        notBefore: retryDeadline,
        lastRecoverableCategory: .unavailable
    ))
    let engine = ServiceSyncEngine(
        persistenceActor: persistenceActor,
        remoteDataSource: remote,
        observationSignal: signal,
        timing: timing.dependency
    )
    lifetime.container = container
    lifetime.persistenceActor = persistenceActor
    lifetime.engine = engine

    await remote.recover()
    try await engine.synchronize()
    try await engine.synchronize()

    #expect(try await persistenceActor.pendingOperations().isEmpty)
    #expect(try await persistenceActor.retryState(for: .operation(fixture.creationID)) == nil)
    #expect(try await persistenceActor.cursor() == ServiceSyncCursor(changeSequence: 3))
}

@MainActor
private func verifyRecoveredServiceStore(
    at storeURL: URL,
    fixture: ServiceDurabilityFixture,
    lifetime: ServiceDurabilityLifetime
) throws {
    let container = try serviceDurabilityContainer(at: storeURL)
    lifetime.container = container
    let context = ModelContext(container)
    let source = ServiceLocalDataSource()

    #expect(try source.fetchAll(in: context) == [fixture.inactiveService])
    #expect(try source.pendingOperations(in: context).isEmpty)
    #expect(try source.cursor(in: context) == ServiceSyncCursor(changeSequence: 3))
    #expect(try context.fetchCount(FetchDescriptor<ServiceSyncRetryModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ServiceSyncConflictModel>()) == 0)
    let remoteStates = try context.fetch(FetchDescriptor<ServiceRemoteStateModel>())
    try #require(remoteStates.count == 1)
    #expect(try remoteStates[0].decodeRecord() == fixture.finalRemoteRecord)
}

private func serviceDurabilityContainer(at storeURL: URL) throws -> ModelContainer {
    let schema = Schema.franAlonso
    let configuration = ModelConfiguration(
        "ServiceCRUDDurability",
        schema: schema,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: schema,
        migrationPlan: PhaseFiveSchemaMigrationPlan.self,
        configurations: [configuration]
    )
}

private func serviceDurabilityPayloads(in context: ModelContext) throws -> [UUID: ServiceDurabilityPayload] {
    let rows = try context.fetch(FetchDescriptor<ServicePendingUpsertModel>())
    return Dictionary(uniqueKeysWithValues: rows.map { row in
        (row.operationID, ServiceDurabilityPayload(
            baseVersion: row.baseVersion,
            baseData: row.baseData,
            payloadVersion: row.payloadVersion,
            payloadData: row.payloadData
        ))
    })
}

private func serviceDurabilityLinkID() throws -> UUID {
    try #require(UUID(uuidString: "10200000-0000-0000-0000-000000000099"))
}

private func serviceDurabilityProfile(edited: Bool) throws -> ServiceProfile {
    try ServiceProfile(
        name: edited ? "Edited offline" : "Created offline",
        type: edited ? .product : .professional,
        linkedProductID: edited ? ProductID(rawValue: serviceDurabilityLinkID()) : nil,
        price: Money(amount: #require(Decimal(string: edited ? "47.83" : "29.95")), currency: edited ? .usd : .eur),
        taxRate: TaxRate(percentage: #require(Decimal(string: edited ? "7.25" : "21"))),
        discount: edited ? Discount(percentage: 0) : nil
    )
}

private func serviceDurabilityDTO(id: ServiceID, edited: Bool, status: ServiceStatusDTO) throws -> ServiceDTO {
    try ServiceDTO(
        id: id.rawValue.uuidString,
        name: edited ? "Edited offline" : "Created offline",
        type: edited ? .product : .professional,
        linkedProductID: edited ? serviceDurabilityLinkID().uuidString : nil,
        price: ServiceMoneyDTO(
            amount: CanonicalDecimalDTO(canonicalString: edited ? "47.83" : "29.95"),
            currency: edited ? .usd : .eur
        ),
        taxRate: ServiceTaxRateDTO(percentage: CanonicalDecimalDTO(canonicalString: edited ? "7.25" : "21")),
        discount: edited ? ServiceDiscountDTO(percentage: CanonicalDecimalDTO(canonicalString: "0")) : nil,
        status: status
    )
}
