import Foundation
import SwiftData

/// Owns atomic, context-confined stock synchronization acceptance without suspension or implicit saves.
struct StockSyncLocalDataSource {
    private let commitChanges: @Sendable (ModelContext) throws -> Void
}

extension StockSyncLocalDataSource {
    /// Injects only the sync commit boundary; manual and payment writers retain their existing contracts.
    init(
        save: @escaping @Sendable (ModelContext) throws -> Void = {
            try $0.save()
        }
    ) {
        self.init(commitChanges: save)
    }

    /// Commits a complete validated batch, cursor and retry cleanup, retaining divergent originals.
    /// Missing Products never prevent retaining history and are never materialized by this operation.
    func reconcile(_ batch: StockRemoteChangeBatch, in context: ModelContext) throws {
        try clean(context)
        let previous = try cursor(in: context)
        try validate(batch, after: previous)
        try verifyBalances(in: context)
        try mutate(context) {
            for record in batch.records {
                try Task.checkCancellation()
                try accept(record, in: context)
            }
            try verifyBalances(in: context)
            if let row = try cursorModel(in: context) {
                if row.changeSequence != batch.nextCursor.changeSequence {
                    row.advance(to: batch.nextCursor.changeSequence)
                }
            } else {
                context.insert(
                    StockSyncCursorModel(feedID: "stockMovements", changeSequence: batch.nextCursor.changeSequence)
                )
            }
            try removeRetry(.pull, in: context)
        }
    }

    /// Returns only still-pending identities without a durable conflict or prior remote acceptance.
    func pending(in context: ModelContext) throws -> [StockMovement] {
        try Task.checkCancellation()
        let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
        var values: [StockMovement] = []
        for row in rows {
            let value = try row.toDomain()
            if row.isPendingSync, try conflict(id: row.id, in: context) == nil,
                try remoteState(id: row.id, in: context) == nil
            {
                values.append(value)
            }
        }
        return values.sorted { $0.id.rawValue.uuidString < $1.id.rawValue.uuidString }
    }

    /// Acknowledges only the exact pending payload with valid immutable remote metadata.
    func acknowledge(_ movement: StockMovement, record: StockRemoteRecord, in context: ModelContext) throws {
        try clean(context)
        let remote = try record.validatedMovement()
        guard remote == movement, let row = try movementModel(id: movement.id.rawValue, in: context),
            try row.toDomain() == movement, try conflict(id: row.id, in: context) == nil
        else {
            throw StockSyncError.identityConflict
        }
        try mutate(context) {
            try accept(record, in: context)
        }
    }

    /// Preserves the local original and the conflicting remote payload, clearing only its retry atomically.
    func recordConflict(_ movement: StockMovement, remote: StockRemoteRecord, in context: ModelContext) throws {
        try clean(context)
        let value = try remote.validatedMovement()
        guard value.id == movement.id, value != movement,
            let row = try movementModel(id: movement.id.rawValue, in: context),
            try row.toDomain() == movement
        else { throw StockSyncError.identityConflict }
        try mutate(context) {
            try accept(remote, in: context)
        }
    }

    func cursor(in context: ModelContext) throws -> StockSyncCursor? {
        try Task.checkCancellation()
        guard let row = try cursorModel(in: context) else { return nil }
        guard row.changeSequence >= 0 else { throw StockSyncError.invalidMetadata }
        return StockSyncCursor(changeSequence: row.changeSequence)
    }

    /// Exposes detached, version-checked conflict snapshots; UI resolution belongs to a later flow.
    func conflicts(in context: ModelContext) throws -> [StockSyncConflict] {
        try context.fetch(FetchDescriptor<StockSyncConflictModel>()).map { row in
            guard row.payloadVersion == 1 else { throw StockSyncError.invalidPayload }
            let conflict = try JSONDecoder().decode(StockSyncConflict.self, from: row.conflictData)
            let local = try conflict.local.toDomain()
            let remote = try conflict.remote.validatedMovement()
            guard local.id.rawValue == row.movementID, local.id == remote.id, local != remote else {
                throw StockSyncError.identityConflict
            }
            return conflict
        }
    }

    func retryState(for scope: SyncRetryScope, in context: ModelContext) throws -> SyncRetryState? {
        try Task.checkCancellation()
        return try retryModel(scope, in: context)?.decodeState(for: scope)
    }

    func persistRetry(_ state: SyncRetryState, in context: ModelContext) throws {
        try clean(context)
        try mutate(context) {
            if let row = try retryModel(state.scope, in: context) {
                try row.update(with: state)
            } else {
                context.insert(StockSyncRetryModel(state))
            }
        }
    }

    func clearRetry(_ scope: SyncRetryScope, in context: ModelContext) throws {
        try clean(context)
        try mutate(context) {
            try removeRetry(scope, in: context)
        }
    }
}

extension StockSyncLocalDataSource {
    fileprivate func clean(_ context: ModelContext) throws {
        try Task.checkCancellation()
        guard !context.hasChanges else { throw StockSyncError.storageFailure }
    }

    fileprivate func mutate(_ context: ModelContext, operation: () throws -> Void) throws {
        let autosave = context.autosaveEnabled
        context.autosaveEnabled = false
        defer { context.autosaveEnabled = autosave }
        do {
            try operation()
            try Task.checkCancellation()
            if context.hasChanges {
                try commitChanges(context)
            }
        } catch {
            context.rollback()
            throw error
        }
    }

    fileprivate func validate(_ batch: StockRemoteChangeBatch, after cursor: StockSyncCursor?) throws {
        let previous = cursor?.changeSequence ?? 0
        guard previous >= 0, batch.nextCursor.changeSequence >= previous else { throw StockSyncError.invalidBatch }
        var ids: Set<StockMovementID> = []
        var sequences: Set<Int64> = []
        for record in batch.records {
            let movement = try record.validatedMovement()
            guard record.changeSequence > previous, ids.insert(movement.id).inserted,
                sequences.insert(record.changeSequence).inserted
            else { throw StockSyncError.invalidBatch }
        }
        guard batch.nextCursor.changeSequence == (sequences.max() ?? previous) else {
            throw StockSyncError.invalidBatch
        }
    }

    fileprivate func accept(_ record: StockRemoteRecord, in context: ModelContext) throws {
        let remote = try record.validatedMovement()
        let id = remote.id.rawValue
        if let previous = try remoteState(id: id, in: context) {
            guard previous.revision == record.revision, previous.operationID == record.operationID,
                previous.changeSequence == record.changeSequence
            else { throw StockSyncError.invalidMetadata }
        }
        if let row = try movementModel(id: id, in: context) {
            let local = try row.toDomain()
            if local != remote {
                let value = StockSyncConflict(local: try StockMovementDTO(local), remote: record)
                if let old = try conflict(id: id, in: context) {
                    guard old.payloadVersion == 1,
                        try JSONDecoder().decode(StockSyncConflict.self, from: old.conflictData) == value
                    else {
                        throw StockSyncError.identityConflict
                    }
                } else {
                    context.insert(
                        StockSyncConflictModel(
                            movementID: id,
                            payloadVersion: 1,
                            conflictData: try JSONEncoder().encode(value)
                        )
                    )
                }
                try removeRetry(.operation(id), in: context)
                return
            }
            guard try conflict(id: id, in: context) == nil else { throw StockSyncError.identityConflict }
            row.acknowledgeSync()
        } else {
            let row = try StockMovementModel(remote)
            row.acknowledgeSync()
            context.insert(row)
        }
        if try remoteState(id: id, in: context) == nil {
            context.insert(
                StockRemoteStateModel(movementID: id, payloadVersion: 1, recordData: try JSONEncoder().encode(record))
            )
        }
        try removeRetry(.operation(id), in: context)
    }

    fileprivate func verifyBalances(in context: ModelContext) throws {
        var deltas: [ProductID: [Int]] = [:]
        for row in try context.fetch(FetchDescriptor<StockMovementModel>()) {
            let movement = try row.toDomain()
            deltas[movement.productID, default: []].append(movement.quantityDelta)
        }
        for values in deltas.values {
            _ = try StockQuantityPolicy().quantity(deltas: values)
        }
    }

    fileprivate func movementModel(id: UUID, in context: ModelContext) throws -> StockMovementModel? {
        try context.fetch(FetchDescriptor<StockMovementModel>(predicate: #Predicate { $0.id == id })).first
    }

    fileprivate func conflict(id: UUID, in context: ModelContext) throws -> StockSyncConflictModel? {
        try context.fetch(FetchDescriptor<StockSyncConflictModel>(predicate: #Predicate { $0.movementID == id })).first
    }

    fileprivate func remoteState(id: UUID, in context: ModelContext) throws -> StockRemoteRecord? {
        guard
            let row = try context.fetch(
                FetchDescriptor<StockRemoteStateModel>(
                    predicate: #Predicate { $0.movementID == id }
                )
            ).first
        else { return nil }
        guard row.payloadVersion == 1 else { throw StockSyncError.invalidPayload }
        let record = try JSONDecoder().decode(StockRemoteRecord.self, from: row.recordData)
        guard try record.validatedMovement().id.rawValue == id else { throw StockSyncError.invalidMetadata }
        return record
    }

    fileprivate func cursorModel(in context: ModelContext) throws -> StockSyncCursorModel? {
        let rows = try context.fetch(FetchDescriptor<StockSyncCursorModel>())
        guard rows.count <= 1, rows.first?.feedID == "stockMovements" || rows.isEmpty else {
            throw StockSyncError.invalidMetadata
        }
        return rows.first
    }

    fileprivate func retryModel(_ scope: SyncRetryScope, in context: ModelContext) throws -> StockSyncRetryModel? {
        let id = scope.storageID
        return try context.fetch(FetchDescriptor<StockSyncRetryModel>(predicate: #Predicate { $0.scopeID == id })).first
    }

    fileprivate func removeRetry(_ scope: SyncRetryScope, in context: ModelContext) throws {
        if let row = try retryModel(scope, in: context) {
            context.delete(row)
        }
    }
}
