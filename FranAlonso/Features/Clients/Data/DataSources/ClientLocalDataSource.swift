import Foundation
import SwiftData

private let clientSyncFeedID = "clients"

/// Performs context-confined Clients persistence without retaining live SwiftData state.
struct ClientLocalDataSource {}

extension ClientLocalDataSource {
    /// Fetches visible local profiles, excluding retained history marked by a tombstone.
    func fetchAll(in context: ModelContext) throws -> [Client] {
        let deletedIDs = try deletedClientIDs(in: context)
        let descriptor = FetchDescriptor<ClientModel>(sortBy: [SortDescriptor(\ClientModel.displayName)])
        return try context.fetch(descriptor).filter { !deletedIDs.contains($0.id) }.map { try $0.toDomain() }
    }

    /// Reads only visible profiles; retained deactivated history remains outside CRUD lookup.
    func client(id: ClientID, in context: ModelContext) throws -> Client? {
        try performClientOperation {
            guard try !hasDeletionState(for: id, in: context) else { return nil }
            return try model(for: id, in: context)?.toDomain()
        }
    }

    /// Accepts a new draft and its causal operation in one save, without replacing an existing identity.
    func createClient(
        id: ClientID,
        profile: ClientProfile,
        operationID: UUID,
        in context: ModelContext
    ) throws -> Client {
        try performClientOperation {
            try requireClean(context)
            guard try !hasDeletionState(for: id, in: context) else { throw ClientError.alreadyExists }
            guard try model(for: id, in: context) == nil,
                  try pendingOperations(for: id, in: context).isEmpty,
                  try remoteState(for: id, in: context) == nil else {
                throw ClientError.alreadyExists
            }
            let client = Client(
                id: id,
                displayName: profile.displayName,
                taxIdentifier: profile.taxIdentifier,
                billingAddress: profile.billingAddress,
                status: .draft
            )
            try persistPendingUpsert(client, operationID: operationID, in: context)
            return client
        }
    }

    /// Edits fields on the profile in this context, retaining its consent and activation state.
    /// Profile and queue share one save; separate caller contexts are not a compare-and-swap boundary.
    func updateClient(
        id: ClientID,
        profile: ClientProfile,
        operationID: UUID,
        in context: ModelContext
    ) throws -> Client {
        try performClientOperation {
            try requireClean(context)
            guard try !hasDeletionState(for: id, in: context) else { throw ClientError.deactivated }
            guard let existing = try model(for: id, in: context)?.toDomain() else { throw ClientError.notFound }
            let client = Client(
                id: id,
                displayName: profile.displayName,
                taxIdentifier: profile.taxIdentifier,
                billingAddress: profile.billingAddress,
                status: existing.status
            )
            try persistPendingUpsert(client, operationID: operationID, in: context)
            return client
        }
    }

    /// Accepts an idempotent deactivation while distinguishing a never-known identity.
    func deactivateClient(_ id: ClientID, operationID: UUID, in context: ModelContext) throws {
        try performClientOperation {
            try requireClean(context)
            guard try !hasDeletionState(for: id, in: context) else { return }
            guard try model(for: id, in: context) != nil else { throw ClientError.notFound }
            try persistPendingDelete(id, operationID: operationID, in: context)
        }
    }

    /// Materializes a client without creating a pending local mutation.
    func upsert(_ client: Client, in context: ModelContext) throws {
        try materialize(client, in: context)
        try saveChanges(in: context)
    }

    /// Commits a client and an immutable causal upsert in the same save boundary.
    ///
    /// A tombstone or pending deletion blocks ordinary upserts so restoration cannot occur
    /// accidentally. A future explicit restore flow owns that separate state transition.
    func persistPendingUpsert(_ client: Client, operationID: UUID, in context: ModelContext) throws {
        try requireClean(context)

        do {
            guard try conflict(for: client.id, in: context) == nil else {
                throw ClientLocalDataSourceError.syncConflictPending(client.id)
            }
            guard try !hasDeletionState(for: client.id, in: context) else {
                throw ClientLocalDataSourceError.restoreRequiresExplicitResolution(client.id)
            }

            let payload = ClientDTO(client)
            let operations = try pendingOperations(for: client.id, in: context)
            let head = try pendingHead(from: operations, clientID: client.id)
            let headPayload: ClientDTO?
            if case .upsert(let upsert) = head {
                headPayload = upsert.client
            } else {
                headPayload = nil
            }

            if headPayload != payload {
                try ensureOperationIdentityAvailable(operationID, in: context)
                context.insert(
                    try ClientPendingUpsertModel(
                        clientID: client.id.rawValue,
                        operationID: operationID,
                        predecessorOperationID: head?.operationID,
                        base: try remoteBase(for: client.id, in: context),
                        payload: payload
                    )
                )
            }

            try materialize(client, in: context)
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Hides the client and commits a durable tombstone, retaining its last local profile and consent.
    ///
    /// An already deleted client is a no-op only when no live remote state or pending chain
    /// remains. A repeated delete keeps the existing pending operation identity.
    func persistPendingDelete(_ id: ClientID, operationID: UUID, in context: ModelContext) throws {
        try requireClean(context)

        do {
            let operations = try pendingOperations(for: id, in: context)
            if operations.contains(where: { operation in
                if case .delete = operation {
                    return true
                }
                return false
            }) {
                return
            }

            let localModel = try model(for: id, in: context)
            let remoteRecord = try remoteState(for: id, in: context)?.decodeRecord()
            guard remoteRecord?.isTombstone != true else { return }
            guard localModel != nil
                    || !operations.isEmpty
                    || remoteRecord?.isLive == true else {
                return
            }

            try ensureOperationIdentityAvailable(operationID, in: context)
            let head = try pendingHead(from: operations, clientID: id)
            context.insert(
                try ClientPendingDeleteModel(
                    clientID: id.rawValue,
                    operationID: operationID,
                    predecessorOperationID: head?.operationID,
                    base: try remoteBase(for: id, in: context)
                )
            )
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Returns every immutable pending operation in deterministic causal order.
    func pendingOperations(in context: ModelContext) throws -> [ClientPendingOperation] {
        let upserts = try context.fetch(FetchDescriptor<ClientPendingUpsertModel>()).map { model in
            ClientPendingOperation.upsert(
                ClientPendingUpsert(
                    clientID: model.clientID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase(),
                    client: try model.decodePayload()
                )
            )
        }
        let deletes = try context.fetch(FetchDescriptor<ClientPendingDeleteModel>()).map { model in
            ClientPendingOperation.delete(
                ClientPendingDelete(
                    clientID: model.clientID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase()
                )
            )
        }
        return try causallySorted(upserts + deletes)
    }

    /// Preserves the 05.7 upsert inspection boundary for existing callers.
    func pendingUpserts(in context: ModelContext) throws -> [ClientPendingUpsert] {
        try pendingOperations(in: context).compactMap { operation in
            guard case .upsert(let upsert) = operation else { return nil }
            return upsert
        }
    }

    /// Returns operations eligible for delivery while preserving delete-wins semantics.
    func deliverablePendingOperations(in context: ModelContext) throws -> [ClientPendingOperation] {
        let conflictedClientIDs = Set(try context.fetch(FetchDescriptor<ClientSyncConflictModel>()).map(\.clientID))

        return try pendingOperations(in: context).filter { operation in
            switch operation {
            case .delete:
                true
            case .upsert:
                !conflictedClientIDs.contains(operation.clientID)
            }
        }
    }

    /// Preserves the 05.7 deliverable-upsert inspection boundary.
    func deliverablePendingUpserts(in context: ModelContext) throws -> [ClientPendingUpsert] {
        try deliverablePendingOperations(in: context).compactMap { operation in
            guard case .upsert(let upsert) = operation else { return nil }
            return upsert
        }
    }

    /// Returns the durable Clients feed position, or nil before the first bootstrap.
    func cursor(in context: ModelContext) throws -> ClientSyncCursor? {
        try cursorModel(in: context).map { model in
            guard model.changeSequence >= 0 else { throw ClientSyncPersistenceError.invalidCursor }
            return ClientSyncCursor(changeSequence: model.changeSequence)
        }
    }

    /// Returns the validated durable schedule for one retry scope, when present.
    func retryState(for scope: SyncRetryScope, in context: ModelContext) throws -> SyncRetryState? {
        try retryModel(for: scope, in: context)?.decodeState(for: scope)
    }

    /// Inserts or replaces one durable retry schedule and commits it explicitly.
    func saveRetryState(_ state: SyncRetryState, in context: ModelContext) throws {
        try requireClean(context)
        do {
            if let model = try retryModel(for: state.scope, in: context) {
                try model.update(with: state)
            } else {
                context.insert(ClientSyncRetryModel(state))
            }
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Removes a transient backoff without discarding its pending sync operation.
    func clearRetryState(for scope: SyncRetryScope, in context: ModelContext) throws {
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
        _ batch: ClientRemoteChangeBatch,
        policy: ClientSyncPolicy,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)

        do {
            let currentCursor = try cursor(in: context)
            guard batch.nextCursor.changeSequence >= 0,
                  batch.nextCursor.changeSequence
                    >= (currentCursor?.changeSequence ?? 0) else {
                throw ClientSyncPersistenceError.invalidCursor
            }
            for record in batch.records {
                if let sequence = record.changeSequence {
                    guard sequence > 0,
                          sequence <= batch.nextCursor.changeSequence else {
                        throw ClientSyncPersistenceError.invalidCursor
                    }
                } else if currentCursor != nil {
                    throw ClientSyncPersistenceError.invalidCursor
                }
            }
            let receivedMaximum = batch.records
                .compactMap(\.changeSequence)
                .max()
                ?? 0
            let expectedNextSequence = max(currentCursor?.changeSequence ?? 0, receivedMaximum)
            guard batch.nextCursor.changeSequence
                    == expectedNextSequence else {
                throw ClientSyncPersistenceError.invalidCursor
            }

            let orderedRecords = batch.records.sorted { left, right in
                let leftKey = (left.changeSequence ?? 0, left.id)
                let rightKey = (right.changeSequence ?? 0, right.id)
                return leftKey < rightKey
            }
            for record in orderedRecords {
                let clientID = ClientID(rawValue: try record.stableClientID())
                if try isStale(record, for: clientID, in: context) {
                    continue
                }
                let operation = try pendingOperations(for: clientID, in: context).first
                guard let operation else {
                    try applyRemoteObservation(record, in: context)
                    continue
                }

                switch policy.decision(for: operation, against: record) {
                case .apply:
                    try applyRemoteObservation(record, in: context)
                case .alreadyApplied(let acknowledgedRecord):
                    try applyAcknowledgement(operation: operation, record: acknowledgedRecord, in: context)
                    try deleteRetryState(for: .operation(operation.operationID), in: context)
                case .conflict(let reason, let remoteRecord):
                    guard case .upsert(let upsert) = operation else {
                        throw ClientSyncPersistenceError.entityIdentityMismatch
                    }
                    try applyConflict(
                        operation: upsert,
                        reason: reason,
                        remoteRecord: remoteRecord,
                        in: context
                    )
                    try deleteRetryState(for: .operation(operation.operationID), in: context)
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
        record: ClientRemoteRecord,
        clearingRetryFor retryScope: SyncRetryScope? = nil,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        do {
            let operation = try requirePendingOperation(operationID: operationID, in: context)
            try applyAcknowledgement(operation: operation, record: record, in: context)
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
    func recordRemoteObservation(_ record: ClientRemoteRecord, in context: ModelContext) throws {
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
        operation: ClientPendingUpsert,
        reason: ClientSyncConflictReason,
        remoteRecord: ClientRemoteRecord?,
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

    /// Deletes a client by stable identity without creating synchronized work.
    func delete(_ id: ClientID, in context: ModelContext) throws {
        guard let model = try model(for: id, in: context) else { return }
        context.delete(model)
        try saveChanges(in: context)
    }

    private func applyAcknowledgement(
        operation: ClientPendingOperation,
        record: ClientRemoteRecord,
        in context: ModelContext
    ) throws {
        guard try record.stableClientID() == operation.clientID else {
            throw ClientSyncPersistenceError.entityIdentityMismatch
        }
        switch operation {
        case .upsert(let upsert):
            guard record.lastOperationID == upsert.operationID,
                  record.liveClient == upsert.client else {
                throw ClientSyncPersistenceError.entityIdentityMismatch
            }
        case .delete:
            guard record.isTombstone else { throw ClientSyncPersistenceError.entityIdentityMismatch }
        }

        try persistRemoteState(record, in: context)
        switch operation {
        case .upsert(let upsert):
            if let model = try pendingUpsertModel(operationID: upsert.operationID, in: context) {
                context.delete(model)
            }
            let descendantsRemain = try pendingOperations(
                for: ClientID(rawValue: upsert.clientID),
                in: context
            ).contains { $0.operationID != upsert.operationID }
            if !descendantsRemain,
               try conflict(for: ClientID(rawValue: upsert.clientID), in: context) == nil,
               let client = record.liveClient {
                try materialize(try client.toDomain(), in: context)
            }
        case .delete(let delete):
            try removePendingChain(for: ClientID(rawValue: delete.clientID), in: context)
            if let conflict = try conflict(for: ClientID(rawValue: delete.clientID), in: context) {
                context.delete(conflict)
            }
        }
    }

    private func applyRemoteObservation(_ record: ClientRemoteRecord, in context: ModelContext) throws {
        let clientID = ClientID(rawValue: try record.stableClientID())
        try persistRemoteState(record, in: context)
        let hasPending = try !pendingOperations(for: clientID, in: context).isEmpty
        let hasConflict = try conflict(for: clientID, in: context) != nil

        switch record.content {
        case .live(let client):
            if !hasPending, !hasConflict {
                try materialize(try client.toDomain(), in: context)
            }
        case .tombstone:
            break
        }
    }

    private func applyConflict(
        operation: ClientPendingUpsert,
        reason: ClientSyncConflictReason,
        remoteRecord: ClientRemoteRecord?,
        in context: ModelContext
    ) throws {
        if let remoteRecord,
           try remoteRecord.stableClientID() != operation.clientID {
            throw ClientSyncPersistenceError.entityIdentityMismatch
        }
        let clientID = ClientID(rawValue: operation.clientID)
        if let model = try conflict(for: clientID, in: context) {
            try model.update(operation: operation, reason: reason, remoteRecord: remoteRecord)
        } else {
            context.insert(
                try ClientSyncConflictModel(operation: operation, reason: reason, remoteRecord: remoteRecord)
            )
        }
        if let remoteRecord {
            try persistRemoteState(remoteRecord, in: context)
        }
    }

    private func isStale(_ record: ClientRemoteRecord, for id: ClientID, in context: ModelContext) throws -> Bool {
        guard let current = try remoteState(for: id, in: context)?.decodeRecord() else { return false }
        switch (current.changeSequence, record.changeSequence) {
        case (.some(let currentSequence), .some(let incomingSequence)):
            if incomingSequence < currentSequence {
                return true
            }
            if incomingSequence == currentSequence, current != record {
                throw ClientSyncPersistenceError.invalidCursor
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

    private func advanceCursor(_ cursor: ClientSyncCursor, in context: ModelContext) throws {
        if let model = try cursorModel(in: context) {
            model.advance(to: cursor.changeSequence)
        } else {
            context.insert(ClientSyncCursorModel(feedID: clientSyncFeedID, changeSequence: cursor.changeSequence))
        }
    }

    private func cursorModel(in context: ModelContext) throws -> ClientSyncCursorModel? {
        var descriptor = FetchDescriptor<ClientSyncCursorModel>(
            predicate: #Predicate { model in
                model.feedID == clientSyncFeedID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func retryModel(for scope: SyncRetryScope, in context: ModelContext) throws -> ClientSyncRetryModel? {
        let scopeID = scope.storageID
        var descriptor = FetchDescriptor<ClientSyncRetryModel>(
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
        guard !context.hasChanges else { throw ClientLocalDataSourceError.contextHasUncommittedChanges }
    }

    private func performClientOperation<Value>(
        _ operation: () throws -> Value
    ) throws -> Value {
        try Task.checkCancellation()
        do {
            return try operation()
        } catch let error as ClientError {
            throw error
        } catch ClientLocalDataSourceError.syncConflictPending {
            throw ClientError.conflict
        } catch ClientLocalDataSourceError.restoreRequiresExplicitResolution {
            throw ClientError.deactivated
        } catch {
            throw ClientError.persistenceUnavailable
        }
    }

    private func model(for id: ClientID, in context: ModelContext) throws -> ClientModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ClientModel>(
            predicate: #Predicate { model in model.id == rawIdentifier }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingOperations(for id: ClientID, in context: ModelContext) throws -> [ClientPendingOperation] {
        try pendingOperations(in: context).filter {
            $0.clientID == id.rawValue
        }
    }

    private func pendingUpsertModels(for id: ClientID, in context: ModelContext) throws -> [ClientPendingUpsertModel] {
        let rawIdentifier = id.rawValue
        return try context.fetch(
            FetchDescriptor<ClientPendingUpsertModel>(
                predicate: #Predicate { model in
                    model.clientID == rawIdentifier
                }
            )
        )
    }

    private func pendingDeleteModels(for id: ClientID, in context: ModelContext) throws -> [ClientPendingDeleteModel] {
        let rawIdentifier = id.rawValue
        return try context.fetch(
            FetchDescriptor<ClientPendingDeleteModel>(
                predicate: #Predicate { model in
                    model.clientID == rawIdentifier
                }
            )
        )
    }

    private func pendingUpsertModel(operationID: UUID, in context: ModelContext) throws -> ClientPendingUpsertModel? {
        var descriptor = FetchDescriptor<ClientPendingUpsertModel>(
            predicate: #Predicate { model in
                model.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingDeleteModel(operationID: UUID, in context: ModelContext) throws -> ClientPendingDeleteModel? {
        var descriptor = FetchDescriptor<ClientPendingDeleteModel>(
            predicate: #Predicate { model in
                model.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func requirePendingOperation(operationID: UUID, in context: ModelContext) throws -> ClientPendingOperation {
        if let model = try pendingUpsertModel(operationID: operationID, in: context) {
            return .upsert(
                ClientPendingUpsert(
                    clientID: model.clientID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase(),
                    client: try model.decodePayload()
                )
            )
        }
        if let model = try pendingDeleteModel(operationID: operationID, in: context) {
            return .delete(
                ClientPendingDelete(
                    clientID: model.clientID,
                    operationID: model.operationID,
                    predecessorOperationID: model.predecessorOperationID,
                    base: try model.decodeBase()
                )
            )
        }
        throw ClientSyncPersistenceError.entityIdentityMismatch
    }

    private func ensureOperationIdentityAvailable(_ operationID: UUID, in context: ModelContext) throws {
        guard try pendingUpsertModel(operationID: operationID, in: context) == nil,
        try pendingDeleteModel(operationID: operationID, in: context) == nil else {
            throw ClientSyncPersistenceError.duplicateOperationIdentity(operationID)
        }
    }

    private func pendingHead(
        from operations: [ClientPendingOperation],
        clientID: ClientID
    ) throws -> ClientPendingOperation? {
        let predecessorIDs = Set(operations.compactMap(\.predecessorOperationID))
        let heads = operations.filter {
            !predecessorIDs.contains($0.operationID)
        }
        guard heads.count <= 1 else { throw ClientSyncPersistenceError.ambiguousPendingLineage(clientID) }
        return heads.first
    }

    private func remoteState(for id: ClientID, in context: ModelContext) throws -> ClientRemoteStateModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ClientRemoteStateModel>(
            predicate: #Predicate { state in
                state.clientID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func remoteBase(for id: ClientID, in context: ModelContext) throws -> ClientRemoteBase {
        guard let record = try remoteState(for: id, in: context)?.decodeRecord() else { return .absent }
        switch (record.version, record.content) {
        case (.legacy, .live(let client)):
            return .legacy(client)
        case (.versioned(let revision, _), .live):
            return .versioned(revision)
        case (.versioned(let revision, _), .tombstone):
            return .tombstone(revision)
        case (.legacy, .tombstone):
            throw ClientSyncPersistenceError.entityIdentityMismatch
        }
    }

    private func hasDeletionState(for id: ClientID, in context: ModelContext) throws -> Bool {
        if try !pendingDeleteModels(for: id, in: context).isEmpty {
            return true
        }
        return try remoteState(for: id, in: context)?.decodeRecord().isTombstone
            == true
    }

    private func deletedClientIDs(in context: ModelContext) throws -> Set<UUID> {
        var identifiers = Set(try context.fetch(FetchDescriptor<ClientPendingDeleteModel>()).map(\.clientID))
        for state in try context.fetch(FetchDescriptor<ClientRemoteStateModel>()) {
            if try state.decodeRecord().isTombstone {
                identifiers.insert(state.clientID)
            }
        }
        return identifiers
    }

    private func persistRemoteState(_ record: ClientRemoteRecord, in context: ModelContext) throws {
        let clientID = ClientID(rawValue: try record.stableClientID())
        if let state = try remoteState(for: clientID, in: context) {
            try state.update(record: record)
        } else {
            context.insert(try ClientRemoteStateModel(record: record))
        }
    }

    private func conflict(for id: ClientID, in context: ModelContext) throws -> ClientSyncConflictModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ClientSyncConflictModel>(
            predicate: #Predicate { conflict in
                conflict.clientID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func removePendingChain(for id: ClientID, in context: ModelContext) throws {
        for model in try pendingUpsertModels(for: id, in: context) {
            context.delete(model)
        }
        for model in try pendingDeleteModels(for: id, in: context) {
            context.delete(model)
        }
    }

    private func causallySorted(_ operations: [ClientPendingOperation]) throws -> [ClientPendingOperation] {
        var remaining: [UUID: ClientPendingOperation] = [:]
        for operation in operations {
            guard remaining[operation.operationID] == nil else {
                throw ClientSyncPersistenceError.duplicateOperationIdentity(operation.operationID)
            }
            remaining[operation.operationID] = operation
        }
        var sorted: [ClientPendingOperation] = []

        while !remaining.isEmpty {
            let ready = remaining.values.filter { operation in
                guard let predecessor = operation.predecessorOperationID else { return true }
                return remaining[predecessor] == nil
            }.sorted { left, right in
                let leftKey = "\(left.clientID.uuidString)/\(left.operationID.uuidString)"
                let rightKey = "\(right.clientID.uuidString)/\(right.operationID.uuidString)"
                return leftKey < rightKey
            }

            guard !ready.isEmpty else {
                guard let remainingOperation = remaining.values.first else { return sorted }
                throw ClientSyncPersistenceError.cyclicPendingLineage(ClientID(rawValue: remainingOperation.clientID))
            }
            for operation in ready {
                sorted.append(operation)
                remaining.removeValue(forKey: operation.operationID)
            }
        }
        return sorted
    }

    private func materialize(_ client: Client, in context: ModelContext) throws {
        if let model = try model(for: client.id, in: context) {
            model.update(from: client)
        } else {
            context.insert(ClientModel(client))
        }
    }

    private func saveChanges(in context: ModelContext) throws {
        guard context.hasChanges else { return }
        try context.save()
    }
}

/// Failures that protect the boundary of a caller-owned Clients context.
enum ClientLocalDataSourceError: Error, Equatable {
    case contextHasUncommittedChanges
    case syncConflictPending(ClientID)
    case restoreRequiresExplicitResolution(ClientID)
}

private extension ClientRemoteRecord {
    var lastOperationID: UUID? {
        guard case .versioned(_, let lastOperationID) = version else { return nil }
        return lastOperationID
    }
}
