import Foundation
import SwiftData

private let serviceSyncFeedID = "services"

/// Performs context-confined Services persistence without retaining live SwiftData state.
struct ServiceLocalDataSource {}

extension ServiceLocalDataSource {
    /// Fetches and maps the locally persisted service snapshot.
    func fetchAll(in context: ModelContext) throws -> [Service] {
        let descriptor = FetchDescriptor<ServiceModel>(
            sortBy: [SortDescriptor(\ServiceModel.name)]
        )
        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    /// Materializes a service without creating a pending local mutation.
    func upsert(_ service: Service, in context: ModelContext) throws {
        try materialize(service, in: context)
        try saveChanges(in: context)
    }

    /// Commits a service and an immutable causal upsert in the same save boundary.
    ///
    /// A tombstone or pending deletion blocks ordinary upserts so restoration cannot occur
    /// accidentally. A future explicit restore flow owns that separate state transition.
    func persistPendingUpsert(
        _ service: Service,
        operationID: UUID,
        in context: ModelContext
    ) throws {
        try requireClean(context)

        do {
            guard try conflict(for: service.id, in: context) == nil else {
                throw ServiceLocalDataSourceError.syncConflictPending(service.id)
            }
            guard try !hasDeletionState(for: service.id, in: context) else {
                throw ServiceLocalDataSourceError.restoreRequiresExplicitResolution(
                    service.id
                )
            }

            let payload = try ServiceDTO(service)
            let operations = try pendingOperations(
                for: service.id,
                in: context
            )
            let head = try pendingHead(
                from: operations,
                serviceID: service.id
            )
            let headPayload: ServiceDTO?
            if case .upsert(let upsert) = head {
                headPayload = upsert.service
            } else {
                headPayload = nil
            }

            if headPayload != payload {
                try ensureOperationIdentityAvailable(
                    operationID,
                    in: context
                )
                context.insert(
                    try ServicePendingUpsertModel(
                        serviceID: service.id.rawValue,
                        operationID: operationID,
                        predecessorOperationID: head?.operationID,
                        base: try remoteBase(for: service.id, in: context),
                        payload: payload
                    )
                )
            }

            try materialize(service, in: context)
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Removes the active service and commits a durable tombstone operation atomically.
    ///
    /// An already deleted service is a no-op only when no live remote state or pending chain
    /// remains. A repeated delete keeps the existing pending operation identity.
    func persistPendingDelete(
        _ id: ServiceID,
        operationID: UUID,
        in context: ModelContext
    ) throws {
        try requireClean(context)

        do {
            let operations = try pendingOperations(for: id, in: context)
            if operations.contains(where: { operation in
                if case .delete = operation { return true }
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

            try ensureOperationIdentityAvailable(operationID, in: context)
            let head = try pendingHead(from: operations, serviceID: id)
            context.insert(
                try ServicePendingDeleteModel(
                    serviceID: id.rawValue,
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
    ) throws -> [ServicePendingOperation] {
        let upserts = try context.fetch(
            FetchDescriptor<ServicePendingUpsertModel>()
        ).map { model in
            ServicePendingOperation.upsert(
                ServicePendingUpsert(
                    serviceID: model.serviceID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase(),
                    service: try model.decodePayload()
                )
            )
        }
        let deletes = try context.fetch(
            FetchDescriptor<ServicePendingDeleteModel>()
        ).map { model in
            ServicePendingOperation.delete(
                ServicePendingDelete(
                    serviceID: model.serviceID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase()
                )
            )
        }
        return try causallySorted(upserts + deletes)
    }

    /// Returns only upserts from the complete causal operation chain.
    func pendingUpserts(in context: ModelContext) throws -> [ServicePendingUpsert] {
        try pendingOperations(in: context).compactMap { operation in
            guard case .upsert(let upsert) = operation else { return nil }
            return upsert
        }
    }

    /// Returns operations eligible for delivery while preserving delete-wins semantics.
    func deliverablePendingOperations(
        in context: ModelContext
    ) throws -> [ServicePendingOperation] {
        let conflictedServiceIDs = Set(
            try context.fetch(
                FetchDescriptor<ServiceSyncConflictModel>()
            ).map(\.serviceID)
        )

        return try pendingOperations(in: context).filter { operation in
            switch operation {
            case .delete:
                true
            case .upsert:
                !conflictedServiceIDs.contains(operation.serviceID)
            }
        }
    }

    /// Returns only deliverable upserts that are not blocked by conflicts.
    func deliverablePendingUpserts(
        in context: ModelContext
    ) throws -> [ServicePendingUpsert] {
        try deliverablePendingOperations(in: context).compactMap { operation in
            guard case .upsert(let upsert) = operation else { return nil }
            return upsert
        }
    }

    /// Returns the durable Services feed position, or nil before the first bootstrap.
    func cursor(in context: ModelContext) throws -> ServiceSyncCursor? {
        try cursorModel(in: context).map { model in
            guard model.changeSequence >= 0 else {
                throw ServiceSyncPersistenceError.invalidCursor
            }
            return ServiceSyncCursor(
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
                context.insert(ServiceSyncRetryModel(state))
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
        _ batch: ServiceRemoteChangeBatch,
        policy: ServiceSyncPolicy,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)

        do {
            let currentCursor = try cursor(in: context)
            guard batch.nextCursor.changeSequence >= 0,
                  batch.nextCursor.changeSequence
                    >= (currentCursor?.changeSequence ?? 0) else {
                throw ServiceSyncPersistenceError.invalidCursor
            }
            for record in batch.records {
                if let sequence = record.changeSequence {
                    guard sequence > 0,
                          sequence <= batch.nextCursor.changeSequence else {
                        throw ServiceSyncPersistenceError.invalidCursor
                    }
                } else if currentCursor != nil {
                    throw ServiceSyncPersistenceError.invalidCursor
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
                throw ServiceSyncPersistenceError.invalidCursor
            }

            let orderedRecords = batch.records.sorted { left, right in
                let leftKey = (left.changeSequence ?? 0, left.id)
                let rightKey = (right.changeSequence ?? 0, right.id)
                return leftKey < rightKey
            }
            for record in orderedRecords {
                let serviceID = ServiceID(rawValue: try record.stableServiceID())
                if try isStale(record, for: serviceID, in: context) {
                    continue
                }
                let operation = try pendingOperations(
                    for: serviceID,
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
                    guard case .upsert(let upsert) = operation else {
                        throw ServiceSyncPersistenceError.entityIdentityMismatch
                    }
                    try applyConflict(
                        operation: upsert,
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
        record: ServiceRemoteRecord,
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
        _ record: ServiceRemoteRecord,
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

    /// Preserves the local upsert and complete remote state for explicit resolution.
    func recordConflict(
        operation: ServicePendingUpsert,
        reason: ServiceSyncConflictReason,
        remoteRecord: ServiceRemoteRecord?,
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

    /// Deletes a service by stable identity without creating synchronized work.
    func delete(_ id: ServiceID, in context: ModelContext) throws {
        guard let model = try model(for: id, in: context) else { return }
        context.delete(model)
        try saveChanges(in: context)
    }

    private func applyAcknowledgement(
        operation: ServicePendingOperation,
        record: ServiceRemoteRecord,
        in context: ModelContext
    ) throws {
        guard try record.stableServiceID() == operation.serviceID else {
            throw ServiceSyncPersistenceError.entityIdentityMismatch
        }
        switch operation {
        case .upsert(let upsert):
            guard record.lastOperationID == upsert.operationID,
                  record.liveService == upsert.service else {
                throw ServiceSyncPersistenceError.entityIdentityMismatch
            }
        case .delete:
            guard record.isTombstone else {
                throw ServiceSyncPersistenceError.entityIdentityMismatch
            }
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
                for: ServiceID(rawValue: upsert.serviceID),
                in: context
            ).contains { $0.operationID != upsert.operationID }
            if !descendantsRemain,
               try conflict(
                for: ServiceID(rawValue: upsert.serviceID),
                in: context
               ) == nil,
               let service = record.liveService {
                try materialize(try service.toDomain(), in: context)
            }
        case .delete(let delete):
            try removePendingChain(
                for: ServiceID(rawValue: delete.serviceID),
                in: context
            )
            if let conflict = try conflict(
                for: ServiceID(rawValue: delete.serviceID),
                in: context
            ) {
                context.delete(conflict)
            }
            if let model = try model(
                for: ServiceID(rawValue: delete.serviceID),
                in: context
            ) {
                context.delete(model)
            }
        }
    }

    private func applyRemoteObservation(
        _ record: ServiceRemoteRecord,
        in context: ModelContext
    ) throws {
        let serviceID = ServiceID(rawValue: try record.stableServiceID())
        try persistRemoteState(record, in: context)
        let hasPending = try !pendingOperations(
            for: serviceID,
            in: context
        ).isEmpty
        let hasConflict = try conflict(for: serviceID, in: context) != nil

        switch record.content {
        case .live(let service):
            if !hasPending, !hasConflict {
                try materialize(try service.toDomain(), in: context)
            }
        case .tombstone:
            if let model = try model(for: serviceID, in: context) {
                context.delete(model)
            }
        }
    }

    private func applyConflict(
        operation: ServicePendingUpsert,
        reason: ServiceSyncConflictReason,
        remoteRecord: ServiceRemoteRecord?,
        in context: ModelContext
    ) throws {
        if let remoteRecord,
           try remoteRecord.stableServiceID() != operation.serviceID {
            throw ServiceSyncPersistenceError.entityIdentityMismatch
        }
        let serviceID = ServiceID(rawValue: operation.serviceID)
        if let model = try conflict(for: serviceID, in: context) {
            try model.update(
                operation: operation,
                reason: reason,
                remoteRecord: remoteRecord
            )
        } else {
            context.insert(
                try ServiceSyncConflictModel(
                    operation: operation,
                    reason: reason,
                    remoteRecord: remoteRecord
                )
            )
        }
        if let remoteRecord {
            try persistRemoteState(remoteRecord, in: context)
            if remoteRecord.isTombstone,
               let localModel = try model(for: serviceID, in: context) {
                context.delete(localModel)
            }
        }
    }

    private func isStale(
        _ record: ServiceRemoteRecord,
        for id: ServiceID,
        in context: ModelContext
    ) throws -> Bool {
        guard let current = try remoteState(for: id, in: context)?.decodeRecord() else {
            return false
        }
        switch (current.changeSequence, record.changeSequence) {
        case (.some(let currentSequence), .some(let incomingSequence)):
            if incomingSequence < currentSequence { return true }
            if incomingSequence == currentSequence, current != record {
                throw ServiceSyncPersistenceError.invalidCursor
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

    private func advanceCursor(
        _ cursor: ServiceSyncCursor,
        in context: ModelContext
    ) throws {
        if let model = try cursorModel(in: context) {
            model.advance(to: cursor.changeSequence)
        } else {
            context.insert(
                ServiceSyncCursorModel(
                    feedID: serviceSyncFeedID,
                    changeSequence: cursor.changeSequence
                )
            )
        }
    }

    private func cursorModel(
        in context: ModelContext
    ) throws -> ServiceSyncCursorModel? {
        var descriptor = FetchDescriptor<ServiceSyncCursorModel>(
            predicate: #Predicate { model in
                model.feedID == serviceSyncFeedID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func retryModel(
        for scope: SyncRetryScope,
        in context: ModelContext
    ) throws -> ServiceSyncRetryModel? {
        let scopeID = scope.storageID
        var descriptor = FetchDescriptor<ServiceSyncRetryModel>(
            predicate: #Predicate { model in
                model.scopeID == scopeID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func deleteRetryState(
        for scope: SyncRetryScope,
        in context: ModelContext
    ) throws {
        if let model = try retryModel(for: scope, in: context) {
            context.delete(model)
        }
    }

    private func requireClean(_ context: ModelContext) throws {
        guard !context.hasChanges else {
            throw ServiceLocalDataSourceError.contextHasUncommittedChanges
        }
    }

    private func model(
        for id: ServiceID,
        in context: ModelContext
    ) throws -> ServiceModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ServiceModel>(
            predicate: #Predicate { model in model.id == rawIdentifier }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingOperations(
        for id: ServiceID,
        in context: ModelContext
    ) throws -> [ServicePendingOperation] {
        try pendingOperations(in: context).filter {
            $0.serviceID == id.rawValue
        }
    }

    private func pendingUpsertModels(
        for id: ServiceID,
        in context: ModelContext
    ) throws -> [ServicePendingUpsertModel] {
        let rawIdentifier = id.rawValue
        return try context.fetch(
            FetchDescriptor<ServicePendingUpsertModel>(
                predicate: #Predicate { model in
                    model.serviceID == rawIdentifier
                }
            )
        )
    }

    private func pendingDeleteModels(
        for id: ServiceID,
        in context: ModelContext
    ) throws -> [ServicePendingDeleteModel] {
        let rawIdentifier = id.rawValue
        return try context.fetch(
            FetchDescriptor<ServicePendingDeleteModel>(
                predicate: #Predicate { model in
                    model.serviceID == rawIdentifier
                }
            )
        )
    }

    private func pendingUpsertModel(
        operationID: UUID,
        in context: ModelContext
    ) throws -> ServicePendingUpsertModel? {
        var descriptor = FetchDescriptor<ServicePendingUpsertModel>(
            predicate: #Predicate { model in
                model.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingDeleteModel(
        operationID: UUID,
        in context: ModelContext
    ) throws -> ServicePendingDeleteModel? {
        var descriptor = FetchDescriptor<ServicePendingDeleteModel>(
            predicate: #Predicate { model in
                model.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func requirePendingOperation(
        operationID: UUID,
        in context: ModelContext
    ) throws -> ServicePendingOperation {
        if let model = try pendingUpsertModel(
            operationID: operationID,
            in: context
        ) {
            return .upsert(
                ServicePendingUpsert(
                    serviceID: model.serviceID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase(),
                    service: try model.decodePayload()
                )
            )
        }
        if let model = try pendingDeleteModel(
            operationID: operationID,
            in: context
        ) {
            return .delete(
                ServicePendingDelete(
                    serviceID: model.serviceID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase()
                )
            )
        }
        throw ServiceSyncPersistenceError.entityIdentityMismatch
    }

    private func ensureOperationIdentityAvailable(
        _ operationID: UUID,
        in context: ModelContext
    ) throws {
        guard try pendingUpsertModel(
            operationID: operationID,
            in: context
        ) == nil,
        try pendingDeleteModel(
            operationID: operationID,
            in: context
        ) == nil else {
            throw ServiceSyncPersistenceError.duplicateOperationIdentity(
                operationID
            )
        }
    }

    private func pendingHead(
        from operations: [ServicePendingOperation],
        serviceID: ServiceID
    ) throws -> ServicePendingOperation? {
        let predecessorIDs = Set(
            operations.compactMap(\.predecessorOperationID)
        )
        let heads = operations.filter {
            !predecessorIDs.contains($0.operationID)
        }
        guard heads.count <= 1 else {
            throw ServiceSyncPersistenceError.ambiguousPendingLineage(serviceID)
        }
        return heads.first
    }

    private func remoteState(
        for id: ServiceID,
        in context: ModelContext
    ) throws -> ServiceRemoteStateModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ServiceRemoteStateModel>(
            predicate: #Predicate { state in
                state.serviceID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func remoteBase(
        for id: ServiceID,
        in context: ModelContext
    ) throws -> ServiceRemoteBase {
        guard let record = try remoteState(for: id, in: context)?.decodeRecord() else {
            return .absent
        }
        switch (record.version, record.content) {
        case (.legacy, .live(let service)):
            return .legacy(service)
        case (.versioned(let revision, _), .live):
            return .versioned(revision)
        case (.versioned(let revision, _), .tombstone):
            return .tombstone(revision)
        case (.legacy, .tombstone):
            throw ServiceSyncPersistenceError.entityIdentityMismatch
        }
    }

    private func hasDeletionState(
        for id: ServiceID,
        in context: ModelContext
    ) throws -> Bool {
        if try !pendingDeleteModels(for: id, in: context).isEmpty {
            return true
        }
        return try remoteState(for: id, in: context)?.decodeRecord().isTombstone
            == true
    }

    private func persistRemoteState(
        _ record: ServiceRemoteRecord,
        in context: ModelContext
    ) throws {
        let serviceID = ServiceID(rawValue: try record.stableServiceID())
        if let state = try remoteState(for: serviceID, in: context) {
            try state.update(record: record)
        } else {
            context.insert(try ServiceRemoteStateModel(record: record))
        }
    }

    private func conflict(
        for id: ServiceID,
        in context: ModelContext
    ) throws -> ServiceSyncConflictModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ServiceSyncConflictModel>(
            predicate: #Predicate { conflict in
                conflict.serviceID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func removePendingChain(
        for id: ServiceID,
        in context: ModelContext
    ) throws {
        for model in try pendingUpsertModels(for: id, in: context) {
            context.delete(model)
        }
        for model in try pendingDeleteModels(for: id, in: context) {
            context.delete(model)
        }
    }

    private func causallySorted(
        _ operations: [ServicePendingOperation]
    ) throws -> [ServicePendingOperation] {
        var remaining: [UUID: ServicePendingOperation] = [:]
        for operation in operations {
            guard remaining[operation.operationID] == nil else {
                throw ServiceSyncPersistenceError.duplicateOperationIdentity(
                    operation.operationID
                )
            }
            remaining[operation.operationID] = operation
        }
        var sorted: [ServicePendingOperation] = []

        while !remaining.isEmpty {
            let ready = remaining.values.filter { operation in
                guard let predecessor = operation.predecessorOperationID else {
                    return true
                }
                return remaining[predecessor] == nil
            }.sorted { left, right in
                let leftKey = "\(left.serviceID.uuidString)/\(left.operationID.uuidString)"
                let rightKey = "\(right.serviceID.uuidString)/\(right.operationID.uuidString)"
                return leftKey < rightKey
            }

            guard !ready.isEmpty else {
                guard let remainingOperation = remaining.values.first else {
                    return sorted
                }
                throw ServiceSyncPersistenceError.cyclicPendingLineage(
                    ServiceID(rawValue: remainingOperation.serviceID)
                )
            }
            for operation in ready {
                sorted.append(operation)
                remaining.removeValue(forKey: operation.operationID)
            }
        }
        return sorted
    }

    private func materialize(
        _ service: Service,
        in context: ModelContext
    ) throws {
        if let model = try model(for: service.id, in: context) {
            try model.update(from: service)
        } else {
            context.insert(try ServiceModel(service))
        }
    }

    private func saveChanges(in context: ModelContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}

/// Failures that protect the boundary of a caller-owned Services context.
enum ServiceLocalDataSourceError: Error, Equatable {
    case contextHasUncommittedChanges
    case syncConflictPending(ServiceID)
    case restoreRequiresExplicitResolution(ServiceID)
}

private extension ServiceRemoteRecord {
    var lastOperationID: UUID? {
        guard case .versioned(_, let lastOperationID) = version else {
            return nil
        }
        return lastOperationID
    }
}
