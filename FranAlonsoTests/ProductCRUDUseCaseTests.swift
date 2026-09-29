import Foundation
import Testing
@testable import FranAlonso

@Suite("Product CRUD and search")
struct ProductCRUDUseCaseTests {
    @Test
    func `creation normalizes a name and remains visible through local lookup`() async throws {
        let repository = InMemoryProductRepository()
        let profile = try PrepareProductProfileUseCase()(name: "  Champú  suave \n")
        let id = productCRUDID(1)

        _ = try await CreateProductUseCase(repository: repository)(id: id, profile: profile)
        let reopened = try #require(try await GetProductUseCase(repository: repository)(id))

        #expect(reopened == Product(id: id, name: "Champú  suave", status: .active))
    }

    @Test(arguments: ["", " ", "\n\t"])
    func `blank editable names are rejected`(_ name: String) {
        #expect(throws: ProductError.invalidName) {
            try PrepareProductProfileUseCase()(name: name)
        }
    }

    @Test
    func `decoding cannot bypass name validation`() {
        let payload = Data(#"{"name":"  \n\t "}"#.utf8)

        #expect(throws: ProductError.invalidName) {
            try JSONDecoder().decode(ProductProfile.self, from: payload)
        }
    }

    @Test
    func `decoded editable text is normalized before local acceptance`() async throws {
        let repository = InMemoryProductRepository()
        let payload = Data(#"{"name":"  Champú teñido  "}"#.utf8)
        let profile = try JSONDecoder().decode(ProductProfile.self, from: payload)

        _ = try await CreateProductUseCase(repository: repository)(id: productCRUDID(1), profile: profile)

        #expect(try await repository.product(id: productCRUDID(1))?.name == "Champú teñido")
    }

    @Test
    func `a duplicate identity cannot replace an inactive product`() async throws {
        let original = Product(id: productCRUDID(1), name: "Original", status: .inactive)
        let repository = InMemoryProductRepository(products: [original])
        let profile = try ProductProfile(name: "Replacement")

        await #expect(throws: ProductError.alreadyExists) {
            try await CreateProductUseCase(repository: repository)(id: original.id, profile: profile)
        }

        #expect(try await repository.product(id: original.id) == original)
    }

    @Test
    func `different identities may share the same name`() async throws {
        let repository = InMemoryProductRepository()
        let profile = try ProductProfile(name: "Champú")
        let create = CreateProductUseCase(repository: repository)

        _ = try await create(id: productCRUDID(1), profile: profile)
        _ = try await create(id: productCRUDID(2), profile: profile)
        var iterator = await repository.observeProducts().makeAsyncIterator()
        let products = try #require(try await iterator.next())

        #expect(products.map(\.id) == [productCRUDID(1), productCRUDID(2)])
    }

    @Test
    func `renaming preserves the stored inactive state`() async throws {
        let original = Product(id: productCRUDID(1), name: "Original", status: .inactive)
        let repository = InMemoryProductRepository(products: [original])
        let profile = try ProductProfile(name: "  Renamed  ")

        _ = try await UpdateProductUseCase(repository: repository)(id: original.id, profile: profile)

        #expect(try await repository.product(id: original.id) == Product(
            id: original.id,
            name: "Renamed",
            status: .inactive
        ))
    }

    @Test
    func `editing a missing identity does not insert a product`() async throws {
        let repository = InMemoryProductRepository()
        let profile = try ProductProfile(name: "Absent")

        await #expect(throws: ProductError.notFound) {
            try await UpdateProductUseCase(repository: repository)(id: productCRUDID(1), profile: profile)
        }

        #expect(try await GetProductUseCase(repository: repository)(productCRUDID(1)) == nil)
    }

    @Test
    func `deactivation preserves the selected profile and the rest of the collection`() async throws {
        let selected = Product(id: productCRUDID(1), name: "Selected", status: .active)
        let other = Product(id: productCRUDID(2), name: "Other", status: .active)
        let repository = InMemoryProductRepository(products: [selected, other])
        let deactivate = DeactivateProductUseCase(repository: repository)

        try await deactivate(selected.id)
        try await deactivate(selected.id)
        var iterator = await repository.observeProducts().makeAsyncIterator()

        #expect(try await iterator.next() == [
            Product(id: selected.id, name: "Selected", status: .inactive),
            other
        ])
        #expect(try await GetProductUseCase(repository: repository)(selected.id)?.status == .inactive)
    }

    @Test
    func `deactivating an unknown identity reports absence`() async {
        let repository = InMemoryProductRepository()

        await #expect(throws: ProductError.notFound) {
            try await DeactivateProductUseCase(repository: repository)(productCRUDID(9))
        }
    }

    @Test(arguments: [
        ("", [1, 2, 3]),
        ("  \n", [1, 2, 3]),
        (" CHAMPU ", [1, 3]),
        ("suave", [1]),
        ("ausente", [])
    ])
    func `search matches names and preserves supplied order and inactive entries`(_ query: String, expectedIDs: [Int]) {
        let products = [
            Product(id: productCRUDID(1), name: "Champú suave", status: .inactive),
            Product(id: productCRUDID(2), name: "Mascarilla", status: .active),
            Product(id: productCRUDID(3), name: "Champú teñido", status: .active)
        ]

        let matches = SearchProductsUseCase()(products, query: query)

        #expect(matches.map(\.id) == expectedIDs.map(productCRUDID))
    }

    @Test
    func `prior cancellation prevents creation even if the repository would accept it`() async throws {
        let repository = InMemoryProductRepository()
        let profile = try ProductProfile(name: "Cancelled")

        await #expect(throws: CancellationError.self) {
            try await runPreCancelledProductOperation {
                _ = try await CreateProductUseCase(repository: repository)(id: productCRUDID(1), profile: profile)
            }
        }

        #expect(try await repository.product(id: productCRUDID(1)) == nil)
    }

    @Test
    func `prior cancellation prevents editing and deactivation of the stored profile`() async throws {
        let original = Product(id: productCRUDID(1), name: "Original", status: .active)
        let repository = InMemoryProductRepository(products: [original])
        let profile = try ProductProfile(name: "Cancelled")

        await #expect(throws: CancellationError.self) {
            try await runPreCancelledProductOperation {
                _ = try await UpdateProductUseCase(repository: repository)(id: original.id, profile: profile)
            }
        }
        await #expect(throws: CancellationError.self) {
            try await runPreCancelledProductOperation {
                try await DeactivateProductUseCase(repository: repository)(original.id)
            }
        }

        #expect(try await repository.product(id: original.id) == original)
    }

    @Test
    func `cancellation after acceptance does not turn a committed creation into a failure`() async throws {
        let backing = InMemoryProductRepository()
        let accepted = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let repository = ProductCRUDDelayedCreationRepository(
            backing: backing,
            accepted: accepted.continuation,
            release: release.stream
        )
        let id = productCRUDID(1)
        let profile = try ProductProfile(name: "Accepted")
        let task = Task {
            try await CreateProductUseCase(repository: repository)(id: id, profile: profile)
        }
        var acceptance = accepted.stream.makeAsyncIterator()
        _ = await acceptance.next()

        task.cancel()
        release.continuation.finish()
        let result = try await task.value

        #expect(result == Product(id: id, name: "Accepted", status: .active))
        #expect(try await backing.product(id: id) == result)
    }

    @Test
    func `prior cancellation wins over repository failure when reading`() async {
        let repository = ProductCRUDRejectedRepository(error: .persistenceUnavailable)

        await #expect(throws: CancellationError.self) {
            try await runPreCancelledProductOperation {
                _ = try await GetProductUseCase(repository: repository)(productCRUDID(1))
            }
        }
    }
}

private struct ProductCRUDDelayedCreationRepository: ProductRepository {
    let backing: InMemoryProductRepository
    let accepted: AsyncStream<Void>.Continuation
    let release: AsyncStream<Void>

    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        let product = try await backing.createProduct(id: id, profile: profile)
        accepted.yield(())
        accepted.finish()
        var iterator = release.makeAsyncIterator()
        _ = await iterator.next()
        return product
    }

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        await backing.observeProducts()
    }

    func saveProduct(_ product: Product) async throws {
        try await backing.saveProduct(product)
    }

    func product(id: ProductID) async throws -> Product? {
        try await backing.product(id: id)
    }

    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        try await backing.updateProduct(id: id, profile: profile)
    }

    func deactivateProduct(_ id: ProductID) async throws {
        try await backing.deactivateProduct(id)
    }
}

private struct ProductCRUDRejectedRepository: ProductRepository {
    let error: ProductError

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        AsyncThrowingStream { $0.finish(throwing: error) }
    }

    func saveProduct(_ product: Product) async throws { throw error }
    func product(id: ProductID) async throws -> Product? { throw error }
    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product { throw error }
    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product { throw error }
    func deactivateProduct(_ id: ProductID) async throws { throw error }
}

private func productCRUDID(_ suffix: Int) -> ProductID {
    ProductID(rawValue: UUID(uuidString: "09010000-0000-0000-0000-00000000000\(suffix)")!)
}

private func runPreCancelledProductOperation(
    _ operation: @escaping @Sendable () async throws -> Void
) async throws {
    let gate = AsyncStream<Void>.makeStream()
    let task = Task {
        var iterator = gate.stream.makeAsyncIterator()
        _ = await iterator.next()
        try await operation()
    }
    task.cancel()
    gate.continuation.finish()
    try await task.value
}
