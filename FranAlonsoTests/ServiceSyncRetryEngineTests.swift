import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Services synchronization retry engine")
struct ServiceSyncRetryEngineTests {
    @Test("A recoverable pull retries with deterministic exponential delays")
    func recoverablePullRetriesWithDeterministicDelays() async throws {
        let container = try retryEngineContainer()
        let timing = RetryManualTiming(
            now: Date(timeIntervalSinceReferenceDate: 1_000)
        )
        let remote = RetryPullRemote(failuresBeforeSuccess: 2)
        let engine = retryEngine(
            container: container,
            remote: remote,
            timing: timing.dependency
        )

        try await engine.synchronize()

        #expect(await remote.fetchCount == 3)
        #expect(await timing.recordedSleeps == [.seconds(1), .seconds(2)])
        #expect(
            try await ServicePersistenceActor(modelContainer: container)
                .retryState(for: .pull) == nil
        )
    }

    @Test("Each pending operation owns an independent three-attempt budget")
    func eachPendingOperationOwnsIndependentAttemptBudget() async throws {
        let container = try retryEngineContainer()
        let firstService = try retryEngineService(
            id: "72000000-0000-0000-0000-000000000001",
            name: "First retry scope"
        )
        let secondService = try retryEngineService(
            id: "72000000-0000-0000-0000-000000000002",
            name: "Second retry scope"
        )
        let firstOperationID = retryEngineUUID(
            "73000000-0000-0000-0000-000000000001"
        )
        let secondOperationID = retryEngineUUID(
            "73000000-0000-0000-0000-000000000002"
        )
        let actor = ServicePersistenceActor(modelContainer: container)
        try await actor.persistPendingUpsert(
            firstService,
            operationID: firstOperationID
        )
        try await actor.persistPendingUpsert(
            secondService,
            operationID: secondOperationID
        )
        let timing = RetryManualTiming(
            now: Date(timeIntervalSinceReferenceDate: 2_000)
        )
        let remote = RetryOperationsRemote(failuresBeforeSuccess: 2)
        let engine = retryEngine(
            container: container,
            remote: remote,
            timing: timing.dependency
        )

        try await engine.synchronize()

        let receivedOperationIDs = await remote.receivedOperationIDs
        #expect(receivedOperationIDs.filter { $0 == firstOperationID }.count == 3)
        #expect(receivedOperationIDs.filter { $0 == secondOperationID }.count == 3)
        #expect(receivedOperationIDs.count == 6)
        #expect(
            await timing.recordedSleeps
                == [.seconds(1), .seconds(2), .seconds(1), .seconds(2)]
        )
        #expect(try await actor.pendingOperations().isEmpty)
    }

    @Test("A third transient failure persists the next deadline without sleeping")
    func thirdTransientFailurePersistsDeadlineForRestart() async throws {
        let container = try retryEngineContainer()
        let start = Date(timeIntervalSinceReferenceDate: 3_000)
        let timing = RetryManualTiming(now: start)
        let failingRemote = RetryPullRemote(failuresBeforeSuccess: .max)
        let firstEngine = retryEngine(
            container: container,
            remote: failingRemote,
            timing: timing.dependency
        )

        await #expect(throws: ServiceRemoteDataSourceError.unavailable) {
            try await firstEngine.synchronize()
        }

        let actor = ServicePersistenceActor(modelContainer: container)
        let persisted = try #require(
            try await actor.retryState(for: .pull)
        )
        #expect(persisted.backoffStep == 3)
        #expect(persisted.notBefore == start.addingTimeInterval(7))
        #expect(await timing.recordedSleeps == [.seconds(1), .seconds(2)])

        let recoveredRemote = RetryPullRemote(failuresBeforeSuccess: 0)
        let restartedEngine = retryEngine(
            container: container,
            remote: recoveredRemote,
            timing: timing.dependency
        )

        try await restartedEngine.synchronize()

        #expect(
            await timing.recordedSleeps
                == [.seconds(1), .seconds(2), .seconds(4)]
        )
        #expect(try await actor.retryState(for: .pull) == nil)
    }

    @Test("A definitive failure does not sleep and clears previous backoff")
    func definitiveFailureDoesNotSleepAndClearsBackoff() async throws {
        let container = try retryEngineContainer()
        let actor = ServicePersistenceActor(modelContainer: container)
        try await actor.saveRetryState(
            try SyncRetryState(
                scope: .pull,
                backoffStep: 2,
                notBefore: Date(timeIntervalSinceReferenceDate: 3_999),
                lastRecoverableCategory: .unavailable
            )
        )
        let timing = RetryManualTiming(
            now: Date(timeIntervalSinceReferenceDate: 4_000)
        )
        let remote = RetryDefinitivePullRemote()
        let engine = retryEngine(
            container: container,
            remote: remote,
            timing: timing.dependency
        )

        await #expect(throws: ServiceRemoteDataSourceError.permissionDenied) {
            try await engine.synchronize()
        }

        #expect(await remote.fetchCount == 1)
        #expect(await timing.recordedSleeps.isEmpty)
        #expect(try await actor.retryState(for: .pull) == nil)
    }

    @Test("A concurrent synchronization is rejected before another remote call")
    func concurrentSynchronizationIsRejected() async throws {
        let container = try retryEngineContainer()
        let gate = RetryRemoteGate()
        let remote = RetryGatedPullRemote(gate: gate, outcome: .success)
        let engine = retryEngine(
            container: container,
            remote: remote,
            timing: RetryManualTiming(now: .now).dependency
        )
        let first = Task { try await engine.synchronize() }
        await gate.waitUntilBlocked()

        await #expect(throws: ServiceSyncEngineError.alreadySynchronizing) {
            try await engine.synchronize()
        }

        await gate.release()
        try await first.value
        #expect(await remote.fetchCount == 1)
    }

    @Test("Cancellation during an owned sleep preserves the durable retry")
    func cancellationDuringOwnedSleepPreservesRetry() async throws {
        let container = try retryEngineContainer()
        let sleeping = RetrySleepObservation()
        let start = Date(timeIntervalSinceReferenceDate: 5_000)
        let timing = SyncTiming(
            now: { start },
            sleep: { duration in
                await sleeping.didStart(duration)
                try await Task.sleep(for: .seconds(60), clock: .continuous)
            },
            jitterFactor: { 1 }
        )
        let remote = RetryPullRemote(failuresBeforeSuccess: .max)
        let engine = retryEngine(
            container: container,
            remote: remote,
            timing: timing
        )
        let task = Task { try await engine.synchronize() }
        await sleeping.waitUntilStarted()

        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await sleeping.duration == .seconds(1))
        #expect(
            try await ServicePersistenceActor(modelContainer: container)
                .retryState(for: .pull)?.backoffStep == 1
        )
    }

    @Test("Cancellation wins when non-cancelable remote I/O later throws")
    func cancellationWinsWhenRemoteLaterThrows() async throws {
        let container = try retryEngineContainer()
        let gate = RetryRemoteGate()
        let remote = RetryGatedPullRemote(gate: gate, outcome: .unavailable)
        let timing = RetryManualTiming(now: .now)
        let engine = retryEngine(
            container: container,
            remote: remote,
            timing: timing.dependency
        )
        let task = Task { try await engine.synchronize() }
        await gate.waitUntilBlocked()

        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await timing.recordedSleeps.isEmpty)
        #expect(
            try await ServicePersistenceActor(modelContainer: container)
                .retryState(for: .pull) == nil
        )
    }

    @Test("Cancellation during jitter prevents a new durable retry write")
    func cancellationDuringJitterPreventsRetryPersistence() async throws {
        let container = try retryEngineContainer()
        let gate = RetryRemoteGate()
        let start = Date(timeIntervalSinceReferenceDate: 5_500)
        let timing = SyncTiming(
            now: { start },
            sleep: { _ in },
            jitterFactor: {
                await gate.block()
                return 1
            }
        )
        let engine = retryEngine(
            container: container,
            remote: RetryPullRemote(failuresBeforeSuccess: .max),
            timing: timing
        )
        let task = Task { try await engine.synchronize() }
        await gate.waitUntilBlocked()

        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(
            try await ServicePersistenceActor(modelContainer: container)
                .retryState(for: .pull) == nil
        )
    }

    @Test("A remote commit returned after cancellation converges on the next pass")
    func remoteCommitAfterCancellationConvergesOnNextPass() async throws {
        let container = try retryEngineContainer()
        let service = try retryEngineService(
            id: "72000000-0000-0000-0000-000000000003",
            name: "Committed while cancelled"
        )
        let operationID = retryEngineUUID(
            "73000000-0000-0000-0000-000000000003"
        )
        let actor = ServicePersistenceActor(modelContainer: container)
        try await actor.persistPendingUpsert(
            service,
            operationID: operationID
        )
        let gate = RetryRemoteGate()
        let remote = RetryCommittedMutationRemote(gate: gate)
        let engine = retryEngine(
            container: container,
            remote: remote,
            timing: RetryManualTiming(now: .now).dependency
        )
        let cancelledPass = Task { try await engine.synchronize() }
        await gate.waitUntilBlocked()

        cancelledPass.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await cancelledPass.value
        }
        #expect(try await actor.pendingOperations().map(\.operationID) == [operationID])

        try await engine.synchronize()

        #expect(try await actor.pendingOperations().isEmpty)
        #expect(await remote.applyCount == 1)
    }
}

private actor RetryManualTiming {
    private var currentDate: Date
    private var sleeps: [Duration] = []

    init(now: Date) {
        currentDate = now
    }

    nonisolated var dependency: SyncTiming {
        SyncTiming(
            now: { await self.current() },
            sleep: { duration in try await self.sleep(for: duration) },
            jitterFactor: { 1 }
        )
    }

    var recordedSleeps: [Duration] { sleeps }

    private func current() -> Date { currentDate }

    private func sleep(for duration: Duration) throws {
        let components = duration.components
        let interval = Double(components.seconds)
            + Double(components.attoseconds) / 1_000_000_000_000_000_000
        sleeps.append(duration)
        currentDate = currentDate.addingTimeInterval(interval)
    }
}

private actor RetryPullRemote: ServiceRemoteDataSource {
    private let failuresBeforeSuccess: Int
    private var calls = 0

    init(failuresBeforeSuccess: Int) {
        self.failuresBeforeSuccess = failuresBeforeSuccess
    }

    var fetchCount: Int { calls }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        calls += 1
        if calls <= failuresBeforeSuccess {
            throw ServiceRemoteDataSourceError.unavailable
        }
        return ServiceRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? ServiceSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        throw ServiceRemoteDataSourceError.unexpected
    }
}

private actor RetryOperationsRemote: ServiceRemoteDataSource {
    private let failuresBeforeSuccess: Int
    private var attempts: [UUID: Int] = [:]
    private var received: [UUID] = []
    private var sequence: Int64 = 0

    init(failuresBeforeSuccess: Int) {
        self.failuresBeforeSuccess = failuresBeforeSuccess
    }

    var receivedOperationIDs: [UUID] { received }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        ServiceRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? ServiceSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        received.append(operation.operationID)
        let count = attempts[operation.operationID, default: 0] + 1
        attempts[operation.operationID] = count
        if count <= failuresBeforeSuccess {
            throw ServiceRemoteDataSourceError.unavailable
        }
        sequence += 1
        return .applied(
            ServiceRemoteRecord(
                content: retryDesiredContent(for: operation),
                version: .versioned(
                    revision: 1,
                    lastOperationID: operation.operationID
                ),
                changeSequence: sequence
            )
        )
    }
}

private actor RetryDefinitivePullRemote: ServiceRemoteDataSource {
    private var calls = 0

    var fetchCount: Int { calls }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        calls += 1
        throw ServiceRemoteDataSourceError.permissionDenied
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        throw ServiceRemoteDataSourceError.unexpected
    }
}

private actor RetryGatedPullRemote: ServiceRemoteDataSource {
    enum Outcome {
        case success
        case unavailable
    }

    private let gate: RetryRemoteGate
    private let outcome: Outcome
    private var calls = 0

    init(gate: RetryRemoteGate, outcome: Outcome) {
        self.gate = gate
        self.outcome = outcome
    }

    var fetchCount: Int { calls }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        calls += 1
        await gate.block()
        switch outcome {
        case .success:
            return ServiceRemoteChangeBatch(
                records: [],
                nextCursor: cursor ?? ServiceSyncCursor(changeSequence: 0)
            )
        case .unavailable:
            throw ServiceRemoteDataSourceError.unavailable
        }
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        throw ServiceRemoteDataSourceError.unexpected
    }
}

private actor RetryCommittedMutationRemote: ServiceRemoteDataSource {
    private let gate: RetryRemoteGate
    private var record: ServiceRemoteRecord?
    private var applies = 0

    init(gate: RetryRemoteGate) {
        self.gate = gate
    }

    var applyCount: Int { applies }

    func fetchChanges(
        after cursor: ServiceSyncCursor?
    ) async throws -> ServiceRemoteChangeBatch {
        let records: [ServiceRemoteRecord]
        if let record,
           (record.changeSequence ?? 0) > (cursor?.changeSequence ?? -1) {
            records = [record]
        } else {
            records = []
        }
        return ServiceRemoteChangeBatch(
            records: records,
            nextCursor: ServiceSyncCursor(
                changeSequence: record?.changeSequence ?? 0
            )
        )
    }

    func apply(
        _ operation: ServicePendingOperation
    ) async throws -> ServiceRemoteMutationResult {
        applies += 1
        let committed = ServiceRemoteRecord(
            content: retryDesiredContent(for: operation),
            version: .versioned(
                revision: 1,
                lastOperationID: operation.operationID
            ),
            changeSequence: 1
        )
        record = committed
        await gate.block()
        return .applied(committed)
    }
}

private actor RetryRemoteGate {
    private var isBlocked = false
    private var blockedWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func block() async {
        isBlocked = true
        blockedWaiters.forEach { $0.resume() }
        blockedWaiters.removeAll()
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitUntilBlocked() async {
        guard !isBlocked else { return }
        await withCheckedContinuation { continuation in
            blockedWaiters.append(continuation)
        }
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
        isBlocked = false
    }
}

private actor RetrySleepObservation {
    private var startedDuration: Duration?
    private var waiters: [CheckedContinuation<Void, Never>] = []

    var duration: Duration? { startedDuration }

    func didStart(_ duration: Duration) {
        startedDuration = duration
        waiters.forEach { $0.resume() }
        waiters.removeAll()
    }

    func waitUntilStarted() async {
        guard startedDuration == nil else { return }
        await withCheckedContinuation { continuation in
            waiters.append(continuation)
        }
    }
}

private func retryEngine(
    container: ModelContainer,
    remote: any ServiceRemoteDataSource,
    timing: SyncTiming
) -> ServiceSyncEngine {
    ServiceSyncEngine(
        persistenceActor: ServicePersistenceActor(modelContainer: container),
        remoteDataSource: remote,
        observationSignal: ServiceObservationSignal(),
        timing: timing
    )
}

private func retryEngineContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: .franAlonso)
}

private func retryEngineService(id: String, name: String) throws -> Service {
    try makeService(
        id: retryEngineUUID(id),
        name: name,
        discountPercentage: nil
    )
}

private func retryEngineUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}

private func retryDesiredContent(
    for operation: ServicePendingOperation
) -> ServiceRemoteContent {
    switch operation {
    case .upsert(let upsert):
        .live(upsert.service)
    case .delete(let delete):
        .tombstone(serviceID: delete.serviceID)
    }
}
