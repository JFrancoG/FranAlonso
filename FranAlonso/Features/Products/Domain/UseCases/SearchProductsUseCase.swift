import Foundation

/// Searches supplied local product snapshots without persistence or network access.
struct SearchProductsUseCase {
    /// Matches names irrespective of case/diacritics, preserving order and inactive entries.
    /// A whitespace-only query returns every supplied product.
    func callAsFunction(_ products: [Product], query: String) -> [Product] {
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !search.isEmpty else { return products }
        return products.filter { $0.name.localizedStandardContains(search) }
    }
}
