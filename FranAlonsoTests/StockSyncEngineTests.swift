import Foundation
import SwiftData
import Testing

@testable import FranAlonso

@Suite("Stock immutable synchronization engine")
@MainActor
struct StockSyncEngineTests {
    @Test
    func `repeated push pull and remote disappearance retain one accepted ledger`() async throws {
        let container = try stockSyncTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let movement = try stockTestMovement(productID: product.id, delta: -5, ordinal: 1)
        let writer = StockPersistenceActor(modelContainer: container)
        _ = try await writer.append(movement)
        let before = try stockPayloads(in: ModelContext(container))
        let remote = StockSyncTestRemote()
        let signal = StockSyncTestSignal()
        let engine = StockSyncEngine(persistenceActor: writer, remoteDataSource: remote, observationSignal: signal)
        try await engine.synchronize()
        try await engine.synchronize()
        await remote.removeAllRecords()
        try await engine.synchronize()
        #expect(await remote.appliedIDs == [movement.id.rawValue])
        #expect(try await writer.deliverablePendingMovements().isEmpty)
        #expect(try await writer.quantity(for: product.id) == -5)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 1)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockRemoteStateModel>()) == 1)
    }

    @Test
    func `pull publishes committed ledger even when later push fails`() async throws {
        let container = try stockSyncTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let remoteMovement = try stockTestMovement(productID: product.id, delta: -8, ordinal: 1)
        let pending = try stockTestMovement(productID: product.id, delta: 2, ordinal: 2)
        let writer = StockPersistenceActor(modelContainer: container)
        _ = try await writer.append(pending)
        let remote = StockSyncTestRemote(
            records: [try stockSyncTestRecord(remoteMovement, sequence: 1)],
            pushError: .permissionDenied
        )
        let signal = StockSyncTestSignal()
        let engine = StockSyncEngine(persistenceActor: writer, remoteDataSource: remote, observationSignal: signal)
        await #expect(throws: StockRemoteDataSourceError.permissionDenied) { try await engine.synchronize() }
        #expect(try await writer.quantity(for: product.id) == -6)
        #expect(try await writer.cursor()?.changeSequence == 1)
        #expect(try await writer.deliverablePendingMovements() == [pending])
        #expect(await signal.count == 1)
        #expect(try await writer.retryState(for: .operation(pending.id.rawValue)) == nil)
    }

    @Test
    func `cancelled acknowledgement retains pending then replays without duplicate remote event`() async throws {
        let container = try stockSyncTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let movement = try stockTestMovement(productID: product.id, delta: -3, ordinal: 1)
        let writer = StockPersistenceActor(modelContainer: container)
        _ = try await writer.append(movement)
        let gate = StockSyncTestGate()
        let remote = StockSyncTestRemote(gate: gate)
        let engine = StockSyncEngine(
            persistenceActor: writer,
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal()
        )
        let pass = Task { try await engine.synchronize() }
        await gate.waitUntilEntered()
        pass.cancel()
        await gate.release()
        await #expect(throws: CancellationError.self) { try await pass.value }
        #expect(try await writer.deliverablePendingMovements() == [movement])
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockRemoteStateModel>()) == 0)
        try await engine.synchronize()
        #expect(try await writer.deliverablePendingMovements().isEmpty)
        #expect(try await writer.quantity(for: product.id) == -3)
        #expect(await remote.records.count == 1)
        #expect(await remote.appliedIDs == [movement.id.rawValue])
    }

    @Test
    func `overlapping pass is rejected while one caller owns remote wait`() async throws {
        let container = try stockSyncTestContainer()
        let gate = StockSyncTestGate()
        let remote = StockSyncTestRemote(pullGate: gate)
        let engine = StockSyncEngine(
            persistenceActor: StockPersistenceActor(modelContainer: container),
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal()
        )
        async let pass: Void = engine.synchronize()
        await gate.waitUntilEntered()
        await #expect(throws: StockSyncError.alreadySynchronizing) { try await engine.synchronize() }
        await gate.release()
        try await pass
        #expect(await remote.fetchCount == 1)
    }

    @Test
    func `third transient failure persists schedule without a third sleep`() async throws {
        let container = try stockSyncTestContainer()
        let writer = StockPersistenceActor(modelContainer: container)
        let remote = StockSyncTestRemote(pullFailures: 3)
        let clock = StockSyncTestClock()
        let engine = StockSyncEngine(
            persistenceActor: writer,
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal(),
            timing: clock.timing
        )
        await #expect(throws: StockRemoteDataSourceError.unavailable) { try await engine.synchronize() }
        #expect(await remote.fetchCount == 3)
        #expect(await clock.waits == [.seconds(1), .seconds(2)])
        let state = try #require(await writer.retryState(for: .pull))
        #expect(state.backoffStep == 3)
        #expect(state.notBefore == Date(timeIntervalSinceReferenceDate: 107))
        try await engine.synchronize()
        #expect(await clock.waits == [.seconds(1), .seconds(2), .seconds(4)])
        #expect(try await writer.retryState(for: .pull) == nil)
    }

    @Test
    func `operation retry is independent of pull and clears with acknowledgement`() async throws {
        let container = try stockSyncTestContainer()
        let product = try stockTestProduct()
        try seedStockTestProduct(product, in: container)
        let movement = try stockTestMovement(productID: product.id, delta: 1, ordinal: 1)
        let writer = StockPersistenceActor(modelContainer: container)
        _ = try await writer.append(movement)
        let remote = StockSyncTestRemote(pushFailures: 2)
        let clock = StockSyncTestClock()
        let engine = StockSyncEngine(
            persistenceActor: writer,
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal(),
            timing: clock.timing
        )
        try await engine.synchronize()
        #expect(await remote.fetchCount == 1)
        #expect(await remote.pushCount == 3)
        #expect(await clock.waits == [.seconds(1), .seconds(2)])
        #expect(try await writer.retryState(for: .operation(movement.id.rawValue)) == nil)
        #expect(try await writer.deliverablePendingMovements().isEmpty)
    }

    @Test
    func `cancelled late pull produces no local cursor or event`() async throws {
        let container = try stockSyncTestContainer()
        let movement = try stockTestMovement(productID: ProductID(rawValue: UUID()), delta: 1, ordinal: 1)
        let writer = StockPersistenceActor(modelContainer: container)
        let gate = StockSyncTestGate()
        let remote = StockSyncTestRemote(records: [try stockSyncTestRecord(movement, sequence: 1)], pullGate: gate)
        let engine = StockSyncEngine(
            persistenceActor: writer,
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal()
        )
        let pass = Task { try await engine.synchronize() }
        await gate.waitUntilEntered()
        pass.cancel()
        await gate.release()
        await #expect(throws: CancellationError.self) { try await pass.value }
        #expect(try await writer.cursor() == nil)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
        #expect(try await writer.retryState(for: .pull) == nil)
    }
}

actor StockSyncTestSignal: ProductChangeSignaling {
    private(set) var count = 0
    func publishChange() {
        count += 1
    }
}

actor StockSyncTestRemote: StockRemoteDataSource {
    private(set) var records: [StockRemoteRecord]
    private(set) var appliedIDs: [UUID] = []
    private(set) var fetchCount = 0
    private(set) var pushCount = 0
    private var pullFailures: Int
    private var pushFailures: Int
    private let pushError: StockRemoteDataSourceError?
    private let gate: StockSyncTestGate?
    private let pullGate: StockSyncTestGate?

    init(
        records: [StockRemoteRecord] = [],
        pushError: StockRemoteDataSourceError? = nil,
        gate: StockSyncTestGate? = nil,
        pullGate: StockSyncTestGate? = nil,
        pullFailures: Int = 0,
        pushFailures: Int = 0
    ) {
        self.records = records
        self.pushError = pushError
        self.gate = gate
        self.pullGate = pullGate
        self.pullFailures = pullFailures
        self.pushFailures = pushFailures
    }

    func fetchChanges(after cursor: StockSyncCursor?) async throws -> StockRemoteChangeBatch {
        fetchCount += 1
        if pullFailures > 0 {
            pullFailures -= 1
            throw StockRemoteDataSourceError.unavailable
        }
        await pullGate?.enter()
        let values = records.filter { $0.changeSequence > (cursor?.changeSequence ?? 0) }.reversed()
        return StockRemoteChangeBatch(
            records: Array(values),
            nextCursor: StockSyncCursor(
                changeSequence: values.map(\.changeSequence).max() ?? cursor?.changeSequence ?? 0
            )
        )
    }

    func apply(_ movement: StockMovement) async throws -> StockRemoteMutationResult {
        pushCount += 1
        if let pushError { throw pushError }
        if pushFailures > 0 {
            pushFailures -= 1
            throw StockRemoteDataSourceError.aborted
        }
        if let previous = records.first(where: { $0.operationID == movement.id.rawValue }) {
            return try previous.validatedMovement() == movement ? .alreadyApplied(previous) : .conflict(previous)
        }
        let record = try stockSyncTestRecord(movement, sequence: (records.map(\.changeSequence).max() ?? 0) + 1)
        records.append(record)
        appliedIDs.append(movement.id.rawValue)
        await gate?.enter()
        return .applied(record)
    }

    func removeAllRecords() {
        records.removeAll()
    }
}

actor StockSyncTestGate {
    private var entered = false
    private var released = false
    private var waiters: [CheckedContinuation<Void, Never>] = []
    private var blocked: CheckedContinuation<Void, Never>?

    func enter() async {
        if released { return }
        entered = true
        for waiter in waiters { waiter.resume() }
        waiters.removeAll()
        await withCheckedContinuation { blocked = $0 }
    }

    func waitUntilEntered() async {
        if entered { return }
        await withCheckedContinuation { waiters.append($0) }
    }

    func release() {
        released = true
        blocked?.resume()
        blocked = nil
    }
}

actor StockSyncTestClock {
    private var date = Date(timeIntervalSinceReferenceDate: 100)
    private(set) var waits: [Duration] = []

    nonisolated var timing: SyncTiming {
        SyncTiming(now: { await self.now() }, sleep: { try await self.sleep($0) }, jitterFactor: { 1 })
    }

    func now() -> Date { date }

    func sleep(_ duration: Duration) throws {
        try Task.checkCancellation()
        waits.append(duration)
        date.addTimeInterval(Double(duration.components.seconds) + Double(duration.components.attoseconds) / 1e18)
    }
}
