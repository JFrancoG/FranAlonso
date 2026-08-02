import SwiftData
import Testing
@testable import FranAlonso

@Suite("SwiftData store pristine data source")
@MainActor
struct SwiftDataStorePristineDataSourceTests {
    @Test("A new published-schema store is pristine")
    func newPublishedSchemaStoreIsPristine() async throws {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        let dataSource = SwiftDataStorePristineDataSource(modelContainer: container)

        #expect(try await dataSource.isPristine())
    }

    @Test(
        "Any persisted feature metadata makes the store non-pristine",
        arguments: LocalStoreFeature.allCases
    )
    fileprivate func anyPersistedFeatureMetadataMakesStoreNonPristine(_ feature: LocalStoreFeature) async throws {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)

        switch feature {
        case .clients:
            container.mainContext.insert(ClientSyncCursorModel(feedID: "clients", changeSequence: 1))
        case .products:
            container.mainContext.insert(ProductSyncCursorModel(feedID: "products", changeSequence: 1))
        case .services:
            container.mainContext.insert(ServiceSyncCursorModel(feedID: "services", changeSequence: 1))
        case .sales:
            container.mainContext.insert(SaleSyncCursorModel(feedID: "sales", changeSequence: 1))
        }
        try container.mainContext.save()

        let dataSource = SwiftDataStorePristineDataSource(modelContainer: container)

        #expect(try await !dataSource.isPristine())
    }
}

private enum LocalStoreFeature: CaseIterable, CustomTestStringConvertible {
    case clients
    case products
    case services
    case sales

    var testDescription: String {
        switch self {
        case .clients:
            "Clients"
        case .products:
            "Products"
        case .services:
            "Services"
        case .sales:
            "Sales"
        }
    }
}
