import Foundation
@testable import FranAlonso

actor ServiceSyncRemoteFake: ServiceRemoteDataSource {
    private var records: [UUID: ServiceRemoteRecord]
    private var operationIDs: [UUID] = []
    private var appliedIDs: [UUID] = []
    private let acknowledgementGate: ServiceSyncAcknowledgementGate?
    private let policy = ServiceSyncPolicy()
    private var changeSequence: Int64
    private var cursors: [ServiceSyncCursor?] = []

    init(records: [ServiceRemoteRecord] = [], acknowledgementGate: ServiceSyncAcknowledgementGate? = nil) {
        self.records = Dictionary(
            uniqueKeysWithValues: records.compactMap { record in
                guard let identifier = UUID(uuidString: record.id) else { return nil }
                return (identifier, record)
            }
        )
        changeSequence = records.compactMap(\.changeSequence).max() ?? 0
        self.acknowledgementGate = acknowledgementGate
    }

    var recordCount: Int { records.count }
    var receivedOperationIDs: [UUID] { operationIDs }
    var appliedOperationIDs: [UUID] { appliedIDs }
    var requestedCursors: [ServiceSyncCursor?] { cursors }

    func fetchChanges(after cursor: ServiceSyncCursor?) async throws -> ServiceRemoteChangeBatch {
        cursors.append(cursor)
        let records = records.values.filter { record in
            guard let cursor else { return true }
            return (record.changeSequence ?? 0) > cursor.changeSequence
        }.sorted { $0.id > $1.id }
        return ServiceRemoteChangeBatch(records: records, nextCursor: ServiceSyncCursor(changeSequence: changeSequence))
    }

    func apply(_ operation: ServicePendingOperation) async throws -> ServiceRemoteMutationResult {
        operationIDs.append(operation.operationID)
        let currentRecord = records[operation.serviceID]
        switch policy.decision(for: operation, against: currentRecord) {
        case .apply(let nextRecord):
            appliedIDs.append(operation.operationID)
            changeSequence += 1
            let sequencedRecord = ServiceRemoteRecord(
                content: nextRecord.content,
                version: nextRecord.version,
                changeSequence: changeSequence
            )
            records[operation.serviceID] = sequencedRecord
            if let acknowledgementGate {
                await acknowledgementGate.blockOnce()
            }
            return .applied(sequencedRecord)
        case .alreadyApplied(let record):
            return .alreadyApplied(record)
        case .conflict(let reason, let record):
            return .conflict(reason, record)
        case .invalid(let error):
            throw error
        }
    }

    func receive(_ record: ServiceRemoteRecord) throws {
        guard let id = UUID(uuidString: record.id) else { throw ServiceRemoteDataSourceError.unexpected }
        records[id] = record
        changeSequence = max(changeSequence, record.changeSequence ?? 0)
    }

    func record(for serviceID: UUID) -> ServiceRemoteRecord? {
        records[serviceID]
    }
}

actor ServiceSyncAcknowledgementGate {
    private var shouldBlock = true
    private var synchronizationFinished = false
    private var blockedWaiters: [CheckedContinuation<Bool, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func blockOnce() async {
        guard shouldBlock else { return }
        shouldBlock = false
        blockedWaiters.forEach { $0.resume(returning: true) }
        blockedWaiters.removeAll()
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitUntilBlocked() async {
        _ = await waitUntilBlockedOrFinished()
    }

    func waitUntilBlockedOrFinished() async -> Bool {
        guard shouldBlock else { return true }
        guard !synchronizationFinished else { return false }
        return await withCheckedContinuation { continuation in
            blockedWaiters.append(continuation)
        }
    }

    func finishSynchronization() {
        synchronizationFinished = true
        blockedWaiters.forEach { $0.resume(returning: false) }
        blockedWaiters.removeAll()
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

actor ServiceRetryManualTiming {
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
