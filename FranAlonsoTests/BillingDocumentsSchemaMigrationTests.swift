import Foundation
import SwiftData
import Testing

@testable import FranAlonso

@Suite("Billing documents schema migration")
@MainActor
struct BillingDocumentsSchemaMigrationTests {
    @Test(arguments: [1, 2, 3, 4])
    func `raw supported store preserves every historical payload across two billing reopens`(
        version: Int
    ) async throws {
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        let signedDocument = try await ClientDocumentTestFixtures.render(snapshot)
        let draft = try ClientDocumentDraft(.init(
            id: UUID(),
            clientID: ClientDocumentTestFixtures.clientID,
            profile: ClientProfile(displayName: "Retained historical draft"),
            snapshot: nil,
            binding: nil,
            signedAt: nil,
            revision: 3
        ))
        let legacy = try ClientConsentReference(rawValue: "legacy/consents/retained.pdf")
        let delivery = try BillingDocumentDelivery(
            request: billingTransactionRequest(index: 1310),
            principalID: "billing-migration-principal"
        )
        try withPhaseFiveMigrationStore { storeURL in
            let fixture: PhaseFiveMigrationFixture
            let payloads: [String: ClientDocumentsMigrationPayload]
            let artifacts: BillingMigrationClientArtifacts?
            let ledger: [UUID: BillingMigrationLedgerRow]
            let sync: BillingMigrationStockMetadata?
            let billingBytes: Data
            weak var releasedContainer: ModelContainer?
            do {
                let container = try billingMigrationContainer(
                    schema: billingMigrationRawSchema(version: version),
                    at: storeURL,
                    migrate: false
                )
                releasedContainer = container
                let context = ModelContext(container)
                context.autosaveEnabled = false
                fixture = try insertPhaseFiveMigrationRows(in: context, clientStatus: .active(consentReference: legacy))
                if version >= 2 {
                    context.insert(try ClientDocumentDraftModel(draft))
                    let model = try ClientSignedDocumentModel(draftID: draft.id, document: signedDocument)
                    try model.setState(.uploaded(ClientDocumentUploadReceipt(
                        documentID: signedDocument.id,
                        principalID: "client-migration-principal",
                        reference: ClientConsentReference(rawValue: "synthetic/retained-client-artifact")
                    )))
                    model.attemptCount = 3
                    model.lastAttemptAt = Date(timeIntervalSinceReferenceDate: 850)
                    context.insert(model)
                }
                if version >= 3 {
                    try insertBillingMigrationLedger(in: context, productID: fixture.product.value.id)
                }
                if version == 4 {
                    try insertBillingMigrationStockMetadata(in: context)
                }
                try context.save()
                payloads = try preservedPayloads(in: context)
                artifacts = version >= 2 ? try billingMigrationClientArtifacts(in: context) : nil
                ledger = version >= 3 ? try billingMigrationLedger(in: context) : [:]
                sync = version == 4 ? try billingMigrationStockMetadata(in: context) : nil
            }
            try #require(releasedContainer == nil)
            do {
                let container = try billingMigrationContainer(at: storeURL)
                releasedContainer = container
                let context = ModelContext(container)
                context.autosaveEnabled = false
                try verifyBillingMigrationHistory(
                    in: context,
                    fixture: fixture,
                    payloads: payloads,
                    artifacts: artifacts,
                    ledger: ledger,
                    sync: sync
                )
                #expect(try context.fetchCount(FetchDescriptor<BillingDocumentDeliveryModel>()) == 0)
                let model = try BillingDocumentDeliveryModel(delivery)
                billingBytes = model.payload
                context.insert(model)
                try context.save()
                let independent = ModelContext(container)
                independent.autosaveEnabled = false
                let rows = try independent.fetch(FetchDescriptor<BillingDocumentDeliveryModel>())
                try #require(rows.count == 1)
                #expect(try #require(rows.first).toDomain() == delivery)
            }
            try #require(releasedContainer == nil)
            do {
                let container = try billingMigrationContainer(at: storeURL)
                releasedContainer = container
                let context = ModelContext(container)
                context.autosaveEnabled = false
                try verifyBillingMigrationHistory(
                    in: context,
                    fixture: fixture,
                    payloads: payloads,
                    artifacts: artifacts,
                    ledger: ledger,
                    sync: sync
                )
                let rows = try context.fetch(FetchDescriptor<BillingDocumentDeliveryModel>())
                try #require(rows.count == 1)
                let model = try #require(rows.first)
                #expect(model.payload == billingBytes)
                #expect(try model.toDomain() == delivery)
            }
            try #require(releasedContainer == nil)
        }
    }

    @Test
    func `unknown origin fails closed and remains readable without reset`() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(
            path: "FranAlonso-BillingUnknownOrigin-\(UUID())",
            directoryHint: .isDirectory
        )
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let storeURL = directory.appending(path: "Migration.store")
        let origin = Schema([ProductModel.self])
        let product = Product(id: ProductID(rawValue: UUID()), name: "Must survive", status: .inactive)
        weak var releasedContainer: ModelContainer?
        // Drain SwiftData bridge temporaries before proving each disk owner has been released.
        try autoreleasepool {
            try writeUnknownBillingMigrationOrigin(
                schema: origin,
                at: storeURL,
                product: product
            ) {
                releasedContainer = $0
            }
        }
        await allowBillingMigrationOwnerTeardown { releasedContainer == nil }
        try #require(releasedContainer == nil)
        #expect(throws: (any Error).self) {
            try autoreleasepool {
                let container = try billingMigrationContainer(at: storeURL)
                releasedContainer = container
            }
        }
        await allowBillingMigrationOwnerTeardown { releasedContainer == nil }
        try #require(releasedContainer == nil)
        try autoreleasepool {
            let restored = try readUnknownBillingMigrationOrigin(
                schema: origin,
                at: storeURL
            ) {
                releasedContainer = $0
            }
            #expect(restored == product)
        }
        await allowBillingMigrationOwnerTeardown { releasedContainer == nil }
        try #require(releasedContainer == nil)
    }
}

@MainActor
private func allowBillingMigrationOwnerTeardown(
    isReleased: () -> Bool
) async {
    // Teardown may be queued internally; the caller still requires actual release before every reopen.
    for _ in 0..<128 {
        guard !isReleased() else { return }
        await Task.yield()
    }
}

@MainActor
private func writeUnknownBillingMigrationOrigin(
    schema: Schema,
    at storeURL: URL,
    product: Product,
    observeOwner: (ModelContainer) -> Void
) throws {
    let container = try billingMigrationContainer(schema: schema, at: storeURL, migrate: false)
    observeOwner(container)
    let context = ModelContext(container)
    context.autosaveEnabled = false
    let model = ProductModel(product)
    context.insert(model)
    try context.save()
}

@MainActor
private func readUnknownBillingMigrationOrigin(
    schema: Schema,
    at storeURL: URL,
    observeOwner: (ModelContainer) -> Void
) throws -> Product {
    let container = try billingMigrationContainer(schema: schema, at: storeURL, migrate: false)
    observeOwner(container)
    let context = ModelContext(container)
    context.autosaveEnabled = false
    let rows = try context.fetch(FetchDescriptor<ProductModel>())
    try #require(rows.count == 1)
    return try #require(rows.first).toDomain()
}

private struct BillingMigrationClientArtifacts: Equatable {
    let draftID: UUID
    let clientID: UUID
    let revision: Int
    let draftVersion: Int
    let draftBytes: Data
    let documentID: UUID
    let documentClientID: UUID
    let documentDraftID: UUID
    let documentVersion: Int
    let documentBytes: Data
    let stateBytes: Data
    let attempts: Int
    let lastAttempt: Date?
}

private struct BillingMigrationLedgerRow: Equatable {
    let productID: UUID
    let payloadVersion: Int
    let bytes: Data
    let isPending: Bool
}

private struct BillingMigrationStockMetadata: Equatable {
    let movementID: UUID
    let remoteVersion: Int
    let remoteBytes: Data
    let conflictID: UUID
    let conflictVersion: Int
    let conflictBytes: Data
    let feedID: String
    let cursor: Int64
    let retryScope: String
    let backoffStep: Int
    let notBefore: Date
    let category: String
}

private func billingMigrationRawSchema(version: Int) -> Schema {
    let models: [any PersistentModel.Type]
    switch version {
    case 1: models = PhaseFiveBaselineSchema.models
    case 2: models = ClientDocumentsSchema.models
    case 3: models = StockMovementsSchema.models
    default: models = StockSyncSchema.models
    }
    return Schema(models, version: Schema.Version(version, 0, 0))
}

private func billingMigrationContainer(
    schema: Schema = Schema(versionedSchema: BillingDocumentsSchema.self),
    at storeURL: URL,
    migrate: Bool = true
) throws -> ModelContainer {
    let configuration = ModelConfiguration(
        "BillingDocumentsMigration",
        schema: schema,
        url: storeURL,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: schema,
        migrationPlan: migrate ? PhaseFiveSchemaMigrationPlan.self : nil,
        configurations: [configuration]
    )
}

private func insertBillingMigrationLedger(in context: ModelContext, productID: ProductID) throws {
    let id = StockMovementID(rawValue: UUID())
    let manual = try StockMovement(
        id: id,
        productID: productID,
        quantityDelta: -4,
        reason: "Historical physical count",
        occurredAt: Date(timeIntervalSinceReferenceDate: 950),
        origin: .manual(reference: id)
    )
    context.insert(try StockMovementModel(manual))
    let sale = try StockMovement(
        id: StockMovementID(rawValue: UUID()),
        productID: productID,
        quantityDelta: -2,
        reason: "Historical payment",
        occurredAt: Date(timeIntervalSinceReferenceDate: 951),
        origin: .sale(
            saleID: SaleID(rawValue: UUID()),
            lineID: SaleLineID(rawValue: UUID()),
            paymentID: PaymentID(rawValue: UUID())
        )
    )
    let model = try StockMovementModel(sale)
    model.acknowledgeSync()
    context.insert(model)
}

private func insertBillingMigrationStockMetadata(in context: ModelContext) throws {
    let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
    let model = try #require(rows.first { !$0.isPendingSync })
    let movement = try model.toDomain()
    let divergent = try StockMovement(
        id: movement.id,
        productID: movement.productID,
        quantityDelta: -3,
        reason: movement.reason,
        occurredAt: movement.occurredAt,
        origin: movement.origin
    )
    let remote = StockRemoteRecord(
        movement: try StockMovementDTO(divergent),
        revision: 1,
        operationID: movement.id.rawValue,
        changeSequence: 53
    )
    let conflict = try StockSyncConflict(local: StockMovementDTO(movement), remote: remote)
    context.insert(StockRemoteStateModel(
        movementID: model.id,
        payloadVersion: 1,
        recordData: try JSONEncoder().encode(remote)
    ))
    context.insert(StockSyncConflictModel(
        movementID: model.id,
        payloadVersion: 1,
        conflictData: try JSONEncoder().encode(conflict)
    ))
    context.insert(StockSyncCursorModel(feedID: "stock", changeSequence: 53))
    context.insert(StockSyncRetryModel(try SyncRetryState(
        scope: .operation(model.id),
        backoffStep: 4,
        notBefore: Date(timeIntervalSinceReferenceDate: 952),
        lastRecoverableCategory: .deadlineExceeded
    )))
}

private func billingMigrationClientArtifacts(in context: ModelContext) throws -> BillingMigrationClientArtifacts {
    let drafts = try context.fetch(FetchDescriptor<ClientDocumentDraftModel>())
    let documents = try context.fetch(FetchDescriptor<ClientSignedDocumentModel>())
    try #require(drafts.count == 1 && documents.count == 1)
    let draft = try #require(drafts.first)
    let document = try #require(documents.first)
    _ = try draft.toDomain()
    _ = try document.toDomain()
    return BillingMigrationClientArtifacts(
        draftID: draft.id,
        clientID: draft.clientID,
        revision: draft.revision,
        draftVersion: draft.payloadVersion,
        draftBytes: draft.payload,
        documentID: document.id,
        documentClientID: document.clientID,
        documentDraftID: document.draftID,
        documentVersion: document.payloadVersion,
        documentBytes: document.documentPayload,
        stateBytes: document.statePayload,
        attempts: document.attemptCount,
        lastAttempt: document.lastAttemptAt
    )
}

private func billingMigrationLedger(in context: ModelContext) throws -> [UUID: BillingMigrationLedgerRow] {
    try Dictionary(uniqueKeysWithValues: context.fetch(FetchDescriptor<StockMovementModel>()).map { model in
        _ = try model.toDomain()
        return (model.id, BillingMigrationLedgerRow(
            productID: model.productID,
            payloadVersion: model.payloadVersion,
            bytes: model.payloadData,
            isPending: model.isPendingSync
        ))
    })
}

private func billingMigrationStockMetadata(in context: ModelContext) throws -> BillingMigrationStockMetadata {
    let remote = try context.fetch(FetchDescriptor<StockRemoteStateModel>())
    let conflicts = try context.fetch(FetchDescriptor<StockSyncConflictModel>())
    let cursors = try context.fetch(FetchDescriptor<StockSyncCursorModel>())
    let retries = try context.fetch(FetchDescriptor<StockSyncRetryModel>())
    try #require(remote.count == 1 && conflicts.count == 1 && cursors.count == 1 && retries.count == 1)
    let accepted = try #require(remote.first)
    let conflict = try #require(conflicts.first)
    let cursor = try #require(cursors.first)
    let retry = try #require(retries.first)
    return BillingMigrationStockMetadata(
        movementID: accepted.movementID,
        remoteVersion: accepted.payloadVersion,
        remoteBytes: accepted.recordData,
        conflictID: conflict.movementID,
        conflictVersion: conflict.payloadVersion,
        conflictBytes: conflict.conflictData,
        feedID: cursor.feedID,
        cursor: cursor.changeSequence,
        retryScope: retry.scopeID,
        backoffStep: retry.backoffStep,
        notBefore: retry.notBefore,
        category: retry.lastRecoverableCategoryRawValue
    )
}

private func verifyBillingMigrationHistory(
    in context: ModelContext,
    fixture: PhaseFiveMigrationFixture,
    payloads: [String: ClientDocumentsMigrationPayload],
    artifacts: BillingMigrationClientArtifacts?,
    ledger: [UUID: BillingMigrationLedgerRow],
    sync: BillingMigrationStockMetadata?
) throws {
    try verifyPhaseFiveMigrationRows(in: context, fixture: fixture)
    #expect(try preservedPayloads(in: context) == payloads)
    #expect(try billingMigrationLedger(in: context) == ledger)
    if let artifacts {
        #expect(try billingMigrationClientArtifacts(in: context) == artifacts)
    } else {
        #expect(try context.fetchCount(FetchDescriptor<ClientDocumentDraftModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<ClientSignedDocumentModel>()) == 0)
    }
    if let sync {
        #expect(try billingMigrationStockMetadata(in: context) == sync)
    } else {
        #expect(try context.fetchCount(FetchDescriptor<StockRemoteStateModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<StockSyncConflictModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<StockSyncCursorModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<StockSyncRetryModel>()) == 0)
    }
}
