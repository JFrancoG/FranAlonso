import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product form draft protection")
@MainActor
struct ProductFormDraftTests {
    @Test
    func `creation protects typed input and clears protection after a complete reversal`() async throws {
        let fixture = try ProductDraftFixture(mode: .create)
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.name = "New shampoo"
        #expect(fixture.model.hasUnsavedChanges)
        fixture.model.name = ""
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.name = "  "
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .invalidName))
        #expect(fixture.model.hasUnsavedChanges)
        fixture.model.name = ""
        #expect(!fixture.model.hasUnsavedChanges)
    }

    @Test
    func `editing compares against the loaded name and does not protect an unread form`() async throws {
        let fixture = try ProductDraftFixture(mode: .edit)
        fixture.model.name = "Before the read"
        #expect(!fixture.model.hasUnsavedChanges)
        await fixture.model.load()
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.name = "Changed shampoo"
        #expect(fixture.model.hasUnsavedChanges)
        fixture.model.name = "Original shampoo"
        #expect(!fixture.model.hasUnsavedChanges)
        fixture.model.name = " Original shampoo "
        #expect(fixture.model.hasUnsavedChanges)
    }

    @Test
    func `failed mutations retain discard protection until the original name is restored`() async throws {
        let fixture = try ProductDraftFixture(mode: .edit)
        await fixture.model.load()
        fixture.model.name = "Changed shampoo"
        fixture.writes.failure = .conflict
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .conflict))
        #expect(fixture.model.hasUnsavedChanges)
        await fixture.model.deactivate(in: fixture.context)
        #expect(fixture.model.state == .failed(.deactivate, .conflict))
        #expect(fixture.model.hasUnsavedChanges)
        fixture.model.name = "Original shampoo"
        #expect(!fixture.model.hasUnsavedChanges)
    }

    @Test(arguments: [ProductDraftTerminal.saved, .deactivated, .closed])
    func `terminal sessions no longer protect a discarded or accepted draft`(
        terminal: ProductDraftTerminal
    ) async throws {
        let fixture = try ProductDraftFixture(mode: .edit)
        await fixture.model.load()
        fixture.model.name = "Changed shampoo"
        #expect(fixture.model.hasUnsavedChanges)
        switch terminal {
        case .saved:
            await fixture.model.save(in: fixture.context)
            guard case .saved = fixture.model.state else {
                Issue.record("The local write must be accepted before checking terminal protection")
                return
            }
        case .deactivated:
            await fixture.model.deactivate(in: fixture.context)
            #expect(fixture.model.state == .deactivated)
        case .closed:
            fixture.model.close()
            #expect(fixture.model.state == .closed)
        }
        fixture.model.name = "Late input cannot reopen a terminal session"
        #expect(!fixture.model.hasUnsavedChanges)
    }
}

enum ProductDraftTerminal {
    case saved, deactivated, closed
}

@MainActor
private struct ProductDraftFixture {
    let container: ModelContainer
    let model: ProductFormViewModel
    let writes: ProductDraftWrites

    var context: ModelContext { container.mainContext }
}

private extension ProductDraftFixture {
    init(mode: ProductFormDestination.Mode) throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let id = ProductID(rawValue: UUID())
        let product = Product(id: id, name: "Original shampoo", status: .active)
        let repository = InMemoryProductRepository(products: mode == .edit ? [product] : [])
        let writes = ProductDraftWrites()
        self.init(
            container: container,
            model: ProductFormViewModel(
                destination: ProductFormDestination(id: UUID(), productID: id, mode: mode),
                getProduct: GetProductUseCase(repository: repository),
                create: { id, profile, _ in
                    try writes.save(id, profile: profile)
                },
                update: { id, profile, _ in
                    try writes.save(id, profile: profile)
                },
                deactivate: { _, _ in
                    try writes.deactivate()
                }
            ),
            writes: writes
        )
    }
}

@MainActor
private final class ProductDraftWrites {
    var failure: ProductError?

    func save(_ id: ProductID, profile: ProductProfile) throws -> Product {
        if let failure {
            throw failure
        }
        return Product(id: id, name: profile.name, status: .active)
    }

    func deactivate() throws {
        if let failure {
            throw failure
        }
    }
}
