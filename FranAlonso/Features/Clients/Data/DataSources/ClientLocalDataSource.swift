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
    /// This route supports preview seeding and later reconciled remote materialization. User
    /// mutations use `persistPendingUpsert(_:operationID:in:)` instead.
    /// - Parameters:
    ///   - client: The Domain value to persist.
    ///   - context: The caller-owned context used for this operation only.
    /// - Throws: A SwiftData fetch or save error.
    func upsert(_ client: Client, in context: ModelContext) throws {
        try materialize(client, in: context)
        try saveChanges(in: context)
    }

    /// Commits a client and one idempotent pending upsert in the same save boundary.
    ///
    /// An identical snapshot keeps its existing retry pair. A semantically changed snapshot
    /// replaces the operation identifier and payload while retaining one row for the client.
    /// The complete observable snapshot is validated before saving; any failure rolls back
    /// the attempted client and pending-operation changes.
    ///
    /// - Parameters:
    ///   - client: The validated Domain snapshot to persist.
    ///   - operationID: The identifier assigned only when the pending payload changes.
    ///   - context: The caller-owned context used for this operation only.
    /// - Throws: `ClientLocalDataSourceError.contextHasUncommittedChanges` when the
    ///   caller's context is already dirty, or a mapping, encoding, fetch or save error.
    func persistPendingUpsert(
        _ client: Client,
        operationID: UUID,
        in context: ModelContext
    ) throws {
        guard !context.hasChanges else {
            throw ClientLocalDataSourceError.contextHasUncommittedChanges
        }

        do {
            let payload = ClientDTO(client)

            if let pendingUpsert = try pendingUpsert(
                for: client.id,
                in: context
            ) {
                if try pendingUpsert.decodePayload() != payload {
                    try pendingUpsert.replaceRetryPair(
                        operationID: operationID,
                        payload: payload
                    )
                }
            } else {
                context.insert(
                    try ClientPendingUpsertModel(
                        clientID: client.id.rawValue,
                        operationID: operationID,
                        payload: payload
                    )
                )
            }

            try materialize(client, in: context)
            // Prevent a mapping failure from surfacing after this write is already durable.
            _ = try fetchAll(in: context)
            try saveChanges(in: context)
        } catch {
            context.rollback()
            throw error
        }
    }

    /// Deletes a client by stable identity and treats an already-absent client as success.
    ///
    /// - Parameters:
    ///   - id: The Domain identifier to remove.
    ///   - context: The caller-owned context used for this operation only.
    /// - Throws: A SwiftData fetch or save error.
    func delete(_ id: ClientID, in context: ModelContext) throws {
        guard let model = try model(for: id, in: context) else {
            return
        }

        context.delete(model)
        try saveChanges(in: context)
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

    private func pendingUpsert(
        for id: ClientID,
        in context: ModelContext
    ) throws -> ClientPendingUpsertModel? {
        let rawIdentifier = id.rawValue
        var descriptor = FetchDescriptor<ClientPendingUpsertModel>(
            predicate: #Predicate { operation in
                operation.clientID == rawIdentifier
            }
        )
        descriptor.fetchLimit = 1
        return try context.fetch(descriptor).first
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
    /// The caller must resolve its existing changes before starting an atomic upsert.
    case contextHasUncommittedChanges
}
