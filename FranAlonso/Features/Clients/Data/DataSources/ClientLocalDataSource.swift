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

    /// Inserts or replaces a client by stable identity and saves the caller's context explicitly.
    ///
    /// This is the shared local write primitive for later repository, contextual-adapter,
    /// and persistence-actor composition.
    /// - Parameters:
    ///   - client: The Domain value to persist.
    ///   - context: The caller-owned context used for this operation only.
    /// - Throws: A SwiftData fetch or save error.
    func upsert(_ client: Client, in context: ModelContext) throws {
        if let model = try model(for: client.id, in: context) {
            model.update(from: client)
        } else {
            context.insert(ClientModel(client))
        }

        try saveChanges(in: context)
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

    private func saveChanges(in context: ModelContext) throws {
        guard context.hasChanges else {
            return
        }

        try context.save()
    }
}
