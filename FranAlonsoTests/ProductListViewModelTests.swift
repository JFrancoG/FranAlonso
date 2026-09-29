import Foundation
import Testing
@testable import FranAlonso

@Suite("Product list view model")
@MainActor
struct ProductListViewModelTests {
    @Test
    func `loading exposes active and inactive products`() async throws {
        let activeID = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000001"))
        let inactiveID = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000002"))
        let products = [
            Product(id: ProductID(rawValue: activeID), name: "Shampoo", status: .active),
            Product(id: ProductID(rawValue: inactiveID), name: "Conditioner", status: .inactive)
        ]
        let repository = InMemoryProductRepository(products: products)
        let model = ProductListViewModel(observeProducts: ObserveProductsUseCase(repository: repository))

        await model.load()

        #expect(model.state == .content(products))
        #expect(model.visibleProducts == products)
    }

    @Test
    func `an empty local collection displays empty state`() async {
        let model = ProductListViewModel(
            observeProducts: ObserveProductsUseCase(repository: InMemoryProductRepository())
        )

        await model.load()

        #expect(model.state == .empty)
        #expect(!model.hasNoSearchResults)
    }

    @Test
    func `observation ending without values displays empty state`() async {
        let model = ProductListViewModel(
            observeProducts: ObserveProductsUseCase(repository: ProductListTerminalRepository(behavior: .finished))
        )

        await model.load()

        #expect(model.state == .empty)
    }

    @Test
    func `observation failure displays failed state`() async {
        let model = ProductListViewModel(
            observeProducts: ObserveProductsUseCase(repository: ProductListTerminalRepository(behavior: .failure))
        )

        await model.load()

        #expect(model.state == .failed)
        #expect(model.visibleProducts.isEmpty)
    }

    @Test
    func `cancelling a waiting observation returns to idle`() async {
        let repository = ProductListTerminalRepository(behavior: .suspended)
        let model = ProductListViewModel(observeProducts: ObserveProductsUseCase(repository: repository))
        let loading = Task {
            await model.load()
        }
        await repository.waitForObservation()
        #expect(model.state == .loading)

        loading.cancel()
        await loading.value

        #expect(model.state == .idle)
    }
}

private actor ProductListTerminalRepository: ProductRepository {
    enum Behavior {
        case finished
        case failure
        case suspended
    }

    private let behavior: Behavior
    private var hasStarted = false
    private var observationWaiter: CheckedContinuation<Void, Never>?
    private var streamContinuation: AsyncThrowingStream<[Product], any Error>.Continuation?

    init(behavior: Behavior) {
        self.behavior = behavior
    }

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        hasStarted = true
        observationWaiter?.resume()
        observationWaiter = nil

        let (stream, continuation) = AsyncThrowingStream<[Product], any Error>.makeStream()
        switch behavior {
        case .finished:
            continuation.finish()
        case .failure:
            continuation.finish(throwing: ProductError.persistenceUnavailable)
        case .suspended:
            streamContinuation = continuation
        }
        return stream
    }

    func waitForObservation() async {
        guard !hasStarted else { return }
        await withCheckedContinuation {
            observationWaiter = $0
        }
    }

    func product(id: ProductID) async throws -> Product? {
        throw ProductError.persistenceUnavailable
    }

    func saveProduct(_ product: Product) async throws {
        throw ProductError.persistenceUnavailable
    }

    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        throw ProductError.persistenceUnavailable
    }

    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        throw ProductError.persistenceUnavailable
    }

    func deactivateProduct(_ id: ProductID) async throws {
        throw ProductError.persistenceUnavailable
    }
}
