import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product local data source")
struct ProductLocalDataSourceTests {
    private let dataSource = ProductLocalDataSource()

    @Test("Explicit save makes an inserted product visible from another context")
    func explicitSaveMakesAnInsertedProductVisibleFromAnotherContext() throws {
        let container = try makeProductContainer()
        let product = try completeProduct(
            id: "10000000-0000-0000-0000-000000000001",
            name: "Champú nutritivo"
        )
        let insertionContext = ModelContext(container)
        insertionContext.autosaveEnabled = false

        try dataSource.upsert(product, in: insertionContext)

        #expect(!insertionContext.hasChanges)
        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext) == [product])
    }

    @Test("Upsert updates the product with the same stable identifier")
    func upsertUpdatesTheProductWithTheSameStableIdentifier() throws {
        let container = try makeProductContainer()
        let identifier = "10000000-0000-0000-0000-000000000002"
        let initialProduct = Product(
            id: try productID(identifier),
            name: "Initial name",
            status: .active
        )
        let updatedProduct = try completeProduct(
            id: identifier,
            name: "Updated name"
        )

        try dataSource.upsert(initialProduct, in: ModelContext(container))
        try dataSource.upsert(updatedProduct, in: ModelContext(container))

        let verificationContext = ModelContext(container)
        #expect(try verificationContext.fetchCount(FetchDescriptor<ProductModel>()) == 1)
        #expect(try dataSource.fetchAll(in: verificationContext) == [updatedProduct])
    }

    @Test("The model schema enforces unique product identifiers")
    func modelSchemaEnforcesUniqueProductIdentifiers() throws {
        let container = try makeProductContainer()
        let identifier = "10000000-0000-0000-0000-000000000003"
        let firstProduct = Product(
            id: try productID(identifier),
            name: "First value",
            status: .active
        )
        let replacementProduct = Product(
            id: try productID(identifier),
            name: "Replacement value",
            status: .inactive
        )
        let firstContext = ModelContext(container)
        firstContext.insert(ProductModel(firstProduct))
        try firstContext.save()

        let replacementContext = ModelContext(container)
        replacementContext.insert(ProductModel(replacementProduct))
        try replacementContext.save()

        let verificationContext = ModelContext(container)
        #expect(try verificationContext.fetchCount(FetchDescriptor<ProductModel>()) == 1)
        #expect(
            try dataSource.fetchAll(in: verificationContext) == [replacementProduct]
        )
    }

    @Test("Delete removes an existing product and is idempotent when repeated")
    func deleteRemovesAnExistingProductAndIsIdempotentWhenRepeated() throws {
        let container = try makeProductContainer()
        let product = Product(
            id: try productID("10000000-0000-0000-0000-000000000004"),
            name: "Product to delete",
            status: .active
        )
        try dataSource.upsert(product, in: ModelContext(container))

        try dataSource.delete(product.id, in: ModelContext(container))
        let verificationContext = ModelContext(container)
        #expect(try dataSource.fetchAll(in: verificationContext).isEmpty)

        let repeatedDeletionContext = ModelContext(container)
        repeatedDeletionContext.autosaveEnabled = false
        try dataSource.delete(product.id, in: repeatedDeletionContext)
        #expect(!repeatedDeletionContext.hasChanges)
    }

    @Test("Model conversion rejects an unknown persisted product status")
    func modelConversionRejectsAnUnknownPersistedProductStatus() throws {
        let model = ProductModel(
            id: try rawUUID("10000000-0000-0000-0000-000000000005"),
            name: "Invalid status",
            statusRawValue: "suspended"
        )

        #expect(throws: ProductMappingError.invalidPersistedStatus("suspended")) {
            try model.toDomain()
        }
    }

}

private func makeProductContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(for: Schema([ProductModel.self]))
}

private func completeProduct(id: String, name: String) throws -> Product {
    Product(
        id: try productID(id),
        name: name,
        status: .active
    )
}

private func productID(_ value: String) throws -> ProductID {
    ProductID(rawValue: try rawUUID(value))
}

private func rawUUID(_ value: String) throws -> UUID {
    try #require(UUID(uuidString: value))
}
