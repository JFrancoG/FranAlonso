import Observation

/// Owns the catalogue route independently of each feature's list and form session.
@Observable
@MainActor
final class CatalogViewModel {
    enum Destination: Hashable {
        case services, products
    }

    var path: [Destination] = []
}
