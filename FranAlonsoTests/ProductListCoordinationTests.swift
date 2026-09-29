import Foundation
import Testing
@testable import FranAlonso

@Suite("Product list search and navigation")
@MainActor
struct ProductListCoordinationTests {
    @Test
    func `search follows the latest query and changed local snapshots`() async throws {
        let firstID = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000021"))
        let secondID = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000022"))
        let active = Product(id: ProductID(rawValue: firstID), name: "Shampoo", status: .active)
        let inactive = Product(id: ProductID(rawValue: secondID), name: "Conditioner", status: .inactive)
        let repository = InMemoryProductRepository(products: [active, inactive])
        let model = ProductListViewModel(observeProducts: ObserveProductsUseCase(repository: repository))
        model.query = "Shampoo"
        await model.load()
        #expect(model.visibleProducts == [active])

        model.query = "Conditioner"
        #expect(model.visibleProducts == [inactive])
        let updated = try await repository.updateProduct(
            id: active.id,
            profile: ProductProfile(name: "Conditioner refill")
        )
        await model.load()
        #expect(model.visibleProducts == [updated, inactive])
        #expect(model.state == .content([updated, inactive]))

        model.query = "No matching product"
        #expect(model.visibleProducts.isEmpty)
        #expect(model.hasNoSearchResults)
        #expect(model.state == .content([updated, inactive]))
    }

    @Test
    func `creation preserves identity until its matching session closes`() throws {
        let firstSession = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000011"))
        let firstProduct = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000012"))
        let secondSession = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000013"))
        let secondProduct = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000014"))
        var identifiers = [firstSession, firstProduct, secondSession, secondProduct]
        let model = ProductListViewModel(
            observeProducts: ObserveProductsUseCase(repository: InMemoryProductRepository()),
            makeID: { identifiers.removeFirst() }
        )

        model.beginCreatingProduct()
        let first = try #require(model.formDestination)
        model.beginCreatingProduct()
        #expect(model.formDestination == first)
        #expect(first.id == firstSession)
        #expect(first.productID == ProductID(rawValue: firstProduct))
        #expect(first.mode == .create)

        model.finishFormSession(firstSession)
        model.beginCreatingProduct()
        let second = try #require(model.formDestination)
        model.finishFormSession(firstSession)
        #expect(model.formDestination == second)
        #expect(second.id == secondSession)
        #expect(second.productID == ProductID(rawValue: secondProduct))

        model.finishFormSession(secondSession)
        #expect(model.formDestination == nil)
        #expect(identifiers.isEmpty)
    }

    @Test
    func `editing only opens a visible identity and ignores repeated openings`() async throws {
        let id = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000031"))
        let otherID = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000032"))
        let sessionID = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000033"))
        let product = Product(id: ProductID(rawValue: id), name: "Conditioner", status: .inactive)
        let model = ProductListViewModel(
            observeProducts: ObserveProductsUseCase(repository: InMemoryProductRepository(products: [product])),
            makeID: { sessionID }
        )
        model.beginEditingProduct(product.id)
        #expect(model.formDestination == nil)
        await model.load()
        model.beginEditingProduct(ProductID(rawValue: otherID))
        #expect(model.formDestination == nil)

        model.query = "Missing"
        model.beginEditingProduct(product.id)
        #expect(model.formDestination == nil)
        model.query = "Conditioner"
        model.beginEditingProduct(product.id)
        let destination = try #require(model.formDestination)
        #expect(destination.id == sessionID)
        #expect(destination.productID == product.id)
        #expect(destination.mode == .edit)

        model.beginCreatingProduct()
        model.beginEditingProduct(product.id)
        #expect(model.formDestination == destination)
    }

    @Test(arguments: [StaleProductObservation.snapshot, .failure, .finished, .cancelled], [false, true])
    func `replaced observations cannot publish values or terminal states`(
        outcome: StaleProductObservation,
        delaysIterator: Bool
    ) async throws {
        let id = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000041"))
        let current = Product(id: ProductID(rawValue: id), name: "Current product", status: .inactive)
        let repository = DelayedProductListRepository(current: current, delaysIterator: delaysIterator)
        let model = ProductListViewModel(observeProducts: ObserveProductsUseCase(repository: repository))
        let oldLoad = Task {
            await model.load()
        }
        await repository.waitForFirstRequest()
        await model.load()
        #expect(model.state == .content([current]))

        if outcome == .cancelled {
            oldLoad.cancel()
        }
        await repository.releaseFirst(outcome)
        await oldLoad.value

        #expect(model.state == .content([current]))
        #expect(model.visibleProducts == [current])
    }

    @Test
    func `a delayed snapshot uses the query edited during loading`() async throws {
        let id = try #require(UUID(uuidString: "09030000-0000-0000-0000-000000000051"))
        let product = Product(id: ProductID(rawValue: id), name: "Conditioner", status: .inactive)
        let repository = DelayedProductListRepository(current: product)
        let model = ProductListViewModel(observeProducts: ObserveProductsUseCase(repository: repository))
        let loading = Task {
            await model.load()
        }
        await repository.waitForFirstRequest()
        model.query = "No matching product"
        await repository.releaseFirst(.snapshot)
        await loading.value

        #expect(model.visibleProducts.isEmpty)
        #expect(model.hasNoSearchResults)
    }
}

enum StaleProductObservation {
    case snapshot
    case failure
    case finished
    case cancelled
}

private actor DelayedProductListRepository: ProductRepository {
    private let current: Product
    private let delaysIterator: Bool
    private var callCount = 0
    private var firstRequest: CheckedContinuation<AsyncThrowingStream<[Product], any Error>, Never>?
    private var firstElement: CheckedContinuation<[Product]?, any Error>?
    private var hasRequestedElement = false
    private var observationWaiter: CheckedContinuation<Void, Never>?

    init(current: Product, delaysIterator: Bool = false) {
        self.current = current
        self.delaysIterator = delaysIterator
    }

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        callCount += 1
        if callCount == 1 {
            if delaysIterator {
                return AsyncThrowingStream(unfolding: {
                    try await self.delayedElement()
                })
            }
            return await withCheckedContinuation { continuation in
                firstRequest = continuation
                observationWaiter?.resume()
                observationWaiter = nil
            }
        }
        return AsyncThrowingStream { continuation in
            continuation.yield([current])
            continuation.finish()
        }
    }

    func waitForFirstRequest() async {
        guard firstRequest == nil, firstElement == nil else { return }
        await withCheckedContinuation {
            observationWaiter = $0
        }
    }

    func releaseFirst(_ outcome: StaleProductObservation) {
        let obsolete = Product(id: current.id, name: "Obsolete product", status: .active)
        if let firstElement {
            self.firstElement = nil
            switch outcome {
            case .snapshot, .cancelled:
                firstElement.resume(returning: [obsolete])
            case .failure:
                firstElement.resume(throwing: ProductError.persistenceUnavailable)
            case .finished:
                firstElement.resume(returning: nil)
            }
            return
        }
        firstRequest?.resume(returning: AsyncThrowingStream { continuation in
            switch outcome {
            case .snapshot, .cancelled:
                continuation.yield([obsolete])
                continuation.finish()
            case .failure:
                continuation.finish(throwing: ProductError.persistenceUnavailable)
            case .finished:
                continuation.finish()
            }
        })
        firstRequest = nil
    }

    private func delayedElement() async throws -> [Product]? {
        guard !hasRequestedElement else { return nil }
        hasRequestedElement = true
        return try await withCheckedThrowingContinuation { continuation in
            firstElement = continuation
            observationWaiter?.resume()
            observationWaiter = nil
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
