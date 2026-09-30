/// Applies sale-picker eligibility and name/type filters to local catalogue snapshots.
struct FilterSelectableServicesUseCase {
    /// Narrows active offerings without changing their commercial values or catalogue order.
    enum Filter {
        case all
        case professional
        case product
    }

    /// Retains active services of the requested type and matches their names case/diacritic-insensitively.
    /// Product linkage and stock availability are separate acceptance policies, not catalogue filters.
    func callAsFunction(_ services: [Service], query: String, filter: Filter) -> [Service] {
        let eligible = services.filter { service in
            guard service.status == .active else { return false }
            switch filter {
            case .all: return true
            case .professional: return service.type == .professional
            case .product: return service.type == .product
            }
        }
        return SearchServicesUseCase()(eligible, query: query)
    }
}
