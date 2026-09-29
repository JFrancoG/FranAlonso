import Foundation
@testable import FranAlonso

actor ProductSyncRemoteFake: ProductRemoteDataSource {
    private var records: [UUID: ProductRemoteRecord]
    private var operationIDs: [UUID] = []
    private var appliedIDs: [UUID] = []
    private let acknowledgementGate: ProductSyncAcknowledgementGate?
    private let policy = ProductSyncPolicy()
    private var changeSequence: Int64
    private var cursors: [ProductSyncCursor?] = []

    init(records: [ProductRemoteRecord] = [], acknowledgementGate: ProductSyncAcknowledgementGate? = nil) {
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
    var requestedCursors: [ProductSyncCursor?] { cursors }

    func fetchChanges(after cursor: ProductSyncCursor?) async throws -> ProductRemoteChangeBatch {
        cursors.append(cursor)
        let records = records.values.filter { record in
            guard let cursor else { return true }
            return (record.changeSequence ?? 0) > cursor.changeSequence
        }.sorted { $0.id > $1.id }
        return ProductRemoteChangeBatch(records: records, nextCursor: ProductSyncCursor(changeSequence: changeSequence))
    }

    func apply(_ operation: ProductPendingOperation) async throws -> ProductRemoteMutationResult {
        operationIDs.append(operation.operationID)
        let currentRecord = records[operation.productID]
        switch policy.decision(for: operation, against: currentRecord) {
        case .apply(let nextRecord):
            appliedIDs.append(operation.operationID)
            changeSequence += 1
            let sequencedRecord = ProductRemoteRecord(
                content: nextRecord.content,
                version: nextRecord.version,
                changeSequence: changeSequence
            )
            records[operation.productID] = sequencedRecord
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

    func receive(_ record: ProductRemoteRecord) throws {
        guard let id = UUID(uuidString: record.id) else { throw ProductRemoteDataSourceError.unexpected }
        records[id] = record
        changeSequence = max(changeSequence, record.changeSequence ?? 0)
    }

    func record(for productID: UUID) -> ProductRemoteRecord? {
        records[productID]
    }
}

actor ProductSyncAcknowledgementGate {
    private var shouldBlock = true
    private var blockedWaiters: [CheckedContinuation<Void, Never>] = []
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func blockOnce() async {
        guard shouldBlock else { return }
        shouldBlock = false
        blockedWaiters.forEach { $0.resume() }
        blockedWaiters.removeAll()
        await withCheckedContinuation { continuation in
            releaseContinuation = continuation
        }
    }

    func waitUntilBlocked() async {
        guard shouldBlock else { return }
        await withCheckedContinuation { continuation in
            blockedWaiters.append(continuation)
        }
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}

actor ProductRetryManualTiming {
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
