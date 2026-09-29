import Foundation
import Observation
import SwiftData

/// Coordinates one product form using local, caller-context mutation capabilities.
@Observable
@MainActor
final class ProductFormViewModel {
    typealias SaveOperation = @MainActor (ProductID, ProductProfile, ModelContext) async throws -> Product
    typealias DeactivateOperation = @MainActor (ProductID, ModelContext) async throws -> Void

    enum Operation: Equatable {
        case load
        case save
        case deactivate
    }

    /// Identifies failed operations so an unread existing product cannot become a writable blank form.
    enum State: Equatable {
        case idle
        case loading
        case editing
        case saving
        case deactivating
        case saved(Product)
        case deactivated
        case failed(Operation, ProductError)
        case closed
    }

    let destination: ProductFormDestination
    /// Clears only invalid-name feedback once the user supplies a valid editable name.
    var name = "" {
        didSet {
            guard name != oldValue, state == .failed(.save, .invalidName),
                  (try? prepareProfile(name: name)) != nil else { return }
            state = .editing
        }
    }
    private(set) var loadedProduct: Product?
    private(set) var state: State

    private let getProduct: GetProductUseCase
    private let prepareProfile = PrepareProductProfileUseCase()
    private let create: SaveOperation
    private let update: SaveOperation
    private let deactivateProduct: DeactivateOperation
    @ObservationIgnored private var operationGeneration = UUID()

    /// Receives App-composed capabilities without retaining a persistent context.
    init(
        destination: ProductFormDestination,
        getProduct: GetProductUseCase,
        create: @escaping SaveOperation,
        update: @escaping SaveOperation,
        deactivate: @escaping DeactivateOperation
    ) {
        self.destination = destination
        self.getProduct = getProduct
        self.create = create
        self.update = update
        deactivateProduct = deactivate
        state = destination.mode == .create ? .editing : .idle
    }

    /// Failed mutations permit retry; unread products and terminal sessions never permit writes.
    var canEdit: Bool {
        switch state {
        case .editing, .failed(.save, _), .failed(.deactivate, _): true
        default: false
        }
    }

    var canDeactivate: Bool { destination.mode == .edit && loadedProduct?.status == .active && canEdit }

    /// Loads or retries an existing product without replacing an editable draft.
    /// Absence remains a failed read. Cancelled, replaced or closed loads cannot publish late results.
    func load() async {
        guard destination.mode == .edit else { return }
        switch state {
        case .idle, .loading, .failed(.load, _): break
        default: return
        }
        let generation = UUID()
        operationGeneration = generation
        state = .loading
        do {
            let product = try await getProduct(destination.productID)
            try Task.checkCancellation()
            guard operationGeneration == generation else { return }
            guard let product else {
                state = .failed(.load, .notFound)
                return
            }
            loadedProduct = product
            name = product.name
            state = .editing
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError || Task.isCancelled ? .idle : .failed(.load, productError(error))
        }
    }

    /// Validates a captured name and submits one local write with the caller's ephemeral context.
    /// Success reflects durable local acceptance even if cancellation arrives during that write.
    func save(in context: ModelContext) async {
        guard canEdit, !Task.isCancelled else { return }
        let profile: ProductProfile
        do {
            profile = try prepareProfile(name: name)
        } catch {
            state = .failed(.save, productError(error))
            return
        }
        let generation = UUID()
        operationGeneration = generation
        state = .saving
        do {
            let product: Product
            switch destination.mode {
            case .create:
                product = try await create(destination.productID, profile, context)
            case .edit:
                product = try await update(destination.productID, profile, context)
            }
            guard operationGeneration == generation else { return }
            loadedProduct = product
            state = .saved(product)
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError ? .editing : .failed(.save, productError(error))
        }
    }

    /// Applies an already-confirmed deactivation; completion means local acceptance, not remote convergence.
    /// Inactive products, overlapping requests and terminal sessions cannot submit another mutation.
    func deactivate(in context: ModelContext) async {
        guard canDeactivate, !Task.isCancelled else { return }
        let generation = UUID()
        operationGeneration = generation
        state = .deactivating
        do {
            try await deactivateProduct(destination.productID, context)
            guard operationGeneration == generation else { return }
            state = .deactivated
        } catch {
            guard operationGeneration == generation else { return }
            state = error is CancellationError ? .editing : .failed(.deactivate, productError(error))
        }
    }

    /// Clears presentation and fences later responses without claiming to undo an accepted write.
    func close() {
        operationGeneration = UUID()
        name = ""
        loadedProduct = nil
        state = .closed
    }

    private func productError(_ error: any Error) -> ProductError {
        (error as? ProductError) ?? .persistenceUnavailable
    }
}
