import Foundation

/// Searches supplied local service snapshots without persistence or network access.
struct SearchServicesUseCase {
    /// Matches names irrespective of case or diacritics, preserving order, types and inactive entries.
    /// A whitespace-only query returns the complete supplied collection.
    func callAsFunction(_ services: [Service], query: String) -> [Service] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return services }
        return services.filter { $0.name.localizedStandardContains(search) }
    }
}
