import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Compensatory stock convergence", .timeLimit(.minutes(1)))
@MainActor
struct SaleReversalSyncTests {
    @Test
    func `cancelled remote acknowledgement replays compensation without losing stock or adding duplicates`() async throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        _ = try saleReversalSourceVoid(closed, in: ModelContext(container))
        let context = ModelContext(container)
        let before = try stockPayloads(in: context)
        let queue = try SaleLocalDataSource().pendingOperations(in: context)
        let gate = StockSyncTestGate()
        let remote = StockSyncTestRemote(gate: gate)
        let writer = StockPersistenceActor(modelContainer: container)
        let engine = StockSyncEngine(
            persistenceActor: writer,
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal()
        )
        let pass = Task { try await engine.synchronize() }
        await gate.waitUntilEntered()
        pass.cancel()
        await gate.release()
        await #expect(throws: CancellationError.self) {
            try await pass.value
        }
        #expect(try await writer.deliverablePendingMovements().count == 6)
        try await engine.synchronize()
        try await engine.synchronize()
        #expect(try await writer.deliverablePendingMovements().isEmpty)
        #expect(await remote.records.count == 6)
        #expect(await remote.appliedIDs.count == 6)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)) == queue)
        #expect(try await writer.quantity(for: saleStockProductID(1)) == 0)
    }

    @Test
    func `two offline reversals compete for one inverse identity without a second additive event`() async throws {
        let closed = try saleReversalClosedFixture()
        let first = try SaleStockReversalPolicy()(
            sale: saleReversalVoidedFixture(closed),
            reversalID: saleReversalTestID
        )
        let otherID = SaleReversalID(rawValue: saleStockUUID(0xf2, 2))
        let second = try SaleStockReversalPolicy()(
            sale: saleReversalVoidedFixture(closed, id: otherID),
            reversalID: otherID
        )
        #expect(first.map(\.id) == second.map(\.id))
        let remote = StockSyncTestRemote()
        for event in first {
            guard case .applied = try await remote.apply(event) else {
                Issue.record("First inverse must be created")
                return
            }
        }
        for event in second.reversed() {
            guard case .conflict = try await remote.apply(event) else {
                Issue.record("Other reversal must conflict instead of adding stock")
                return
            }
        }
        #expect(await remote.records.count == 3)
        #expect(await remote.records.map(\.changeSequence).sorted() == [1, 2, 3])
        let candidate = try #require(second.first)
        let original = try #require(await remote.records.first { $0.operationID == candidate.id.rawValue })
        let plan = try FirestoreStockRemoteDataSource.transactionPlan(
            for: candidate,
            against: original,
            counter: .unread
        )
        guard case .result(.conflict(let retained)) = plan else {
            Issue.record("Production transaction policy must preserve the first inverse without a counter write")
            return
        }
        #expect(retained == original)
        try await withReversalConflictStore(closed: closed, inverses: second, remote: remote)
    }

    @Test
    func `compensations arriving before consumptions converge without generating stock from Sale`() async throws {
        let closed = try saleReversalClosedFixture()
        let voided = try saleReversalVoidedFixture(closed)
        let inverse = try SaleStockReversalPolicy()(sale: voided, reversalID: saleReversalTestID)
        let remote = StockSyncTestRemote()
        for event in inverse.reversed() {
            _ = try await remote.apply(event)
        }
        let container = try stockSyncTestContainer()
        _ = try saleStockRepository(in: container)
        try SaleLocalDataSource().upsert(voided, in: ModelContext(container))
        let writer = StockPersistenceActor(modelContainer: container)
        let engine = StockSyncEngine(
            persistenceActor: writer,
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal()
        )
        try await engine.synchronize()
        #expect(try await writer.quantity(for: saleStockProductID(1)) == 5)
        #expect(try await writer.quantity(for: saleStockProductID(2)) == 4)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
        for event in try SaleStockMovementPolicy()(sale: closed, paymentID: saleStockPaymentID) {
            _ = try await remote.apply(event)
        }
        try await engine.synchronize()
        try await engine.synchronize()
        let context = ModelContext(container)
        #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 6)
        #expect(try await writer.quantity(for: saleStockProductID(1)) == 0)
        #expect(try await writer.quantity(for: saleStockProductID(2)) == 0)
        #expect(await remote.records.count == 6)
        #expect(try SaleLocalDataSource().pendingOperations(in: context).isEmpty)
        #expect(try SaleLocalDataSource().sale(id: closed.id, in: context) == voided)
    }

    @Test
    func `App composition accepts local void and Stock retry converges without touching Sale lineage`() async throws {
        let container = try stockSyncTestContainer()
        let closed = try saleReversalClosedFixture()
        try seedSaleReversal(closed, in: container)
        let dependencies = AppDependencies.live(modelContainer: container)
        let accepted = try await dependencies.voidSale(
            closed,
            reversalID: saleReversalTestID,
            voidedAt: saleReversalTestDate
        )
        #expect(accepted == (try saleReversalVoidedFixture(closed)))
        let context = ModelContext(container)
        let before = try stockPayloads(in: context)
        let queue = try SaleLocalDataSource().pendingOperations(in: context)
        let remote = StockSyncTestRemote(pushFailures: 2)
        let clock = StockSyncTestClock()
        let writer = StockPersistenceActor(modelContainer: container)
        let engine = StockSyncEngine(
            persistenceActor: writer,
            remoteDataSource: remote,
            observationSignal: StockSyncTestSignal(),
            timing: clock.timing
        )
        try await engine.synchronize()
        try await engine.synchronize()
        #expect(await remote.records.count == 6)
        #expect(await clock.waits == [.seconds(1), .seconds(2)])
        #expect(try stockPayloads(in: ModelContext(container)) == before)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)) == queue)
        #expect(try await writer.deliverablePendingMovements().isEmpty)
        #expect(try await writer.quantity(for: saleStockProductID(1)) == 0)
        let saleRemote = ReversalSaleRemote()
        let saleEngine = SaleSyncEngine(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            remoteDataSource: saleRemote,
            observationSignal: SaleObservationSignal()
        )
        try await saleEngine.synchronize()
        try await saleEngine.synchronize()
        #expect(try await saleRemote.record?.liveSale?.toDomain() == accepted)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(try stockPayloads(in: ModelContext(container)) == before)
    }
}

@MainActor
private func withReversalConflictStore(
    closed: Sale,
    inverses: [StockMovement],
    remote: StockSyncTestRemote
) async throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    defer {
        try? FileManager.default.removeItem(at: directory)
    }
    let url = directory.appending(path: "reversal-conflicts.store")
    let lifetime = SaleReversalLifetime()
    try await persistReversalConflicts(
        at: url,
        closed: closed,
        inverses: inverses,
        remote: remote,
        lifetime: lifetime
    )
    #expect(lifetime.container == nil)
    for _ in 0..<2 {
        try verifyReversalConflicts(at: url, lifetime: lifetime)
        #expect(lifetime.container == nil)
    }
}

@MainActor
private func persistReversalConflicts(
    at url: URL,
    closed: Sale,
    inverses: [StockMovement],
    remote: StockSyncTestRemote,
    lifetime: SaleReversalLifetime
) async throws {
    let container = try stockSyncDiskContainer(at: url)
    lifetime.container = container
    try seedSaleReversal(closed, in: container)
    let context = ModelContext(container)
    for event in inverses {
        context.insert(try StockMovementModel(event))
    }
    try context.save()
    let writer = StockPersistenceActor(modelContainer: container)
    let engine = StockSyncEngine(
        persistenceActor: writer,
        remoteDataSource: remote,
        observationSignal: StockSyncTestSignal()
    )
    try await engine.synchronize()
    try await engine.synchronize()
    #expect(try await writer.syncConflicts().count == 3)
    #expect(try await writer.quantity(for: saleStockProductID(1)) == 0)
    #expect(await remote.records.count == 6)
}

@MainActor
private func verifyReversalConflicts(at url: URL, lifetime: SaleReversalLifetime) throws {
    let container = try stockSyncDiskContainer(at: url)
    lifetime.container = container
    let context = ModelContext(container)
    #expect(try StockSyncLocalDataSource().conflicts(in: context).count == 3)
    #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 6)
    #expect(try StockSyncLocalDataSource().pending(in: context).isEmpty)
    #expect(try context.fetch(FetchDescriptor<StockMovementModel>()).filter(\.isPendingSync).count == 3)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == 0)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(2), in: context) == 0)
}

@MainActor
final class SaleReversalLifetime {
    weak var container: ModelContainer?
}

private actor ReversalSaleRemote: SaleRemoteDataSource {
    private(set) var record: SaleRemoteRecord?

    func fetchChanges(after cursor: SaleSyncCursor?) async throws -> SaleRemoteChangeBatch {
        let records = record.map { value in
            (value.changeSequence ?? 0) > (cursor?.changeSequence ?? -1) ? [value] : []
        } ?? []
        return SaleRemoteChangeBatch(
            records: records,
            nextCursor: SaleSyncCursor(changeSequence: record?.changeSequence ?? 0)
        )
    }

    func apply(_ operation: SalePendingOperation) async throws -> SaleRemoteMutationResult {
        switch SaleSyncPolicy().decision(for: operation, against: record) {
        case .apply(let next):
            let accepted = SaleRemoteRecord(
                content: next.content,
                version: next.version,
                changeSequence: (record?.changeSequence ?? 0) + 1
            )
            record = accepted
            return .applied(accepted)
        case .alreadyApplied(let accepted):
            return .alreadyApplied(accepted)
        case .conflict(let reason, let current):
            return .conflict(reason, current)
        case .invalid(let error):
            throw error
        }
    }
}
