import Foundation
import SwiftData

private let saleSyncFeedID = "sales"

/// Performs context-confined Sales persistence without retaining live SwiftData state.
struct SaleLocalDataSource {}

extension SaleLocalDataSource {
    /// Fetches and maps the locally persisted sale snapshot.
    func fetchAll(in context: ModelContext) throws -> [Sale] {
        let descriptor = FetchDescriptor<SaleModel>(
            sortBy: [
                SortDescriptor(\SaleModel.createdAt),
                SortDescriptor(\SaleModel.id)
            ]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    /// Materializes a sale without creating a pending local mutation.
    func upsert(_ sale: Sale, in context: ModelContext) throws {
        try materialize(sale, in: context)
        try saveChanges(in: context)
    }

    /// Commits a sale and an immutable causal upsert in the same save boundary.
    ///
    /// A tombstone or pending discard blocks ordinary upserts so restoration cannot occur
    /// accidentally. A future explicit restore flow owns that separate state transition.
    func persistPendingUpsert(
        _ sale: Sale,
        operationID: UUID,
        in context: ModelContext
    ) throws {
        try requireClean(context)

        do {
            guard try conflict(for: sale.id, in: context) == nil else {
                throw SaleLocalDataSourceError.syncConflictPending(sale.id)
            }
            guard try !hasDeletionState(for: sale.id, in: context) else {
                throw SaleLocalDataSourceError.restoreRequiresExplicitResolution(
                    sale.id
                )
            }

            let payload = try SaleDTO(sale)
            let operations = try pendingOperations(
                for: sale.id,
                in: context
            )
            let head = try pendingHead(
                from: operations,
                saleID: sale.id
            )
            let headPayload: SaleDTO?
            if case .upsert(let upsert) = head {
                headPayload = upsert.sale
            } else {
                headPayload = nil
            }

            if headPayload != payload {
                try ensureOperationIdentityAvailable(
                    operationID,
                    in: context
                )
                context.insert(
                    try SalePendingUpsertModel(
                        saleID: sale.id.rawValue,
                        operationID: operationID,
                        predecessorOperationID: head?.operationID,
                        base: try remoteBase(for: sale.id, in: context),
                        payload: payload
                    )
                )
            }

            try materialize(sale, in: context)
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Removes an active draft and commits a durable tombstone operation atomically.
    ///
    /// An already discarded draft is a no-op only when no live remote state or pending chain
    /// remains. A repeated discard keeps the existing pending operation identity.
    func persistPendingDiscard(
        _ id: SaleID,
        operationID: UUID,
        in context: ModelContext
    ) throws {
        try requireClean(context)

        do {
            let operations = try pendingOperations(for: id, in: context)
            if operations.contains(where: { operation in
                if case .discard = operation { return true }
                return false
            }) {
                if let model = try model(for: id, in: context) {
                    context.delete(model)
                    try saveChanges(in: context)
                }
                return
            }

            let localModel = try model(for: id, in: context)
            let remoteRecord = try remoteState(for: id, in: context)?.decodeRecord()
            guard localModel != nil
                    || !operations.isEmpty
                    || remoteRecord?.isLive == true else {
                return
            }

            let pendingSales: [Sale] = try operations.reversed().compactMap { operation in
                guard case .upsert(let upsert) = operation else { return nil }
                return try upsert.sale.toDomain()
            }
            let currentSale = try localModel?.toDomain()
                ?? pendingSales.first
                ?? remoteRecord?.liveSale?.toDomain()
            guard currentSale?.status == .draft else {
                throw SaleLocalDataSourceError.discardRequiresDraft(id)
            }

            try ensureOperationIdentityAvailable(operationID, in: context)
            let head = try pendingHead(from: operations, saleID: id)
            context.insert(
                try SalePendingDiscardModel(
                    saleID: id.rawValue,
                    operationID: operationID,
                    predecessorOperationID: head?.operationID,
                    base: try remoteBase(for: id, in: context)
                )
            )
            if let localModel {
                context.delete(localModel)
            }
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Returns every immutable pending operation in deterministic causal order.
    func pendingOperations(
        in context: ModelContext
    ) throws -> [SalePendingOperation] {
        let upserts = try context.fetch(
            FetchDescriptor<SalePendingUpsertModel>()
        ).map { model in
            SalePendingOperation.upsert(
                SalePendingUpsert(
                    saleID: model.saleID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase(),
                    sale: try model.decodePayload()
                )
            )
        }
        let discards = try context.fetch(
            FetchDescriptor<SalePendingDiscardModel>()
        ).map { model in
            SalePendingOperation.discard(
                SalePendingDiscard(
                    saleID: model.saleID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase()
                )
            )
        }
        return try causallySorted(upserts + discards)
    }

    /// Returns only upserts from the complete causal operation chain.
    func pendingUpserts(in context: ModelContext) throws -> [SalePendingUpsert] {
        try pendingOperations(in: context).compactMap { operation in
            guard case .upsert(let upsert) = operation else { return nil }
            return upsert
        }
    }

    /// Returns operations eligible for delivery while preserving explicit conflicts.
    func deliverablePendingOperations(
        in context: ModelContext
    ) throws -> [SalePendingOperation] {
        let conflictedSaleIDs = Set(
            try context.fetch(
                FetchDescriptor<SaleSyncConflictModel>()
            ).map(\.saleID)
        )

        return try pendingOperations(in: context).filter { operation in
            !conflictedSaleIDs.contains(operation.saleID)
        }
    }

    /// Returns only deliverable upserts that are not blocked by conflicts.
    func deliverablePendingUpserts(
        in context: ModelContext
    ) throws -> [SalePendingUpsert] {
        try deliverablePendingOperations(in: context).compactMap { operation in
            guard case .upsert(let upsert) = operation else { return nil }
            return upsert
        }
    }

    /// Returns the durable Sales feed position, or nil before the first bootstrap.
    func cursor(in context: ModelContext) throws -> SaleSyncCursor? {
        try cursorModel(in: context).map { model in
            guard model.changeSequence >= 0 else { throw SaleSyncPersistenceError.invalidCursor }
            return SaleSyncCursor(
                changeSequence: model.changeSequence
            )
        }
    }

    /// Returns the validated durable schedule for one retry scope, when present.
    func retryState(
        for scope: SyncRetryScope,
        in context: ModelContext
    ) throws -> SyncRetryState? {
        try retryModel(for: scope, in: context)?.decodeState(for: scope)
    }

    /// Inserts or replaces one durable retry schedule and commits it explicitly.
    func saveRetryState(
        _ state: SyncRetryState,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        do {
            if let model = try retryModel(for: state.scope, in: context) {
                try model.update(with: state)
            } else {
                context.insert(SaleSyncRetryModel(state))
            }
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Removes a transient backoff without discarding its pending sync operation.
    func clearRetryState(
        for scope: SyncRetryScope,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        do {
            try deleteRetryState(for: scope, in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Reconciles a complete remote batch and advances its cursor in one local commit.
    ///
    /// Any decoding, policy, identity or save failure rolls back every materialization,
    /// tombstone, conflict, acknowledgement and cursor change from this batch.
    func reconcileRemoteBatch(
        _ batch: SaleRemoteChangeBatch,
        policy: SaleSyncPolicy,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)

        do {
            let currentCursor = try cursor(in: context)
            guard batch.nextCursor.changeSequence >= 0,
                  batch.nextCursor.changeSequence
                    >= (currentCursor?.changeSequence ?? 0) else {
                throw SaleSyncPersistenceError.invalidCursor
            }
            for record in batch.records {
                if let sequence = record.changeSequence {
                    guard sequence > 0,
                          sequence <= batch.nextCursor.changeSequence else {
                        throw SaleSyncPersistenceError.invalidCursor
                    }
                } else if currentCursor != nil {
                    throw SaleSyncPersistenceError.invalidCursor
                }
            }
            let receivedMaximum = batch.records
                .compactMap(\.changeSequence)
                .max()
                ?? 0
            let expectedNextSequence = max(
                currentCursor?.changeSequence ?? 0,
                receivedMaximum
            )
            guard batch.nextCursor.changeSequence
                    == expectedNextSequence else {
                throw SaleSyncPersistenceError.invalidCursor
            }

            let orderedRecords = batch.records.sorted { left, right in
                let leftKey = (left.changeSequence ?? 0, left.id)
                let rightKey = (right.changeSequence ?? 0, right.id)
                return leftKey < rightKey
            }
            for record in orderedRecords {
                let saleID = SaleID(rawValue: try record.stableSaleID())
                if try isStale(record, for: saleID, in: context) {
                    continue
                }
                let operation = try pendingOperations(
                    for: saleID,
                    in: context
                ).first
                guard let operation else {
                    try applyRemoteObservation(record, in: context)
                    continue
                }

                switch policy.decision(for: operation, against: record) {
                case .apply:
                    try applyRemoteObservation(record, in: context)
                case .alreadyApplied(let acknowledgedRecord):
                    try applyAcknowledgement(
                        operation: operation,
                        record: acknowledgedRecord,
                        in: context
                    )
                    try deleteRetryState(
                        for: .operation(operation.operationID),
                        in: context
                    )
                case .conflict(let reason, let remoteRecord):
                    try applyConflict(
                        operation: operation,
                        reason: reason,
                        remoteRecord: remoteRecord,
                        in: context
                    )
                    try deleteRetryState(
                        for: .operation(operation.operationID),
                        in: context
                    )
                case .invalid(let error):
                    throw error
                }
            }

            try advanceCursor(batch.nextCursor, in: context)
            if let retryScope {
                try deleteRetryState(for: retryScope, in: context)
            }
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Persists a remote acknowledgement without overwriting newer local work.
    func acknowledge(
        operationID: UUID,
        record: SaleRemoteRecord,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        do {
            let operation = try requirePendingOperation(
                operationID: operationID,
                in: context
            )
            try applyAcknowledgement(
                operation: operation,
                record: record,
                in: context
            )
            if let retryScope {
                try deleteRetryState(for: retryScope, in: context)
            }
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Records an authoritative remote observation while preserving pending work.
    func recordRemoteObservation(
        _ record: SaleRemoteRecord,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        do {
            try applyRemoteObservation(record, in: context)
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Preserves the local operation and complete remote state for explicit resolution.
    func recordConflict(
        operation: SalePendingOperation,
        reason: SaleSyncConflictReason,
        remoteRecord: SaleRemoteRecord?,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        do {
            try applyConflict(
                operation: operation,
                reason: reason,
                remoteRecord: remoteRecord,
                in: context
            )
            if let retryScope {
                try deleteRetryState(for: retryScope, in: context)
            }
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    private func applyAcknowledgement(
        operation: SalePendingOperation,
        record: SaleRemoteRecord,
        in context: ModelContext
    ) throws {
        guard try record.stableSaleID() == operation.saleID else {
            throw SaleSyncPersistenceError.entityIdentityMismatch
        }
        switch operation {
        case .upsert(let upsert):
            guard record.lastOperationID == upsert.operationID,
                  record.liveSale == upsert.sale else {
                throw SaleSyncPersistenceError.entityIdentityMismatch
            }
        case .discard:
            guard record.isTombstone else { throw SaleSyncPersistenceError.entityIdentityMismatch }
        }

        try persistRemoteState(record, in: context)
        switch operation {
        case .upsert(let upsert):
            if let model = try pendingUpsertModel(
                operationID: upsert.operationID,
                in: context
            ) {
                context.delete(model)
            }
            let descendantsRemain = try pendingOperations(
                for: SaleID(rawValue: upsert.saleID),
                in: context
            ).contains { $0.operationID != upsert.operationID }
            if !descendantsRemain,
               try conflict(
                for: SaleID(rawValue: upsert.saleID),
                in: context
               ) == nil,
               let sale = record.liveSale {
                try materialize(try sale.toDomain(), in: context)
            }
        case .discard(let discard):
            try removePendingChain(
                for: SaleID(rawValue: discard.saleID),
                in: context
            )
            if let conflict = try conflict(
                for: SaleID(rawValue: discard.saleID),
                in: context
            ) {
                context.delete(conflict)
            }
            if let model = try model(
                for: SaleID(rawValue: discard.saleID),
                in: context
            ) {
                context.delete(model)
            }
        }
    }

    private func applyRemoteObservation(_ record: SaleRemoteRecord, in context: ModelContext) throws {
        let saleID = SaleID(rawValue: try record.stableSaleID())
        try persistRemoteState(record, in: context)
        let hasPending = try !pendingOperations(
            for: saleID,
            in: context
        ).isEmpty
        let hasConflict = try conflict(for: saleID, in: context) != nil

        switch record.content {
        case .live(let sale):
            if !hasPending, !hasConflict {
                try materialize(try sale.toDomain(), in: context)
            }
        case .tombstone:
            if let model = try model(for: saleID, in: context) {
                context.delete(model)
            }
        }
    }

    private func applyConflict(
        operation: SalePendingOperation,
        reason: SaleSyncConflictReason,
        remoteRecord: SaleRemoteRecord?,
        in context: ModelContext
    ) throws {
        if let remoteRecord,
           try remoteRecord.stableSaleID() != operation.saleID {
            throw SaleSyncPersistenceError.entityIdentityMismatch
        }
        let saleID = SaleID(rawValue: operation.saleID)
        if let model = try conflict(for: saleID, in: context) {
            try model.update(
                operation: operation,
                reason: reason,
                remoteRecord: remoteRecord
            )
        } else {
            context.insert(
                try SaleSyncConflictModel(
                    operation: operation,
                    reason: reason,
                    remoteRecord: remoteRecord
                )
            )
        }
        if let remoteRecord {
            try persistRemoteState(remoteRecord, in: context)
            if remoteRecord.isTombstone,
               let localModel = try model(for: saleID, in: context) {
                context.delete(localModel)
            }
        }
    }

    private func isStale(_ record: SaleRemoteRecord, for id: SaleID, in context: ModelContext) throws -> Bool {
        guard let current = try remoteState(for: id, in: context)?.decodeRecord() else {
            return false
        }
        switch (current.changeSequence, record.changeSequence) {
        case (.some(let currentSequence), .some(let incomingSequence)):
            if incomingSequence < currentSequence { return true }
            if incomingSequence == currentSequence, current != record {
                throw SaleSyncPersistenceError.invalidCursor
            }
            return incomingSequence == currentSequence
        case (.some, nil):
            return true
        case (nil, .some):
            return false
        case (nil, nil):
            return current == record
        }
    }

    private func advanceCursor(_ cursor: SaleSyncCursor, in context: ModelContext) throws {
        if let model = try cursorModel(in: context) {
            model.advance(to: cursor.changeSequence)
        } else {
            context.insert(
                SaleSyncCursorModel(
                    feedID: saleSyncFeedID,
                    changeSequence: cursor.changeSequence
                )
            )
        }
    }

    private func cursorModel(in context: ModelContext) throws -> SaleSyncCursorModel? {
        var descriptor = FetchDescriptor<SaleSyncCursorModel>(
            predicate: #Predicate { model in
                model.feedID == saleSyncFeedID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func retryModel(for scope: SyncRetryScope, in context: ModelContext) throws -> SaleSyncRetryModel? {
        let scopeID = scope.storageID
        var descriptor = FetchDescriptor<SaleSyncRetryModel>(
            predicate: #Predicate { model in
                model.scopeID == scopeID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func deleteRetryState(for scope: SyncRetryScope, in context: ModelContext) throws {
        if let model = try retryModel(for: scope, in: context) {
            context.delete(model)
        }
    }

    private func requireClean(_ context: ModelContext) throws {
        guard !context.hasChanges else { throw SaleLocalDataSourceError.contextHasUncommittedChanges }
    }

    private func model(for id: SaleID, in context: ModelContext) throws -> SaleModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<SaleModel>(
            predicate: #Predicate { model in model.id == rawIdentifier }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingOperations(for id: SaleID, in context: ModelContext) throws -> [SalePendingOperation] {
        try pendingOperations(in: context).filter {
            $0.saleID == id.rawValue
        }
    }

    private func pendingUpsertModels(for id: SaleID, in context: ModelContext) throws -> [SalePendingUpsertModel] {
        let rawIdentifier = id.rawValue
        return try context.fetch(
            FetchDescriptor<SalePendingUpsertModel>(
                predicate: #Predicate { model in
                    model.saleID == rawIdentifier
                }
            )
        )
    }

    private func pendingDiscardModels(for id: SaleID, in context: ModelContext) throws -> [SalePendingDiscardModel] {
        let rawIdentifier = id.rawValue
        return try context.fetch(
            FetchDescriptor<SalePendingDiscardModel>(
                predicate: #Predicate { model in
                    model.saleID == rawIdentifier
                }
            )
        )
    }

    private func pendingUpsertModel(operationID: UUID, in context: ModelContext) throws -> SalePendingUpsertModel? {
        var descriptor = FetchDescriptor<SalePendingUpsertModel>(
            predicate: #Predicate { model in
                model.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingDiscardModel(operationID: UUID, in context: ModelContext) throws -> SalePendingDiscardModel? {
        var descriptor = FetchDescriptor<SalePendingDiscardModel>(
            predicate: #Predicate { model in
                model.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func requirePendingOperation(operationID: UUID, in context: ModelContext) throws -> SalePendingOperation {
        if let model = try pendingUpsertModel(
            operationID: operationID,
            in: context
        ) {
            return .upsert(
                SalePendingUpsert(
                    saleID: model.saleID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase(),
                    sale: try model.decodePayload()
                )
            )
        }
        if let model = try pendingDiscardModel(
            operationID: operationID,
            in: context
        ) {
            return .discard(
                SalePendingDiscard(
                    saleID: model.saleID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase()
                )
            )
        }
        throw SaleSyncPersistenceError.entityIdentityMismatch
    }

    private func ensureOperationIdentityAvailable(_ operationID: UUID, in context: ModelContext) throws {
        guard try pendingUpsertModel(
            operationID: operationID,
            in: context
        ) == nil,
        try pendingDiscardModel(
            operationID: operationID,
            in: context
        ) == nil else {
            throw SaleSyncPersistenceError.duplicateOperationIdentity(
                operationID
            )
        }
    }

    private func pendingHead(from operations: [SalePendingOperation], saleID: SaleID) throws -> SalePendingOperation? {
        let predecessorIDs = Set(
            operations.compactMap(\.predecessorOperationID)
        )
        let heads = operations.filter {
            !predecessorIDs.contains($0.operationID)
        }
        guard heads.count <= 1 else {
            throw SaleSyncPersistenceError.ambiguousPendingLineage(saleID)
        }
        return heads.first
    }

    private func remoteState(for id: SaleID, in context: ModelContext) throws -> SaleRemoteStateModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<SaleRemoteStateModel>(
            predicate: #Predicate { state in
                state.saleID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func remoteBase(for id: SaleID, in context: ModelContext) throws -> SaleRemoteBase {
        guard let record = try remoteState(for: id, in: context)?.decodeRecord() else {
            return .absent
        }
        switch (record.version, record.content) {
        case (.legacy, .live(let sale)):
            return .legacy(sale)
        case (.versioned(let revision, _), .live):
            return .versioned(revision)
        case (.versioned(let revision, _), .tombstone):
            return .tombstone(revision)
        case (.legacy, .tombstone):
            throw SaleSyncPersistenceError.entityIdentityMismatch
        }
    }

    private func hasDeletionState(for id: SaleID, in context: ModelContext) throws -> Bool {
        if try !pendingDiscardModels(for: id, in: context).isEmpty {
            return true
        }
        return try remoteState(for: id, in: context)?.decodeRecord().isTombstone
            == true
    }

    private func persistRemoteState(_ record: SaleRemoteRecord, in context: ModelContext) throws {
        let saleID = SaleID(rawValue: try record.stableSaleID())
        if let state = try remoteState(for: saleID, in: context) {
            try state.update(record: record)
        } else {
            context.insert(try SaleRemoteStateModel(record: record))
        }
    }

    private func conflict(for id: SaleID, in context: ModelContext) throws -> SaleSyncConflictModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<SaleSyncConflictModel>(
            predicate: #Predicate { conflict in
                conflict.saleID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func removePendingChain(for id: SaleID, in context: ModelContext) throws {
        for model in try pendingUpsertModels(for: id, in: context) {
            context.delete(model)
        }
        for model in try pendingDiscardModels(for: id, in: context) {
            context.delete(model)
        }
    }

    private func causallySorted(_ operations: [SalePendingOperation]) throws -> [SalePendingOperation] {
        var remaining: [UUID: SalePendingOperation] = [:]
        for operation in operations {
            guard remaining[operation.operationID] == nil else {
                throw SaleSyncPersistenceError.duplicateOperationIdentity(
                    operation.operationID
                )
            }
            remaining[operation.operationID] = operation
        }
        var sorted: [SalePendingOperation] = []

        while !remaining.isEmpty {
            let ready = remaining.values.filter { operation in
                guard let predecessor = operation.predecessorOperationID else { return true }
                return remaining[predecessor] == nil
            }.sorted { left, right in
                let leftKey = "\(left.saleID.uuidString)/\(left.operationID.uuidString)"
                let rightKey = "\(right.saleID.uuidString)/\(right.operationID.uuidString)"
                return leftKey < rightKey
            }

            guard !ready.isEmpty else {
                guard let remainingOperation = remaining.values.first else { return sorted }
                throw SaleSyncPersistenceError.cyclicPendingLineage(
                    SaleID(rawValue: remainingOperation.saleID)
                )
            }
            for operation in ready {
                sorted.append(operation)
                remaining.removeValue(forKey: operation.operationID)
            }
        }
        return sorted
    }

    private func materialize(_ sale: Sale, in context: ModelContext) throws {
        if let model = try model(for: sale.id, in: context) {
            try model.update(from: sale)
        } else {
            context.insert(try SaleModel(sale))
        }
    }

    private func saveChanges(in context: ModelContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}

/// Failures that protect the boundary of a caller-owned Sales context.
enum SaleLocalDataSourceError: Error, Equatable {
    case contextHasUncommittedChanges
    case syncConflictPending(SaleID)
    case restoreRequiresExplicitResolution(SaleID)
    case discardRequiresDraft(SaleID)
}

private extension SaleRemoteRecord {
    var lastOperationID: UUID? {
        guard case .versioned(_, let lastOperationID) = version else { return nil }
        return lastOperationID
    }
}
