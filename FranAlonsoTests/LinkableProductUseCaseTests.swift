import Foundation
import Testing
@testable import FranAlonso

@Suite("Linkable product contracts", .timeLimit(.minutes(1)))
struct LinkableProductUseCaseTests {
    @Test
    func `observation filters each snapshot without changing order and preserves empty updates`() async throws {
        let pair = AsyncThrowingStream<[Product], any Error>.makeStream()
        let repository = LinkableProductReadFixture(stream: pair.stream)
        var iterator = await ObserveLinkableProductsUseCase(repository: repository)().makeAsyncIterator()
        let first = linkableProduct(1)
        let second = linkableProduct(2)
        pair.continuation.yield([second, linkableProduct(3, status: .inactive), first])
        #expect(try await iterator.next() == [second, first])
        pair.continuation.yield([linkableProduct(2, status: .inactive), first])
        #expect(try await iterator.next() == [first])
        pair.continuation.yield([])
        #expect(try await iterator.next() == [])
        pair.continuation.finish()
        #expect(try await iterator.next() == nil)
    }

    @Test
    func `an observation failure is not presented as an empty catalogue`() async throws {
        let pair = AsyncThrowingStream<[Product], any Error>.makeStream()
        let repository = LinkableProductReadFixture(stream: pair.stream)
        var iterator = await ObserveLinkableProductsUseCase(repository: repository)().makeAsyncIterator()
        pair.continuation.finish(throwing: LinkableReadFailure.unavailable)
        await #expect(throws: LinkableReadFailure.unavailable) {
            try await iterator.next()
        }
    }

    @Test
    func `cancelling iteration terminates the original subscription`() async throws {
        let pair = AsyncThrowingStream<[Product], any Error>.makeStream()
        let ended = AsyncStream<Void>.makeStream()
        pair.continuation.onTermination = { _ in
            ended.continuation.yield(())
            ended.continuation.finish()
        }
        let repository = LinkableProductReadFixture(stream: pair.stream)
        let task = Task {
            var iterator = await ObserveLinkableProductsUseCase(repository: repository)().makeAsyncIterator()
            return try await iterator.next()
        }
        task.cancel()
        #expect(try await task.value == nil)
        var termination = ended.stream.makeAsyncIterator()
        #expect(await termination.next() != nil)
    }

    @Test
    func `a selected product is resolved again after inventory deactivation`() async throws {
        let product = linkableProduct(1)
        let repository = InMemoryProductRepository(products: [product])
        let get = GetLinkableProductUseCase(repository: repository)
        #expect(try await get(product.id) == product)
        try await repository.deactivateProduct(product.id)
        await #expect(throws: ServiceError.linkedProductUnavailable) {
            try await get(product.id)
        }
        await #expect(throws: ServiceError.linkedProductUnavailable) {
            try await get(linkableProduct(2).id)
        }
    }

    @Test
    func `a different returned identity cannot replace the selected product silently`() async throws {
        let repository = LinkableProductReadFixture(lookup: { _ in linkableProduct(2) })
        await #expect(throws: ServiceError.linkedProductUnavailable) {
            try await GetLinkableProductUseCase(repository: repository)(linkableProduct(1).id)
        }
    }

    @Test
    func `lookup errors and cancellation keep their original meaning`() async throws {
        let failing = LinkableProductReadFixture(lookup: { _ in throw LinkableReadFailure.unavailable })
        await #expect(throws: LinkableReadFailure.unavailable) {
            try await GetLinkableProductUseCase(repository: failing)(linkableProduct(1).id)
        }
        let cancelled = LinkableProductReadFixture(lookup: { _ in throw CancellationError() })
        await #expect(throws: CancellationError.self) {
            try await GetLinkableProductUseCase(repository: cancelled)(linkableProduct(1).id)
        }
    }

    @Test
    func `in memory acceptance rejects a link that inventory has made inactive`() async throws {
        let product = linkableProduct(1)
        let products = InMemoryProductRepository(products: [product])
        let services = InMemoryServiceRepository(productRepository: products)
        let id = ServiceID(rawValue: UUID())
        let profile = try linkableServiceProfile(product.id)
        _ = try await services.createService(id: id, profile: profile)
        let before = try await services.service(id: id)
        try await products.deactivateProduct(product.id)
        await #expect(throws: ServiceError.linkedProductUnavailable) {
            try await services.updateService(id: id, profile: profile)
        }
        await #expect(throws: ServiceError.linkedProductUnavailable) {
            try await services.createService(id: ServiceID(rawValue: UUID()), profile: profile)
        }
        #expect(try await services.service(id: id) == before)
        try await services.deactivateService(id)
        #expect(try await services.service(id: id)?.status == .inactive)
    }

    @Test
    func `in memory editing preserves deactivation that occurs while its product lookup is suspended`() async throws {
        let entered = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let product = linkableProduct(1)
        let products = LinkableProductReadFixture(lookup: { _ in
            entered.continuation.yield(())
            var iterator = release.stream.makeAsyncIterator()
            _ = await iterator.next()
            return product
        })
        let original = try makeService()
        let services = InMemoryServiceRepository(services: [original], productRepository: products)
        let task = Task {
            defer { entered.continuation.finish() }
            return try await services.updateService(id: original.id, profile: linkableServiceProfile(product.id))
        }
        var started = entered.stream.makeAsyncIterator()
        let reachedLookup = await started.next() != nil
        do {
            if reachedLookup {
                try await services.deactivateService(original.id)
            }
        } catch {
            release.continuation.finish()
            _ = try? await task.value
            throw error
        }
        release.continuation.finish()
        let result = try await task.value
        #expect(reachedLookup)
        #expect(result.status == .inactive)
        #expect(result.name == "Linked offering")
        #expect(try await services.service(id: original.id) == result)
    }

    @Test
    func `in memory creation rechecks identity after a suspended product lookup`() async throws {
        let entered = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let product = linkableProduct(1)
        let products = LinkableProductReadFixture(lookup: { _ in
            entered.continuation.yield(())
            var iterator = release.stream.makeAsyncIterator()
            _ = await iterator.next()
            return product
        })
        let original = try makeService(name: "Concurrent acceptance", status: .inactive)
        let services = InMemoryServiceRepository(productRepository: products)
        let task = Task {
            defer { entered.continuation.finish() }
            return try await services.createService(id: original.id, profile: linkableServiceProfile(product.id))
        }
        var started = entered.stream.makeAsyncIterator()
        let reachedLookup = await started.next() != nil
        do {
            try await services.saveService(original)
        } catch {
            release.continuation.finish()
            _ = try? await task.value
            throw error
        }
        release.continuation.finish()
        await #expect(throws: ServiceError.alreadyExists) {
            try await task.value
        }
        #expect(reachedLookup)
        #expect(try await services.service(id: original.id) == original)
    }

    @Test
    func `cancellation during product lookup prevents in memory acceptance`() async throws {
        let entered = AsyncStream<Void>.makeStream()
        let release = AsyncStream<Void>.makeStream()
        let product = linkableProduct(1)
        let products = LinkableProductReadFixture(lookup: { _ in
            entered.continuation.yield(())
            var iterator = release.stream.makeAsyncIterator()
            _ = await iterator.next()
            return product
        })
        let services = InMemoryServiceRepository(productRepository: products)
        let id = ServiceID(rawValue: UUID())
        let task = Task {
            defer { entered.continuation.finish() }
            return try await services.createService(id: id, profile: linkableServiceProfile(product.id))
        }
        var started = entered.stream.makeAsyncIterator()
        let reachedLookup = await started.next() != nil
        task.cancel()
        release.continuation.finish()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(reachedLookup)
        #expect(try await services.service(id: id) == nil)
    }

    @Test
    func `product failure is distinct from unavailability and professional creation skips lookup`() async throws {
        let products = LinkableProductReadFixture(lookup: { _ in throw LinkableReadFailure.unavailable })
        let services = InMemoryServiceRepository(productRepository: products)
        await #expect(throws: ServiceError.persistenceUnavailable) {
            try await services.createService(
                id: ServiceID(rawValue: UUID()),
                profile: linkableServiceProfile(linkableProduct(1).id)
            )
        }
        let profile = try ServiceProfile(
            name: "Professional",
            type: .professional,
            price: Money(amount: 17, currency: .eur),
            taxRate: TaxRate(percentage: 21),
            discount: nil
        )
        let professional = try await services.createService(id: ServiceID(rawValue: UUID()), profile: profile)
        #expect(professional.type == .professional)
    }

    @Test
    @MainActor
    func `app readers share the injected catalogue while general inventory keeps inactive products`() async throws {
        let active = linkableProduct(1)
        let inactive = linkableProduct(2, status: .inactive)
        let dependencies = AppDependencies.preview(products: [inactive, active])
        var linkable = await dependencies.observeLinkableProducts().makeAsyncIterator()
        var inventory = await dependencies.observeProducts().makeAsyncIterator()
        #expect(try await linkable.next() == [active])
        #expect(try await inventory.next() == [inactive, active])
        #expect(try await dependencies.getLinkableProduct(active.id) == active)
        await #expect(throws: ServiceError.linkedProductUnavailable) {
            try await dependencies.getLinkableProduct(inactive.id)
        }
    }
}

private enum LinkableReadFailure: Error {
    case unavailable
}

private struct LinkableProductReadFixture: ProductRepository {
    let source: AsyncThrowingStream<[Product], any Error>
    let readProduct: @Sendable (ProductID) async throws -> Product?

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> { source }
    func product(id: ProductID) async throws -> Product? {
        try await readProduct(id)
    }
    func saveProduct(_ product: Product) async throws { throw LinkableReadFailure.unavailable }
    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        throw LinkableReadFailure.unavailable
    }
    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        throw LinkableReadFailure.unavailable
    }
    func deactivateProduct(_ id: ProductID) async throws { throw LinkableReadFailure.unavailable }
}

private extension LinkableProductReadFixture {
    init(
        stream: AsyncThrowingStream<[Product], any Error> = AsyncThrowingStream { $0.finish() },
        lookup: @escaping @Sendable (ProductID) async throws -> Product? = { _ in nil }
    ) {
        self.init(source: stream, readProduct: lookup)
    }
}

private func linkableProduct(_ value: Int, status: ProductStatus = .active) -> Product {
    Product(
        id: ProductID(rawValue: UUID(uuidString: "10300000-0000-0000-0000-00000000000\(value)")!),
        name: "Product \(value)",
        status: status
    )
}

private func linkableServiceProfile(_ productID: ProductID) throws -> ServiceProfile {
    try ServiceProfile(
        name: "Linked offering",
        type: .product,
        linkedProductID: productID,
        price: Money(amount: 17, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: nil
    )
}
