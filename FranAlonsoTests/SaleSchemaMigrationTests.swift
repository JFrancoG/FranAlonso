import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sales schema migration")
struct SaleSchemaMigrationTests {
    @Test("The exact 21-model store reopens with seven empty Sale tables")
    func publishedStoreReopensWithEmptySaleTables() throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-05.10c-Sale-Migration-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(
            at: directory,
            withIntermediateDirectories: true
        )
        defer { try? FileManager.default.removeItem(at: directory) }
        let storeURL = directory.appending(path: "Published-21.store")

        let fixture = try writePublishedStore(at: storeURL)
        let configuration = ModelConfiguration(
            "PhaseFiveTenCSales",
            schema: .franAlonso,
            url: storeURL,
            allowsSave: true,
            cloudKitDatabase: .none
        )
        let reopened = try ModelContainer(
            for: Schema.franAlonso,
            configurations: [configuration]
        )
        let context = ModelContext(reopened)

        try verifyPublishedRows(in: context, fixture: fixture)
        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SalePendingDiscardModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleRemoteStateModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleSyncConflictModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleSyncCursorModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleSyncRetryModel>()) == 0)
    }
}

private struct PublishedStoreFixture {
    let client: Client
    let product: Product
    let service: Service
    let clientRetry: SyncRetryState
    let productRetry: SyncRetryState
    let serviceRetry: SyncRetryState
}

private func writePublishedStore(at storeURL: URL) throws -> PublishedStoreFixture {
    let schema = publishedTwentyOneModelSchema
    let configuration = ModelConfiguration(
        "PublishedPhaseFiveTenB",
        schema: schema,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    let container = try ModelContainer(for: schema, configurations: [configuration])
    let context = ModelContext(container)

    let client = Client.draft(
        id: ClientID(rawValue: migrationUUID("61000000-0000-0000-0000-000000000001")),
        displayName: "Published client"
    )
    let clientDTO = ClientDTO(client)
    let clientOperationID = migrationUUID("61000000-0000-0000-0000-000000000002")
    let clientUpsert = ClientPendingUpsert(
        clientID: client.id.rawValue,
        operationID: clientOperationID,
        predecessorOperationID: nil,
        base: .versioned(10),
        client: clientDTO
    )
    let clientRecord = ClientRemoteRecord(
        client: clientDTO,
        version: .versioned(revision: 11, lastOperationID: clientOperationID),
        changeSequence: 12
    )
    let clientRetry = try SyncRetryState(
        scope: .pull,
        backoffStep: 2,
        notBefore: Date(timeIntervalSinceReferenceDate: 610),
        lastRecoverableCategory: .unavailable
    )
    context.insert(ClientModel(client))
    context.insert(
        try ClientPendingUpsertModel(
            clientID: client.id.rawValue,
            operationID: clientOperationID,
            base: clientUpsert.base,
            payload: clientDTO
        )
    )
    context.insert(
        try ClientPendingDeleteModel(
            clientID: client.id.rawValue,
            operationID: migrationUUID("61000000-0000-0000-0000-000000000003"),
            predecessorOperationID: clientOperationID,
            base: .versioned(11)
        )
    )
    context.insert(try ClientRemoteStateModel(record: clientRecord))
    context.insert(
        try ClientSyncConflictModel(
            operation: clientUpsert,
            reason: .baseChanged,
            remoteRecord: clientRecord
        )
    )
    context.insert(ClientSyncCursorModel(feedID: "clients", changeSequence: 12))
    context.insert(ClientSyncRetryModel(clientRetry))

    let product = Product.testSnapshot(
        id: ProductID(rawValue: migrationUUID("62000000-0000-0000-0000-000000000001")),
        name: "Published product"
    )
    let productDTO = ProductDTO(product)
    let productOperationID = migrationUUID("62000000-0000-0000-0000-000000000002")
    let productUpsert = ProductPendingUpsert(
        productID: product.id.rawValue,
        operationID: productOperationID,
        predecessorOperationID: nil,
        base: .versioned(20),
        product: productDTO
    )
    let productRecord = ProductRemoteRecord(
        product: productDTO,
        version: .versioned(revision: 21, lastOperationID: productOperationID),
        changeSequence: 22
    )
    let productRetry = try SyncRetryState(
        scope: .operation(productOperationID),
        backoffStep: 3,
        notBefore: Date(timeIntervalSinceReferenceDate: 620),
        lastRecoverableCategory: .deadlineExceeded
    )
    context.insert(ProductModel(product))
    context.insert(
        try ProductPendingUpsertModel(
            productID: product.id.rawValue,
            operationID: productOperationID,
            base: productUpsert.base,
            payload: productDTO
        )
    )
    context.insert(
        try ProductPendingDeleteModel(
            productID: product.id.rawValue,
            operationID: migrationUUID("62000000-0000-0000-0000-000000000003"),
            predecessorOperationID: productOperationID,
            base: .versioned(21)
        )
    )
    context.insert(try ProductRemoteStateModel(record: productRecord))
    context.insert(
        try ProductSyncConflictModel(
            operation: productUpsert,
            reason: .baseChanged,
            remoteRecord: productRecord
        )
    )
    context.insert(ProductSyncCursorModel(feedID: "products", changeSequence: 22))
    context.insert(ProductSyncRetryModel(productRetry))

    let service = try makeService(
        id: migrationUUID("63000000-0000-0000-0000-000000000001"),
        name: "Published service",
        priceAmount: 29.95,
        taxPercentage: 21,
        discountPercentage: 10
    )
    let serviceDTO = try ServiceDTO(service)
    let serviceOperationID = migrationUUID("63000000-0000-0000-0000-000000000002")
    let serviceUpsert = ServicePendingUpsert(
        serviceID: service.id.rawValue,
        operationID: serviceOperationID,
        predecessorOperationID: nil,
        base: .versioned(30),
        service: serviceDTO
    )
    let serviceRecord = ServiceRemoteRecord(
        service: serviceDTO,
        version: .versioned(revision: 31, lastOperationID: serviceOperationID),
        changeSequence: 32
    )
    let serviceRetry = try SyncRetryState(
        scope: .operation(serviceOperationID),
        backoffStep: 4,
        notBefore: Date(timeIntervalSinceReferenceDate: 630),
        lastRecoverableCategory: .aborted
    )
    context.insert(try ServiceModel(service))
    context.insert(
        try ServicePendingUpsertModel(
            serviceID: service.id.rawValue,
            operationID: serviceOperationID,
            base: serviceUpsert.base,
            payload: serviceDTO
        )
    )
    context.insert(
        try ServicePendingDeleteModel(
            serviceID: service.id.rawValue,
            operationID: migrationUUID("63000000-0000-0000-0000-000000000003"),
            predecessorOperationID: serviceOperationID,
            base: .versioned(31)
        )
    )
    context.insert(try ServiceRemoteStateModel(record: serviceRecord))
    context.insert(
        try ServiceSyncConflictModel(
            operation: serviceUpsert,
            reason: .baseChanged,
            remoteRecord: serviceRecord
        )
    )
    context.insert(ServiceSyncCursorModel(feedID: "services", changeSequence: 32))
    context.insert(ServiceSyncRetryModel(serviceRetry))

    try context.save()
    return PublishedStoreFixture(
        client: client,
        product: product,
        service: service,
        clientRetry: clientRetry,
        productRetry: productRetry,
        serviceRetry: serviceRetry
    )
}

private func verifyPublishedRows(
    in context: ModelContext,
    fixture: PublishedStoreFixture
) throws {
    #expect(try context.fetch(FetchDescriptor<ClientModel>()).count == 1)
    #expect(try context.fetch(FetchDescriptor<ClientModel>())[0].toDomain() == fixture.client)
    #expect(try context.fetch(FetchDescriptor<ClientPendingUpsertModel>())[0].decodePayload() == ClientDTO(fixture.client))
    #expect(try context.fetch(FetchDescriptor<ClientPendingDeleteModel>())[0].decodeBase() == .versioned(11))
    #expect(try context.fetch(FetchDescriptor<ClientRemoteStateModel>())[0].decodeRecord().changeSequence == 12)
    #expect(try context.fetch(FetchDescriptor<ClientSyncConflictModel>())[0].decodeReason() == .baseChanged)
    #expect(try context.fetch(FetchDescriptor<ClientSyncCursorModel>())[0].changeSequence == 12)
    #expect(try context.fetch(FetchDescriptor<ClientSyncRetryModel>())[0].decodeState(for: fixture.clientRetry.scope) == fixture.clientRetry)

    #expect(try context.fetch(FetchDescriptor<ProductModel>()).count == 1)
    #expect(try context.fetch(FetchDescriptor<ProductModel>())[0].toDomain() == fixture.product)
    #expect(try context.fetch(FetchDescriptor<ProductPendingUpsertModel>())[0].decodePayload() == ProductDTO(fixture.product))
    #expect(try context.fetch(FetchDescriptor<ProductPendingDeleteModel>())[0].decodeBase() == .versioned(21))
    #expect(try context.fetch(FetchDescriptor<ProductRemoteStateModel>())[0].decodeRecord().changeSequence == 22)
    #expect(try context.fetch(FetchDescriptor<ProductSyncConflictModel>())[0].decodeReason() == .baseChanged)
    #expect(try context.fetch(FetchDescriptor<ProductSyncCursorModel>())[0].changeSequence == 22)
    #expect(try context.fetch(FetchDescriptor<ProductSyncRetryModel>())[0].decodeState(for: fixture.productRetry.scope) == fixture.productRetry)

    #expect(try context.fetch(FetchDescriptor<ServiceModel>()).count == 1)
    #expect(try context.fetch(FetchDescriptor<ServiceModel>())[0].toDomain() == fixture.service)
    #expect(try context.fetch(FetchDescriptor<ServicePendingUpsertModel>())[0].decodePayload() == ServiceDTO(fixture.service))
    #expect(try context.fetch(FetchDescriptor<ServicePendingDeleteModel>())[0].decodeBase() == .versioned(31))
    #expect(try context.fetch(FetchDescriptor<ServiceRemoteStateModel>())[0].decodeRecord().changeSequence == 32)
    #expect(try context.fetch(FetchDescriptor<ServiceSyncConflictModel>())[0].decodeReason() == .baseChanged)
    #expect(try context.fetch(FetchDescriptor<ServiceSyncCursorModel>())[0].changeSequence == 32)
    #expect(try context.fetch(FetchDescriptor<ServiceSyncRetryModel>())[0].decodeState(for: fixture.serviceRetry.scope) == fixture.serviceRetry)
}

private let publishedTwentyOneModelSchema = Schema([
    ClientModel.self,
    ClientPendingUpsertModel.self,
    ClientPendingDeleteModel.self,
    ClientRemoteStateModel.self,
    ClientSyncConflictModel.self,
    ClientSyncCursorModel.self,
    ClientSyncRetryModel.self,
    ProductModel.self,
    ProductPendingUpsertModel.self,
    ProductPendingDeleteModel.self,
    ProductRemoteStateModel.self,
    ProductSyncConflictModel.self,
    ProductSyncCursorModel.self,
    ProductSyncRetryModel.self,
    ServiceModel.self,
    ServicePendingUpsertModel.self,
    ServicePendingDeleteModel.self,
    ServiceRemoteStateModel.self,
    ServiceSyncConflictModel.self,
    ServiceSyncCursorModel.self,
    ServiceSyncRetryModel.self
])

private func migrationUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
