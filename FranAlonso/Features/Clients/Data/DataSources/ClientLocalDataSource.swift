import Foundation
import SwiftData

/// Performs context-confined Clients persistence without retaining live SwiftData state.
struct ClientLocalDataSource {}

extension ClientLocalDataSource {
    /// Fetches and maps the locally persisted client snapshot.
    ///
    /// - Parameter context: The caller-owned context used for this operation only.
    /// - Returns: Domain clients ordered by display name.
    /// - Throws: A SwiftData fetch error or a mapping error for invalid persisted data.
    func fetchAll(in context: ModelContext) throws -> [Client] {
        let descriptor = FetchDescriptor<ClientModel>(
            sortBy: [SortDescriptor(\ClientModel.displayName)]
        )

        return try context.fetch(descriptor).map { try $0.toDomain() }
    }

    /// Materializes a client without creating a pending local mutation.
    ///
    /// This route supports preview seeding and reconciled remote materialization. User
    /// mutations use `persistPendingUpsert(_:operationID:in:)` instead.
    func upsert(_ client: Client, in context: ModelContext) throws {
        try materialize(client, in: context)
        try saveChanges(in: context)
    }

    /// Commits a client and an immutable causal upsert in the same save boundary.
    ///
    /// An identical head snapshot keeps its operation. A changed snapshot appends a new
    /// operation whose predecessor is the previous head, so acknowledgements cannot mutate
    /// or delete a newer edit. A conflict blocks only this client until explicit resolution.
    ///
    /// - Parameters:
    ///   - client: The validated Domain snapshot to persist.
    ///   - operationID: The identifier assigned only when the pending payload changes.
    ///   - context: The caller-owned context used for this operation only.
    /// - Throws: A typed boundary, lineage, mapping, encoding, fetch or save error.
    func persistPendingUpsert(
        _ client: Client,
        operationID: UUID,
        in context: ModelContext
    ) throws {
        guard !context.hasChanges else {
            throw ClientLocalDataSourceError.contextHasUncommittedChanges
        }

        do {
            guard try conflict(for: client.id, in: context) == nil else {
                throw ClientLocalDataSourceError.syncConflictPending(client.id)
            }

            let payload = ClientDTO(client)
            let pendingModels = try pendingUpsertModels(
                for: client.id,
                in: context
            )
            let head = try pendingHead(
                from: pendingModels,
                clientID: client.id
            )

            if try head?.decodePayload() != payload {
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

    /// Returns every immutable pending operation in deterministic causal order.
    ///
    /// - Parameter context: The caller-owned context used for this operation only.
    /// - Returns: Roots before successors, with stable ordering across independent chains.
    /// - Throws: A decoding, fetch or cyclic-lineage error.
    func pendingUpserts(in context: ModelContext) throws -> [ClientPendingUpsert] {
        let models = try context.fetch(
            FetchDescriptor<ClientPendingUpsertModel>()
        )
        let operations = try models.map { model in
            ClientPendingUpsert(
                clientID: model.clientID,
                operationID: model.operationID,
                predecessorOperationID: model.predecessorOperationID,
                base: try model.decodeBase(),
                client: try model.decodePayload()
            )
        }

        return try causallySorted(operations)
    }

    /// Returns pending operations whose client is not blocked by a persisted conflict.
    ///
    /// Conflict rows retain their operation for explicit resolution while independent client
    /// chains remain eligible for delivery.
    func deliverablePendingUpserts(
        in context: ModelContext
    ) throws -> [ClientPendingUpsert] {
        let conflictedClientIDs = Set(
            try context.fetch(
                FetchDescriptor<ClientSyncConflictModel>()
            ).map(\.clientID)
        )

        return try pendingUpserts(in: context).filter { operation in
            !conflictedClientIDs.contains(operation.clientID)
        }
    }

    /// Persists a remote acknowledgement without overwriting a newer local descendant.
    ///
    /// The exact acknowledged row is removed by operation identity. The remote snapshot is
    /// materialized only when no pending local operation or conflict remains for the client.
    func acknowledge(
        operationID: UUID,
        record: ClientRemoteRecord,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        let clientID = ClientID(rawValue: try record.client.stableUUID())
        let remoteClient = try record.client.toDomain()
        guard record.lastOperationID == operationID else {
            throw ClientSyncPersistenceError.entityIdentityMismatch
        }

        do {
            let acknowledgedModel = try pendingUpsertModel(
                operationID: operationID,
                in: context
            )
            if let acknowledgedModel,
               acknowledgedModel.clientID != clientID.rawValue {
                throw ClientSyncPersistenceError.entityIdentityMismatch
            }
            let descendantsRemain = try pendingUpsertModels(
                for: clientID,
                in: context
            ).contains { $0.operationID != operationID }

            try persistRemoteState(record, in: context)
            if let acknowledgedModel {
                context.delete(acknowledgedModel)
            }
            if !descendantsRemain,
               try conflict(for: clientID, in: context) == nil {
                try materialize(remoteClient, in: context)
            }

            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Records an authoritative remote observation without discarding pending local work.
    func recordRemoteObservation(
        _ record: ClientRemoteRecord,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        let clientID = ClientID(rawValue: try record.client.stableUUID())
        let remoteClient = try record.client.toDomain()

        do {
            try persistRemoteState(record, in: context)
            let hasPending = try !pendingUpsertModels(
                for: clientID,
                in: context
            ).isEmpty
            if !hasPending,
               try conflict(for: clientID, in: context) == nil {
                try materialize(remoteClient, in: context)
            }
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Preserves the local operation and complete remote state for explicit resolution.
    func recordConflict(
        operation: ClientPendingUpsert,
        reason: ClientSyncConflictReason,
        remoteRecord: ClientRemoteRecord?,
        in context: ModelContext
    ) throws {
        try requireClean(context)
        if let remoteRecord,
           try remoteRecord.client.stableUUID() != operation.clientID {
            throw ClientSyncPersistenceError.entityIdentityMismatch
        }

        do {
            let clientID = ClientID(rawValue: operation.clientID)
            if let model = try conflict(for: clientID, in: context) {
                try model.update(
                    operation: operation,
                    reason: reason,
                    remoteRecord: remoteRecord
                )
            } else {
                context.insert(
                    try ClientSyncConflictModel(
                        operation: operation,
                        reason: reason,
                        remoteRecord: remoteRecord
                    )
                )
            }
            if let remoteRecord {
                try persistRemoteState(remoteRecord, in: context)
            }
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Deletes a client by stable identity and treats an already-absent client as success.
    func delete(_ id: ClientID, in context: ModelContext) throws {
        guard let model = try model(for: id, in: context) else {
            return
        }

        context.delete(model)
        try saveChanges(in: context)
    }

    private func requireClean(_ context: ModelContext) throws {
        guard !context.hasChanges else {
            throw ClientLocalDataSourceError.contextHasUncommittedChanges
        }
    }

    private func model(
        for id: ClientID,
        in context: ModelContext
    ) throws -> ClientModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ClientModel>(
            predicate: #Predicate { model in
                model.id == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingUpsertModels(
        for id: ClientID,
        in context: ModelContext
    ) throws -> [ClientPendingUpsertModel] {
        let rawIdentifier = id.rawValue
        let descriptor = FetchDescriptor<ClientPendingUpsertModel>(
            predicate: #Predicate { operation in
                operation.clientID == rawIdentifier
            }
        )
        return try context.fetch(descriptor)
    }

    private func pendingUpsertModel(
        operationID: UUID,
        in context: ModelContext
    ) throws -> ClientPendingUpsertModel? {
        var descriptor = FetchDescriptor<ClientPendingUpsertModel>(
            predicate: #Predicate { operation in
                operation.operationID == operationID
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func pendingHead(
        from models: [ClientPendingUpsertModel],
        clientID: ClientID
    ) throws -> ClientPendingUpsertModel? {
        let predecessorIDs = Set(models.compactMap(\.predecessorOperationID))
        let heads = models.filter { !predecessorIDs.contains($0.operationID) }
        guard heads.count <= 1 else {
            throw ClientSyncPersistenceError.ambiguousPendingLineage(clientID)
        }
        return heads.first
    }

    private func remoteState(
        for id: ClientID,
        in context: ModelContext
    ) throws -> ClientRemoteStateModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ClientRemoteStateModel>(
            predicate: #Predicate { state in
                state.clientID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func remoteBase(
        for id: ClientID,
        in context: ModelContext
    ) throws -> ClientRemoteBase {
        guard let record = try remoteState(for: id, in: context)?.decodeRecord() else {
            return .absent
        }
        switch record.version {
        case .legacy:
            return .legacy(record.client)
        case .versioned(let revision, _):
            return .versioned(revision)
        }
    }

    private func persistRemoteState(
        _ record: ClientRemoteRecord,
        in context: ModelContext
    ) throws {
        let clientID = ClientID(rawValue: try record.client.stableUUID())
        if let state = try remoteState(for: clientID, in: context) {
            try state.update(record: record)
        } else {
            context.insert(try ClientRemoteStateModel(record: record))
        }
    }

    private func conflict(
        for id: ClientID,
        in context: ModelContext
    ) throws -> ClientSyncConflictModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ClientSyncConflictModel>(
            predicate: #Predicate { conflict in
                conflict.clientID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
    }

    private func causallySorted(
        _ operations: [ClientPendingUpsert]
    ) throws -> [ClientPendingUpsert] {
        var remaining = Dictionary(
            uniqueKeysWithValues: operations.map { ($0.operationID, $0) }
        )
        var sorted: [ClientPendingUpsert] = []

        while !remaining.isEmpty {
            let ready = remaining.values.filter { operation in
                guard let predecessor = operation.predecessorOperationID else {
                    return true
                }
                return remaining[predecessor] == nil
            }.sorted { left, right in
                let leftKey = "\(left.clientID.uuidString)/\(left.operationID.uuidString)"
                let rightKey = "\(right.clientID.uuidString)/\(right.operationID.uuidString)"
                return leftKey < rightKey
            }

            guard !ready.isEmpty else {
                guard let remainingOperation = remaining.values.first else {
                    return sorted
                }
                let clientID = ClientID(rawValue: remainingOperation.clientID)
                throw ClientSyncPersistenceError.cyclicPendingLineage(clientID)
            }

            for operation in ready {
                sorted.append(operation)
                remaining.removeValue(forKey: operation.operationID)
            }
        }

        return sorted
    }

    private func materialize(
        _ client: Client,
        in context: ModelContext
    ) throws {
        if let model = try model(for: client.id, in: context) {
            model.update(from: client)
        } else {
            context.insert(ClientModel(client))
        }
    }

    private func saveChanges(in context: ModelContext) throws {
        guard context.hasChanges else {
            return
        }

        try context.save()
    }
}

/// Failures that protect the boundary of a caller-owned Clients context.
enum ClientLocalDataSourceError: Error, Equatable {
    /// The caller must resolve its existing changes before starting an atomic operation.
    case contextHasUncommittedChanges

    /// Explicit conflict resolution must complete before this client can be edited again.
    case syncConflictPending(ClientID)
}

private extension ClientRemoteRecord {
    var lastOperationID: UUID? {
        guard case .versioned(_, let lastOperationID) = version else {
            return nil
        }
        return lastOperationID
    }
}
