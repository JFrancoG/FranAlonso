import Foundation
import Testing
@testable import FranAlonso

@Suite("Product repository use cases")
struct ProductRepositoryUseCaseTests {
    @Test("Delegates product observation to the repository")
    func delegatesProductObservationToTheRepository() async throws {
        let product = repositoryProduct()
        let repository = ProductRepositoryFake(products: [product])
        let useCase = ObserveProductsUseCase(repository: repository)

        let stream = await useCase()
        var iterator = stream.makeAsyncIterator()

        #expect(try await iterator.next() == [product])
        #expect(try await iterator.next() == nil)
        #expect(await repository.observationCallCount() == 1)
        requireProductUseCaseSendable(useCase)
    }

    @Test("Delegates local product persistence to the repository")
    func delegatesLocalProductPersistenceToTheRepository() async throws {
        let product = repositoryProduct()
        let repository = ProductRepositoryFake(products: [])
        let useCase = SaveProductUseCase(repository: repository)

        try await useCase(product)

        #expect(await repository.savedProducts() == [product])
        #expect(await repository.saveCallCount() == 1)
        requireProductUseCaseSendable(useCase)
    }
}

private actor ProductRepositoryFake: ProductRepository {
    private let products: [Product]
    private var observationCalls = 0
    private var saveCalls = 0
    private var persistedProducts: [Product] = []

    init(products: [Product]) {
        self.products = products
    }

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        observationCalls += 1

        return AsyncThrowingStream { continuation in
            continuation.yield(products)
            continuation.finish()
        }
    }

    func saveProduct(_ product: Product) async throws {
        saveCalls += 1
        persistedProducts.append(product)
    }

    func observationCallCount() -> Int { observationCalls }

    func saveCallCount() -> Int { saveCalls }

    func savedProducts() -> [Product] { persistedProducts }
}

private func repositoryProduct() -> Product {
    Product(
        id: ProductID(
            rawValue: UUID(
                uuidString: "10000000-1000-1000-1000-100000000001"
            )!
        ),
        name: "Coloración",
        status: .active
    )
}

private func requireProductUseCaseSendable<Value: Sendable>(_ value: Value) {}
