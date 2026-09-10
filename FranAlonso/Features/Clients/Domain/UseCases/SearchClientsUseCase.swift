import Foundation

/// Searches a caller's visible local snapshots without accessing persistence or the network.
struct SearchClientsUseCase {
    /// Matches name or tax identifier using a locale-aware, case- and diacritic-insensitive search.
    /// A whitespace-only query returns all supplied clients in their existing order.
    /// The caller supplies the repository's visible snapshots, including editable drafts.
    func callAsFunction(_ clients: [Client], query: String) -> [Client] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return clients }
        return clients.filter {
            $0.displayName.localizedStandardContains(search)
                || $0.taxIdentifier?.localizedStandardContains(search) == true
        }
    }
}
