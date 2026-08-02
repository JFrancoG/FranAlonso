import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Phase five schema migration plan")
struct PhaseFiveSchemaMigrationPlanTests {
    @Test("The plan starts at the persisted 05.10c baseline")
    func planStartsAtPersistedBaseline() {
        #expect(PhaseFiveSchemaMigrationPlan.schemas.count == 1)
        #expect(
            PhaseFiveBaselineSchema.versionIdentifier
                == Schema.Version(1, 0, 0)
        )
        #expect(PhaseFiveBaselineSchema.models.count == 28)
        #expect(PhaseFiveSchemaMigrationPlan.stages.isEmpty)
        #expect(rawCurrentSchema.version == Schema.Version(1, 0, 0))
        #expect(Schema.franAlonso.version == Schema.Version(1, 0, 0))
    }

    @Test("A raw 05.10c store adopts the plan with all 28 rows intact")
    func rawCurrentStoreAdoptsPlanWithoutDataLoss() throws {
        try withPhaseFiveMigrationStore { storeURL in
            let fixture: PhaseFiveMigrationFixture

            do {
                let container = try rawContainer(at: storeURL)
                let context = ModelContext(container)
                fixture = try insertRepresentativeRows(in: context)
                try context.save()
            }

            do {
                let container = try migratedCurrentContainer(at: storeURL)
                try verifyRepresentativeRows(
                    in: ModelContext(container),
                    fixture: fixture
                )
            }

            let reopened = try migratedCurrentContainer(at: storeURL)
            try verifyRepresentativeRows(
                in: ModelContext(reopened),
                fixture: fixture
            )
        }
    }
}

private struct PhaseFiveMigrationFixture {
    let client: ClientMigrationFixture
    let product: ProductMigrationFixture
    let service: ServiceMigrationFixture
    let sale: SaleMigrationFixture
}

private struct ClientMigrationFixture {
    let value: Client
    let upsert: ClientPendingUpsert
    let deletion: ClientPendingDelete
    let record: ClientRemoteRecord
    let retry: SyncRetryState
}

private struct ProductMigrationFixture {
    let value: Product
    let upsert: ProductPendingUpsert
    let deletion: ProductPendingDelete
    let record: ProductRemoteRecord
    let retry: SyncRetryState
}

private struct ServiceMigrationFixture {
    let value: Service
    let upsert: ServicePendingUpsert
    let deletion: ServicePendingDelete
    let record: ServiceRemoteRecord
    let retry: SyncRetryState
}

private struct SaleMigrationFixture {
    let value: Sale
    let upsert: SalePendingUpsert
    let discard: SalePendingDiscard
    let record: SaleRemoteRecord
    let retry: SyncRetryState
}

private let rawCurrentSchema = Schema([
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
    ServiceSyncRetryModel.self,
    SaleModel.self,
    SalePendingUpsertModel.self,
    SalePendingDiscardModel.self,
    SaleRemoteStateModel.self,
    SaleSyncConflictModel.self,
    SaleSyncCursorModel.self,
    SaleSyncRetryModel.self
])

private func rawContainer(at storeURL: URL) throws -> ModelContainer {
    let configuration = ModelConfiguration(
        "RawPhaseFiveTenC",
        schema: rawCurrentSchema,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: rawCurrentSchema,
        configurations: [configuration]
    )
}

private func migratedCurrentContainer(at storeURL: URL) throws -> ModelContainer {
    let configuration = ModelConfiguration(
        "MigratedPhaseFiveTenC",
        schema: .franAlonso,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: Schema.franAlonso,
        migrationPlan: PhaseFiveSchemaMigrationPlan.self,
        configurations: [configuration]
    )
}

private func withPhaseFiveMigrationStore(
    _ operation: (URL) throws -> Void
) throws {
    let directory = FileManager.default.temporaryDirectory.appending(
        path: "FranAlonso-05.11-\(UUID())",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(
        at: directory,
        withIntermediateDirectories: true
    )
    defer { try? FileManager.default.removeItem(at: directory) }
    try operation(directory.appending(path: "Migration.store"))
}

private func insertRepresentativeRows(in context: ModelContext) throws -> PhaseFiveMigrationFixture {
    PhaseFiveMigrationFixture(
        client: try insertClientRows(in: context),
        product: try insertProductRows(in: context),
        service: try insertServiceRows(in: context),
        sale: try insertSaleRows(in: context)
    )
}

private func insertClientRows(in context: ModelContext) throws -> ClientMigrationFixture {
    let client = Client.draft(
        id: ClientID(
            rawValue: phaseFiveMigrationUUID(
                "81000000-0000-0000-0000-000000000001"
            )
        ),
        displayName: "Baseline client"
    )
    let payload = ClientDTO(client)
    let upsertOperationID = phaseFiveMigrationUUID(
        "81000000-0000-0000-0000-000000000002"
    )
    let upsert = ClientPendingUpsert(
        clientID: client.id.rawValue,
        operationID: upsertOperationID,
        predecessorOperationID: nil,
        base: .versioned(10),
        client: payload
    )
    let deletion = ClientPendingDelete(
        clientID: client.id.rawValue,
        operationID: phaseFiveMigrationUUID(
            "81000000-0000-0000-0000-000000000003"
        ),
        predecessorOperationID: upsertOperationID,
        base: .versioned(11)
    )
    let record = ClientRemoteRecord(
        client: payload,
        version: .versioned(
            revision: 11,
            lastOperationID: upsertOperationID
        ),
        changeSequence: 12
    )
    let retry = try SyncRetryState(
        scope: .pull,
        backoffStep: 2,
        notBefore: Date(timeIntervalSinceReferenceDate: 810),
        lastRecoverableCategory: .unavailable
    )

    context.insert(ClientModel(client))
    context.insert(
        try ClientPendingUpsertModel(
            clientID: upsert.clientID,
            operationID: upsert.operationID,
            base: upsert.base,
            payload: upsert.client
        )
    )
    context.insert(
        try ClientPendingDeleteModel(
            clientID: deletion.clientID,
            operationID: deletion.operationID,
            predecessorOperationID: deletion.predecessorOperationID,
            base: deletion.base
        )
    )
    context.insert(try ClientRemoteStateModel(record: record))
    context.insert(
        try ClientSyncConflictModel(
            operation: upsert,
            reason: .baseChanged,
            remoteRecord: record
        )
    )
    context.insert(
        ClientSyncCursorModel(
            feedID: "clients",
            changeSequence: 12
        )
    )
    context.insert(ClientSyncRetryModel(retry))

    return ClientMigrationFixture(
        value: client,
        upsert: upsert,
        deletion: deletion,
        record: record,
        retry: retry
    )
}

private func insertProductRows(in context: ModelContext) throws -> ProductMigrationFixture {
    let product = Product.testSnapshot(
        id: ProductID(
            rawValue: phaseFiveMigrationUUID(
                "82000000-0000-0000-0000-000000000001"
            )
        ),
        name: "Baseline product"
    )
    let payload = ProductDTO(product)
    let upsertOperationID = phaseFiveMigrationUUID(
        "82000000-0000-0000-0000-000000000002"
    )
    let upsert = ProductPendingUpsert(
        productID: product.id.rawValue,
        operationID: upsertOperationID,
        predecessorOperationID: nil,
        base: .versioned(20),
        product: payload
    )
    let deletion = ProductPendingDelete(
        productID: product.id.rawValue,
        operationID: phaseFiveMigrationUUID(
            "82000000-0000-0000-0000-000000000003"
        ),
        predecessorOperationID: upsertOperationID,
        base: .versioned(21)
    )
    let record = ProductRemoteRecord(
        product: payload,
        version: .versioned(
            revision: 21,
            lastOperationID: upsertOperationID
        ),
        changeSequence: 22
    )
    let retry = try SyncRetryState(
        scope: .operation(upsertOperationID),
        backoffStep: 3,
        notBefore: Date(timeIntervalSinceReferenceDate: 820),
        lastRecoverableCategory: .deadlineExceeded
    )

    context.insert(ProductModel(product))
    context.insert(
        try ProductPendingUpsertModel(
            productID: upsert.productID,
            operationID: upsert.operationID,
            base: upsert.base,
            payload: upsert.product
        )
    )
    context.insert(
        try ProductPendingDeleteModel(
            productID: deletion.productID,
            operationID: deletion.operationID,
            predecessorOperationID: deletion.predecessorOperationID,
            base: deletion.base
        )
    )
    context.insert(try ProductRemoteStateModel(record: record))
    context.insert(
        try ProductSyncConflictModel(
            operation: upsert,
            reason: .baseChanged,
            remoteRecord: record
        )
    )
    context.insert(
        ProductSyncCursorModel(
            feedID: "products",
            changeSequence: 22
        )
    )
    context.insert(ProductSyncRetryModel(retry))

    return ProductMigrationFixture(
        value: product,
        upsert: upsert,
        deletion: deletion,
        record: record,
        retry: retry
    )
}

private func insertServiceRows(in context: ModelContext) throws -> ServiceMigrationFixture {
    let service = try makeService(
        id: phaseFiveMigrationUUID(
            "83000000-0000-0000-0000-000000000001"
        ),
        name: "Baseline service"
    )
    let payload = try ServiceDTO(service)
    let upsertOperationID = phaseFiveMigrationUUID(
        "83000000-0000-0000-0000-000000000002"
    )
    let upsert = ServicePendingUpsert(
        serviceID: service.id.rawValue,
        operationID: upsertOperationID,
        predecessorOperationID: nil,
        base: .versioned(30),
        service: payload
    )
    let deletion = ServicePendingDelete(
        serviceID: service.id.rawValue,
        operationID: phaseFiveMigrationUUID(
            "83000000-0000-0000-0000-000000000003"
        ),
        predecessorOperationID: upsertOperationID,
        base: .versioned(31)
    )
    let record = ServiceRemoteRecord(
        service: payload,
        version: .versioned(
            revision: 31,
            lastOperationID: upsertOperationID
        ),
        changeSequence: 32
    )
    let retry = try SyncRetryState(
        scope: .operation(upsertOperationID),
        backoffStep: 4,
        notBefore: Date(timeIntervalSinceReferenceDate: 830),
        lastRecoverableCategory: .aborted
    )

    context.insert(try ServiceModel(service))
    context.insert(
        try ServicePendingUpsertModel(
            serviceID: upsert.serviceID,
            operationID: upsert.operationID,
            base: upsert.base,
            payload: upsert.service
        )
    )
    context.insert(
        try ServicePendingDeleteModel(
            serviceID: deletion.serviceID,
            operationID: deletion.operationID,
            predecessorOperationID: deletion.predecessorOperationID,
            base: deletion.base
        )
    )
    context.insert(try ServiceRemoteStateModel(record: record))
    context.insert(
        try ServiceSyncConflictModel(
            operation: upsert,
            reason: .baseChanged,
            remoteRecord: record
        )
    )
    context.insert(
        ServiceSyncCursorModel(
            feedID: "services",
            changeSequence: 32
        )
    )
    context.insert(ServiceSyncRetryModel(retry))

    return ServiceMigrationFixture(
        value: service,
        upsert: upsert,
        deletion: deletion,
        record: record,
        retry: retry
    )
}

private func insertSaleRows(in context: ModelContext) throws -> SaleMigrationFixture {
    let sale = try representativeSale()
    let payload = try SaleDTO(sale)
    let upsertOperationID = phaseFiveMigrationUUID(
        "84000000-0000-0000-0000-000000000002"
    )
    let upsert = SalePendingUpsert(
        saleID: sale.id.rawValue,
        operationID: upsertOperationID,
        predecessorOperationID: nil,
        base: .versioned(40),
        sale: payload
    )
    let discard = SalePendingDiscard(
        saleID: sale.id.rawValue,
        operationID: phaseFiveMigrationUUID(
            "84000000-0000-0000-0000-000000000003"
        ),
        predecessorOperationID: upsertOperationID,
        base: .versioned(41)
    )
    let record = SaleRemoteRecord(
        sale: payload,
        version: .versioned(
            revision: 41,
            lastOperationID: upsertOperationID
        ),
        changeSequence: 42
    )
    let retry = try SyncRetryState(
        scope: .operation(upsertOperationID),
        backoffStep: 5,
        notBefore: Date(timeIntervalSinceReferenceDate: 840),
        lastRecoverableCategory: .unavailable
    )

    context.insert(try SaleModel(sale))
    context.insert(
        try SalePendingUpsertModel(
            saleID: upsert.saleID,
            operationID: upsert.operationID,
            base: upsert.base,
            payload: upsert.sale
        )
    )
    context.insert(
        try SalePendingDiscardModel(
            saleID: discard.saleID,
            operationID: discard.operationID,
            predecessorOperationID: discard.predecessorOperationID,
            base: discard.base
        )
    )
    context.insert(try SaleRemoteStateModel(record: record))
    context.insert(
        try SaleSyncConflictModel(
            operation: .upsert(upsert),
            reason: .baseChanged,
            remoteRecord: record
        )
    )
    context.insert(
        SaleSyncCursorModel(
            feedID: "sales",
            changeSequence: 42
        )
    )
    context.insert(SaleSyncRetryModel(retry))

    return SaleMigrationFixture(
        value: sale,
        upsert: upsert,
        discard: discard,
        record: record,
        retry: retry
    )
}

private func verifyRepresentativeRows(in context: ModelContext, fixture: PhaseFiveMigrationFixture) throws {
    try verifyClientRows(in: context, fixture: fixture.client)
    try verifyProductRows(in: context, fixture: fixture.product)
    try verifyServiceRows(in: context, fixture: fixture.service)
    try verifySaleRows(in: context, fixture: fixture.sale)
}

private func verifyClientRows(in context: ModelContext, fixture: ClientMigrationFixture) throws {
    #expect(
        try only(ClientModel.self, in: context).toDomain() == fixture.value
    )

    let upsert = try only(ClientPendingUpsertModel.self, in: context)
    #expect(upsert.clientID == fixture.upsert.clientID)
    #expect(upsert.operationID == fixture.upsert.operationID)
    #expect(
        upsert.predecessorOperationID
            == fixture.upsert.predecessorOperationID
    )
    #expect(try upsert.decodeBase() == fixture.upsert.base)
    #expect(try upsert.decodePayload() == fixture.upsert.client)

    let deletion = try only(ClientPendingDeleteModel.self, in: context)
    #expect(deletion.clientID == fixture.deletion.clientID)
    #expect(deletion.operationID == fixture.deletion.operationID)
    #expect(
        deletion.predecessorOperationID
            == fixture.deletion.predecessorOperationID
    )
    #expect(try deletion.decodeBase() == fixture.deletion.base)

    #expect(
        try only(ClientRemoteStateModel.self, in: context).decodeRecord()
            == fixture.record
    )

    let conflict = try only(ClientSyncConflictModel.self, in: context)
    #expect(conflict.clientID == fixture.upsert.clientID)
    #expect(conflict.operationID == fixture.upsert.operationID)
    #expect(try conflict.decodeReason() == .baseChanged)
    #expect(try conflict.decodeBase() == fixture.upsert.base)
    #expect(try conflict.decodeLocalClient() == fixture.upsert.client)
    #expect(try conflict.decodeRemoteRecord() == fixture.record)

    let cursor = try only(ClientSyncCursorModel.self, in: context)
    #expect(cursor.feedID == "clients")
    #expect(cursor.changeSequence == fixture.record.changeSequence)
    #expect(
        try only(ClientSyncRetryModel.self, in: context).decodeState(
            for: fixture.retry.scope
        ) == fixture.retry
    )
}

private func verifyProductRows(in context: ModelContext, fixture: ProductMigrationFixture) throws {
    #expect(
        try only(ProductModel.self, in: context).toDomain() == fixture.value
    )

    let upsert = try only(ProductPendingUpsertModel.self, in: context)
    #expect(upsert.productID == fixture.upsert.productID)
    #expect(upsert.operationID == fixture.upsert.operationID)
    #expect(
        upsert.predecessorOperationID
            == fixture.upsert.predecessorOperationID
    )
    #expect(try upsert.decodeBase() == fixture.upsert.base)
    #expect(try upsert.decodePayload() == fixture.upsert.product)

    let deletion = try only(ProductPendingDeleteModel.self, in: context)
    #expect(deletion.productID == fixture.deletion.productID)
    #expect(deletion.operationID == fixture.deletion.operationID)
    #expect(
        deletion.predecessorOperationID
            == fixture.deletion.predecessorOperationID
    )
    #expect(try deletion.decodeBase() == fixture.deletion.base)

    #expect(
        try only(ProductRemoteStateModel.self, in: context).decodeRecord()
            == fixture.record
    )

    let conflict = try only(ProductSyncConflictModel.self, in: context)
    #expect(conflict.productID == fixture.upsert.productID)
    #expect(conflict.operationID == fixture.upsert.operationID)
    #expect(try conflict.decodeReason() == .baseChanged)
    #expect(try conflict.decodeBase() == fixture.upsert.base)
    #expect(try conflict.decodeLocalProduct() == fixture.upsert.product)
    #expect(try conflict.decodeRemoteRecord() == fixture.record)

    let cursor = try only(ProductSyncCursorModel.self, in: context)
    #expect(cursor.feedID == "products")
    #expect(cursor.changeSequence == fixture.record.changeSequence)
    #expect(
        try only(ProductSyncRetryModel.self, in: context).decodeState(
            for: fixture.retry.scope
        ) == fixture.retry
    )
}

private func verifyServiceRows(in context: ModelContext, fixture: ServiceMigrationFixture) throws {
    #expect(
        try only(ServiceModel.self, in: context).toDomain() == fixture.value
    )

    let upsert = try only(ServicePendingUpsertModel.self, in: context)
    #expect(upsert.serviceID == fixture.upsert.serviceID)
    #expect(upsert.operationID == fixture.upsert.operationID)
    #expect(
        upsert.predecessorOperationID
            == fixture.upsert.predecessorOperationID
    )
    #expect(try upsert.decodeBase() == fixture.upsert.base)
    #expect(try upsert.decodePayload() == fixture.upsert.service)

    let deletion = try only(ServicePendingDeleteModel.self, in: context)
    #expect(deletion.serviceID == fixture.deletion.serviceID)
    #expect(deletion.operationID == fixture.deletion.operationID)
    #expect(
        deletion.predecessorOperationID
            == fixture.deletion.predecessorOperationID
    )
    #expect(try deletion.decodeBase() == fixture.deletion.base)

    #expect(
        try only(ServiceRemoteStateModel.self, in: context).decodeRecord()
            == fixture.record
    )

    let conflict = try only(ServiceSyncConflictModel.self, in: context)
    #expect(conflict.serviceID == fixture.upsert.serviceID)
    #expect(conflict.operationID == fixture.upsert.operationID)
    #expect(try conflict.decodeReason() == .baseChanged)
    #expect(try conflict.decodeBase() == fixture.upsert.base)
    #expect(try conflict.decodeLocalService() == fixture.upsert.service)
    #expect(try conflict.decodeRemoteRecord() == fixture.record)

    let cursor = try only(ServiceSyncCursorModel.self, in: context)
    #expect(cursor.feedID == "services")
    #expect(cursor.changeSequence == fixture.record.changeSequence)
    #expect(
        try only(ServiceSyncRetryModel.self, in: context).decodeState(
            for: fixture.retry.scope
        ) == fixture.retry
    )
}

private func verifySaleRows(in context: ModelContext, fixture: SaleMigrationFixture) throws {
    #expect(
        try only(SaleModel.self, in: context).toDomain() == fixture.value
    )

    let upsert = try only(SalePendingUpsertModel.self, in: context)
    #expect(upsert.saleID == fixture.upsert.saleID)
    #expect(upsert.operationID == fixture.upsert.operationID)
    #expect(
        upsert.predecessorOperationID
            == fixture.upsert.predecessorOperationID
    )
    #expect(try upsert.decodeBase() == fixture.upsert.base)
    #expect(try upsert.decodePayload() == fixture.upsert.sale)

    let discard = try only(SalePendingDiscardModel.self, in: context)
    #expect(discard.saleID == fixture.discard.saleID)
    #expect(discard.operationID == fixture.discard.operationID)
    #expect(
        discard.predecessorOperationID
            == fixture.discard.predecessorOperationID
    )
    #expect(try discard.decodeBase() == fixture.discard.base)

    #expect(
        try only(SaleRemoteStateModel.self, in: context).decodeRecord()
            == fixture.record
    )

    let conflict = try only(SaleSyncConflictModel.self, in: context)
    #expect(try conflict.decodeReason() == .baseChanged)
    #expect(try conflict.decodeOperation() == .upsert(fixture.upsert))
    #expect(try conflict.decodeRemoteRecord() == fixture.record)

    let cursor = try only(SaleSyncCursorModel.self, in: context)
    #expect(cursor.feedID == "sales")
    #expect(cursor.changeSequence == fixture.record.changeSequence)
    #expect(
        try only(SaleSyncRetryModel.self, in: context).decodeState(
            for: fixture.retry.scope
        ) == fixture.retry
    )
}

private func only<Model: PersistentModel>(_ type: Model.Type, in context: ModelContext) throws -> Model {
    let models = try context.fetch(FetchDescriptor<Model>())
    #expect(models.count == 1)
    return try #require(models.first)
}

private func representativeSale() throws -> Sale {
    let line = try SaleLine.upcoming(
        id: SaleLineID(
            rawValue: phaseFiveMigrationUUID(
                "84000000-0000-0000-0000-000000000010"
            )
        ),
        serviceID: ServiceID(
            rawValue: phaseFiveMigrationUUID(
                "84000000-0000-0000-0000-000000000011"
            )
        ),
        serviceName: "Baseline sale snapshot",
        quantity: 2,
        unitPrice: Money(amount: 29.95, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: Discount(percentage: 10),
        linkedProductID: nil
    )
    return try Sale.draft(
        id: SaleID(
            rawValue: phaseFiveMigrationUUID(
                "84000000-0000-0000-0000-000000000001"
            )
        ),
        clientID: ClientID(
            rawValue: phaseFiveMigrationUUID(
                "84000000-0000-0000-0000-000000000012"
            )
        ),
        createdAt: Date(
            timeIntervalSinceReferenceDate: 0.000_000_123_456_789
        ),
        lines: [line]
    )
}

private func phaseFiveMigrationUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
