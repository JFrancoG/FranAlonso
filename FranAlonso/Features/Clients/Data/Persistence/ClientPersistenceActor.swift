import SwiftData

/// Serializes Clients persistence on a SwiftData-owned model context.
///
/// Callers cross the actor boundary only with detached Domain snapshots or stable
/// Domain identifiers. Live persistent models and the actor's context remain isolated.
@ModelActor
actor ClientPersistenceActor {
    private let dataSource = ClientLocalDataSource()

    /// Fetches the current client snapshot ordered by display name.
    ///
    /// - Returns: Domain values detached from this actor's persistent context.
    /// - Throws: A SwiftData fetch error or a mapping error for invalid persisted data.
    func fetchAll() throws -> [Client] {
        try dataSource.fetchAll(in: modelContext)
    }

    /// Inserts or replaces a client by stable identity and saves the actor's context.
    ///
    /// - Parameter client: The detached Domain value to persist.
    /// - Throws: A SwiftData fetch or save error.
    func upsert(_ client: Client) throws {
        try dataSource.upsert(client, in: modelContext)
    }

    /// Deletes a client by stable identity and treats an absent client as success.
    ///
    /// - Parameter id: The Domain identifier to remove.
    /// - Throws: A SwiftData fetch or save error.
    func delete(_ id: ClientID) throws {
        try dataSource.delete(id, in: modelContext)
    }
}
