import Foundation
import Observation

/// Coordinates local product snapshots, search and independent form sessions.
@Observable
@MainActor
final class ProductListViewModel {
    enum State: Equatable {
        case idle
        case loading
        case empty
        case content([Product])
        case failed
    }

    private(set) var state: State = .idle
    var query = ""
    private(set) var formDestination: ProductFormDestination?

    private let observeProducts: ObserveProductsUseCase
    private let searchProducts = SearchProductsUseCase()
    private let makeID: @MainActor () -> UUID
    @ObservationIgnored private var observationGeneration = UUID()

    init(
        observeProducts: ObserveProductsUseCase,
        makeID: @escaping @MainActor () -> UUID = { UUID() }
    ) {
        self.observeProducts = observeProducts
        self.makeID = makeID
    }

    /// Searches the current snapshot without hiding inactive products or mutating the source.
    var visibleProducts: [Product] {
        guard case .content(let products) = state else { return [] }
        return searchProducts(products, query: query)
    }

    /// Distinguishes an unmatched query from an empty local collection.
    var hasNoSearchResults: Bool {
        guard case .content(let products) = state, !products.isEmpty else { return false }
        return visibleProducts.isEmpty
    }

    /// Allocates the session and product identities once until the form is dismissed.
    func beginCreatingProduct() {
        guard formDestination == nil else { return }
        formDestination = ProductFormDestination(id: makeID(), productID: ProductID(rawValue: makeID()), mode: .create)
    }

    /// Opens only identities included in the currently visible search results.
    func beginEditingProduct(_ id: ProductID) {
        guard formDestination == nil, visibleProducts.contains(where: { $0.id == id }) else { return }
        formDestination = ProductFormDestination(id: makeID(), productID: id, mode: .edit)
    }

    /// Ignores a delayed completion or dismissal from a previously presented form.
    func finishFormSession(_ sessionID: UUID) {
        guard formDestination?.id == sessionID else { return }
        formDestination = nil
    }

    /// Observes local snapshots for the lifetime of the caller's task.
    ///
    /// An observation that ends without values becomes `empty`. Cancellation returns to `idle`,
    /// while other errors become `failed`. Replaced observations cannot publish into a newer load.
    func load() async {
        let generation = UUID()
        observationGeneration = generation
        state = .loading

        do {
            try Task.checkCancellation()
            let stream = await observeProducts()
            guard observationGeneration == generation else { return }
            var receivedSnapshot = false

            for try await products in stream {
                try Task.checkCancellation()
                guard observationGeneration == generation else { return }
                receivedSnapshot = true
                state = products.isEmpty ? .empty : .content(products)
            }

            try Task.checkCancellation()
            guard observationGeneration == generation else { return }
            if !receivedSnapshot {
                state = .empty
            }
        } catch is CancellationError {
            guard observationGeneration == generation else { return }
            state = .idle
        } catch {
            guard observationGeneration == generation else { return }
            state = Task.isCancelled ? .idle : .failed
        }
    }
}
