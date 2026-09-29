import Foundation
import Testing
@testable import FranAlonso

@Suite("Service form linked product selection", .timeLimit(.minutes(1)))
@MainActor
struct ServiceFormProductSelectionTests {
    @Test
    func `selection replacement and conversion preserve commercial input until explicit save`() async throws {
        let first = Product(id: ProductID(rawValue: UUID()), name: "First", status: .active)
        let second = Product(id: ProductID(rawValue: UUID()), name: "Second", status: .active)
        let products = InMemoryProductRepository(products: [first, second])
        let fixture = try ServiceFormFixture(mode: .create, products: products)
        fixture.model.draft = serviceEditingDraft()
        await fixture.model.observeProducts()

        fixture.model.changeType(.product)
        #expect(fixture.model.draft.type == .product)
        #expect(fixture.model.draft.linkedProductID == nil)
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .service(.linkedProductRequired)))
        #expect(fixture.writes.profiles.isEmpty)

        fixture.model.selectLinkedProduct(first.id)
        #expect(fixture.model.state == .editing)
        fixture.model.selectLinkedProduct(second.id)
        var expected = serviceEditingDraft()
        expected.type = .product
        expected.linkedProductID = second.id
        #expect(fixture.model.draft == expected)
        #expect(fixture.writes.profiles.isEmpty)

        fixture.model.changeType(.professional)
        #expect(fixture.model.draft == serviceEditingDraft())
        fixture.model.changeType(.product)
        #expect(fixture.model.draft.linkedProductID == nil)
        fixture.model.selectLinkedProduct(second.id)
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.profiles.map(\.linkedProductID) == [second.id])
        #expect(fixture.writes.profiles.map(\.type) == [.product])
    }

    @Test
    func `only observed active products can replace a link while nil is an explicit draft edit`() async throws {
        let active = Product(id: ProductID(rawValue: UUID()), name: "Active", status: .active)
        let inactive = Product(id: ProductID(rawValue: UUID()), name: "Inactive", status: .inactive)
        let products = InMemoryProductRepository(products: [inactive, active])
        let fixture = try ServiceFormFixture(mode: .create, products: products)
        fixture.model.changeType(.product)
        fixture.model.selectLinkedProduct(active.id)
        #expect(fixture.model.draft.linkedProductID == nil)
        await fixture.model.observeProducts()
        #expect(fixture.model.linkableProductsState == .loaded([active]))
        fixture.model.selectLinkedProduct(active.id)
        fixture.model.selectLinkedProduct(inactive.id)
        fixture.model.selectLinkedProduct(ProductID(rawValue: UUID()))
        #expect(fixture.model.draft.linkedProductID == active.id)
        fixture.model.selectLinkedProduct(nil)
        #expect(fixture.model.draft.linkedProductID == nil)
        fixture.model.changeType(.professional)
        fixture.model.selectLinkedProduct(active.id)
        #expect(fixture.model.draft.type == .professional)
        #expect(fixture.model.draft.linkedProductID == nil)
    }

    @Test
    func `catalogue changes preserve historical selection raw edits and dirty baseline`() async throws {
        let first = Product(id: ProductID(rawValue: UUID()), name: "First", status: .active)
        let second = Product(id: ProductID(rawValue: UUID()), name: "Second", status: .active)
        let products = InMemoryProductRepository(products: [first, second])
        let fixture = try ServiceFormFixture(mode: .edit, products: products)
        let stored = try makeService(type: .product, linkedProductID: first.id.rawValue)
        await fixture.reads.set(stored)
        await fixture.model.load()
        let baseline = fixture.model.draft
        await fixture.model.observeProducts()
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.selectLinkedProduct(first.id)
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.selectLinkedProduct(second.id)
        #expect(fixture.model.hasUnsavedChanges)
        fixture.model.selectLinkedProduct(first.id)
        #expect(!fixture.model.hasUnsavedChanges)

        try await products.deactivateProduct(first.id)
        await fixture.model.observeProducts()
        #expect(fixture.model.linkableProductsState == .loaded([second]))
        #expect(fixture.model.draft == baseline)
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.draft.priceText = "unfinished,"
        let rawDraft = fixture.model.draft
        fixture.model.selectLinkedProduct(second.id)
        var replaced = rawDraft
        replaced.linkedProductID = second.id
        #expect(fixture.model.draft == replaced)
        #expect(fixture.model.hasUnsavedChanges)
    }

    @Test(arguments: [false, true])
    func `type and product intents cannot alter a draft during a mutation`(_ deactivation: Bool) async throws {
        let product = Product(id: ProductID(rawValue: UUID()), name: "Selected", status: .active)
        let fixture = try ServiceFormFixture(mode: .edit, products: InMemoryProductRepository(products: [product]))
        await fixture.reads.set(try serviceFormExpected(id: fixture.id, name: "Loaded"))
        await fixture.model.load()
        await fixture.model.observeProducts()
        fixture.model.changeType(.product)
        fixture.model.selectLinkedProduct(product.id)
        let draft = fixture.model.draft
        try #require(draft.type == .product && draft.linkedProductID == product.id)
        let gate = ServiceFormTestGate()
        fixture.writes.gate = gate
        let mutation = Task {
            defer {
                gate.finishRequest()
            }
            if deactivation {
                await fixture.model.deactivate(in: fixture.context)
            } else {
                await fixture.model.save(in: fixture.context)
            }
        }
        let entered = await gate.waitForEntry()
        fixture.model.changeType(.professional)
        fixture.model.selectLinkedProduct(nil)
        await fixture.model.observeProducts()
        #expect(fixture.model.draft == draft)
        #expect(fixture.model.state == (deactivation ? .deactivating : .saving))
        gate.release()
        await mutation.value
        #expect(entered)
    }

    @Test
    func `unread and closed sessions reject selection and type changes`() async throws {
        let product = Product(id: ProductID(rawValue: UUID()), name: "Choice", status: .active)
        let fixture = try ServiceFormFixture(mode: .edit, products: InMemoryProductRepository(products: [product]))
        await fixture.model.observeProducts()
        fixture.model.changeType(.product)
        fixture.model.selectLinkedProduct(product.id)
        #expect(fixture.model.draft == ServiceFormDraft())
        await fixture.model.load()
        fixture.model.changeType(.product)
        fixture.model.selectLinkedProduct(product.id)
        #expect(fixture.model.draft == ServiceFormDraft())
        await fixture.reads.set(try serviceFormExpected(id: fixture.id, name: "Now readable"))
        await fixture.model.load()
        fixture.model.changeType(.product)
        fixture.model.selectLinkedProduct(product.id)
        try #require(fixture.model.draft.linkedProductID == product.id)
        fixture.model.close()
        await fixture.model.observeProducts()
        fixture.model.changeType(.product)
        fixture.model.selectLinkedProduct(product.id)
        #expect(fixture.model.state == .closed)
        #expect(fixture.model.linkableProductsState == .idle)
        #expect(fixture.model.draft == ServiceFormDraft())
    }

    @Test(arguments: [ProductSelectionTerminal.content, .empty, .finished, .failed, .cancelled])
    func `finite observations distinguish snapshots absence failure and cancellation`(
        _ terminal: ProductSelectionTerminal
    ) async throws {
        let product = Product(id: ProductID(rawValue: UUID()), name: "Choice", status: .active)
        let pair = AsyncThrowingStream<[Product], any Error>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let repository = ServiceFormProductStreamStub(first: pair.stream, started: started.continuation, current: [])
        let fixture = try ServiceFormFixture(mode: .create, products: repository)
        fixture.model.draft = serviceEditingDraft()
        let draft = fixture.model.draft
        let observation = Task {
            defer {
                started.continuation.finish()
            }
            await fixture.model.observeProducts()
        }
        var iterator = started.stream.makeAsyncIterator()
        let didStart = await iterator.next() != nil
        #expect(fixture.model.linkableProductsState == .loading)
        fixture.model.changeType(.product)
        fixture.model.selectLinkedProduct(product.id)
        #expect(fixture.model.draft.linkedProductID == nil)
        fixture.model.changeType(.professional)
        completeProductObservation(pair.continuation, terminal: terminal, product: product, task: observation)
        await observation.value
        #expect(didStart)
        switch terminal {
        case .content: #expect(fixture.model.linkableProductsState == .loaded([product]))
        case .empty: #expect(fixture.model.linkableProductsState == .loaded([]))
        case .finished, .failed: #expect(fixture.model.linkableProductsState == .failed)
        case .cancelled: #expect(fixture.model.linkableProductsState == .idle)
        }
        #expect(fixture.model.state == .editing)
        #expect(fixture.model.draft == draft)
    }

    @Test
    func `reader failure and retry preserve selection and persistence error until explicit recovery`() async throws {
        let selected = Product(id: ProductID(rawValue: UUID()), name: "Selected", status: .active)
        let other = Product(id: ProductID(rawValue: UUID()), name: "Replacement", status: .active)
        let pair = AsyncThrowingStream<[Product], any Error>.makeStream()
        pair.continuation.finish(throwing: ProductError.persistenceUnavailable)
        let started = AsyncStream<Void>.makeStream()
        let repository = ServiceFormProductStreamStub(
            first: pair.stream,
            started: started.continuation,
            current: [selected, other]
        )
        let fixture = try ServiceFormFixture(mode: .create, products: repository)
        fixture.model.draft = serviceEditingDraft()
        fixture.model.draft.type = .product
        fixture.model.draft.linkedProductID = selected.id
        fixture.writes.failure = ServiceError.linkedProductUnavailable
        await fixture.model.save(in: fixture.context)
        let draft = fixture.model.draft
        await fixture.model.observeProducts()
        #expect(fixture.model.linkableProductsState == .failed)
        fixture.model.selectLinkedProduct(other.id)
        #expect(fixture.model.draft == draft)
        #expect(fixture.model.state == .failed(.save, .service(.linkedProductUnavailable)))
        fixture.model.selectLinkedProduct(nil)
        #expect(fixture.model.draft.linkedProductID == nil)
        fixture.model.draft = draft
        await fixture.model.observeProducts()
        #expect(fixture.model.linkableProductsState == .loaded([selected, other]))
        #expect(fixture.model.draft == draft)
        #expect(fixture.model.state == .failed(.save, .service(.linkedProductUnavailable)))
        fixture.model.selectLinkedProduct(other.id)
        #expect(fixture.model.state == .failed(.save, .service(.linkedProductUnavailable)))
        fixture.writes.failure = nil
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.profiles.last?.linkedProductID == other.id)
        guard case .saved = fixture.model.state else {
            Issue.record("Recovered selection must reach local acceptance")
            return
        }
    }

    @Test(arguments: [ProductSelectionTerminal.content, .empty, .finished, .failed, .cancelled])
    func `late replaced observations cannot overwrite current choices or their state`(
        _ terminal: ProductSelectionTerminal
    ) async throws {
        let current = Product(id: ProductID(rawValue: UUID()), name: "Current", status: .active)
        let obsolete = Product(id: ProductID(rawValue: UUID()), name: "Obsolete", status: .active)
        let pair = AsyncThrowingStream<[Product], any Error>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let repository = ServiceFormProductStreamStub(
            first: pair.stream,
            started: started.continuation,
            current: [current]
        )
        let fixture = try ServiceFormFixture(mode: .create, products: repository)
        let observation = Task {
            defer {
                started.continuation.finish()
            }
            await fixture.model.observeProducts()
        }
        var iterator = started.stream.makeAsyncIterator()
        let didStart = await iterator.next() != nil
        if didStart {
            await fixture.model.observeProducts()
        }
        fixture.model.changeType(.product)
        fixture.model.selectLinkedProduct(current.id)
        completeProductObservation(pair.continuation, terminal: terminal, product: obsolete, task: observation)
        await observation.value
        #expect(didStart)
        #expect(fixture.model.linkableProductsState == .loaded([current]))
        #expect(fixture.model.draft.linkedProductID == current.id)
    }

    @Test(arguments: [ProductSelectionTerminal.content, .failed, .cancelled])
    func `close fences active observations and a subsequent observation cannot reopen the session`(
        _ terminal: ProductSelectionTerminal
    ) async throws {
        let product = Product(id: ProductID(rawValue: UUID()), name: "Late", status: .active)
        let pair = AsyncThrowingStream<[Product], any Error>.makeStream()
        let started = AsyncStream<Void>.makeStream()
        let repository = ServiceFormProductStreamStub(
            first: pair.stream,
            started: started.continuation,
            current: [product]
        )
        let fixture = try ServiceFormFixture(mode: .create, products: repository)
        let observation = Task {
            defer {
                started.continuation.finish()
            }
            await fixture.model.observeProducts()
        }
        var iterator = started.stream.makeAsyncIterator()
        let didStart = await iterator.next() != nil
        fixture.model.close()
        completeProductObservation(pair.continuation, terminal: terminal, product: product, task: observation)
        await observation.value
        await fixture.model.observeProducts()
        #expect(didStart)
        #expect(fixture.model.state == .closed)
        #expect(fixture.model.linkableProductsState == .idle)
        #expect(fixture.model.draft == ServiceFormDraft())
    }
}

enum ProductSelectionTerminal { case content, empty, finished, failed, cancelled }

private func completeProductObservation(
    _ continuation: AsyncThrowingStream<[Product], any Error>.Continuation,
    terminal: ProductSelectionTerminal,
    product: Product,
    task: Task<Void, Never>
) {
    switch terminal {
    case .content:
        continuation.yield([product])
        continuation.finish()
    case .empty:
        continuation.yield([])
        continuation.finish()
    case .finished:
        continuation.finish()
    case .failed:
        continuation.finish(throwing: ProductError.persistenceUnavailable)
    case .cancelled:
        task.cancel()
        continuation.finish()
    }
}

private actor ServiceFormProductStreamStub: ProductRepository {
    private let first: AsyncThrowingStream<[Product], any Error>
    private let started: AsyncStream<Void>.Continuation
    private let current: [Product]
    private var count = 0

    init(
        first: AsyncThrowingStream<[Product], any Error>,
        started: AsyncStream<Void>.Continuation,
        current: [Product]
    ) {
        self.first = first
        self.started = started
        self.current = current
    }

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        count += 1
        if count == 1 {
            started.yield(())
            return first
        }
        return AsyncThrowingStream {
            $0.yield(current)
            $0.finish()
        }
    }

    func product(id: ProductID) async throws -> Product? { nil }
    func saveProduct(_ product: Product) async throws { throw ProductError.persistenceUnavailable }
    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        throw ProductError.persistenceUnavailable
    }
    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        throw ProductError.persistenceUnavailable
    }
    func deactivateProduct(_ id: ProductID) async throws { throw ProductError.persistenceUnavailable }
}
