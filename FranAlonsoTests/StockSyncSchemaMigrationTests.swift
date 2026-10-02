import Foundation
import SwiftData
import Testing

@testable import FranAlonso

@Suite("Stock sync schema migration")
@MainActor
struct StockSyncSchemaMigrationTests {
    @Test
    func `raw v1 preserves all data and accepts a durable ledger`() async throws {
        try await verifyHistoricalStore(version: 1)
    }

    @Test
    func `raw v2 preserves documents and accepts a durable ledger`() async throws {
        try await verifyHistoricalStore(version: 2)
    }

    @Test
    func `raw v3 preserves manual and sale ledger pending bytes`() async throws {
        try await verifyHistoricalStore(version: 3)
    }

    private func verifyHistoricalStore(version: Int) async throws {
        let documentSnapshot = try await ClientDocumentTestFixtures.snapshot()
        let signedDocument = try await ClientDocumentTestFixtures.render(documentSnapshot)
        let draft = try ClientDocumentDraft(
            .init(
                id: UUID(),
                clientID: ClientDocumentTestFixtures.clientID,
                profile: ClientProfile(displayName: "Historical draft"),
                snapshot: nil,
                binding: nil,
                signedAt: nil,
                revision: 3
            )
        )
        let legacyReference = try ClientConsentReference(rawValue: "legacy/consents/retained.pdf")
        try withPhaseFiveMigrationStore { storeURL in
            let fixture: PhaseFiveMigrationFixture
            let payloads: [String: ClientDocumentsMigrationPayload]
            let documents: StockSyncMigrationDocumentPayload?
            var ledger: [UUID: Data] = [:]
            weak var releasedContainer: ModelContainer?
            let eligible = Product(id: ProductID(rawValue: UUID()), name: "Inventory", status: .inactive)
            let id = StockMovementID(rawValue: UUID())
            let movement = try StockMovement(
                id: id,
                productID: eligible.id,
                quantityDelta: -4,
                reason: "Physical count",
                occurredAt: Date(timeIntervalSinceReferenceDate: 950),
                origin: .manual(reference: id)
            )
            do {
                let schema =
                    version == 1
                    ? Schema(PhaseFiveBaselineSchema.models, version: Schema.Version(1, 0, 0))
                    : version == 2
                        ? Schema(ClientDocumentsSchema.models, version: Schema.Version(2, 0, 0))
                        : Schema(StockMovementsSchema.models, version: Schema.Version(3, 0, 0))
                let container = try stockSyncMigrationContainer(schema: schema, at: storeURL, migrate: false)
                releasedContainer = container
                let context = ModelContext(container)
                fixture = try insertPhaseFiveMigrationRows(
                    in: context,
                    clientStatus: .active(consentReference: legacyReference)
                )
                context.insert(ProductModel(eligible))
                if version >= 2 {
                    context.insert(try ClientDocumentDraftModel(draft))
                    let signed = try ClientSignedDocumentModel(draftID: draft.id, document: signedDocument)
                    try signed.setState(
                        .uploaded(
                            ClientDocumentUploadReceipt(
                                documentID: signedDocument.id,
                                principalID: "migration-principal",
                                reference: ClientConsentReference(rawValue: "synthetic/retained-document")
                            )
                        )
                    )
                    signed.attemptCount = 2
                    signed.lastAttemptAt = Date(timeIntervalSinceReferenceDate: 850)
                    context.insert(signed)
                }
                if version == 3 {
                    context.insert(try StockMovementModel(movement))
                    let saleEvent = try StockMovement(
                        id: StockMovementID(rawValue: UUID()),
                        productID: eligible.id,
                        quantityDelta: -2,
                        reason: "Historical payment",
                        occurredAt: Date(timeIntervalSinceReferenceDate: 951),
                        origin: .sale(
                            saleID: SaleID(rawValue: UUID()),
                            lineID: SaleLineID(rawValue: UUID()),
                            paymentID: PaymentID(rawValue: UUID())
                        )
                    )
                    context.insert(try StockMovementModel(saleEvent))
                    ledger = try Dictionary(
                        uniqueKeysWithValues: context.fetch(FetchDescriptor<StockMovementModel>()).map {
                            ($0.id, $0.payloadData)
                        }
                    )
                }
                try context.save()
                payloads = try preservedPayloads(in: context)
                documents = version >= 2 ? try stockSyncMigrationDocuments(in: context) : nil
            }
            #expect(releasedContainer == nil)
            do {
                let container = try stockSyncMigrationContainer(at: storeURL)
                releasedContainer = container
                let context = ModelContext(container)
                try verifyStockSyncMigrationBaseline(in: context, fixture: fixture, eligible: eligible)
                #expect(try preservedPayloads(in: context) == payloads)
                #expect(try context.fetch(FetchDescriptor<StockMovementModel>()).count == (version == 3 ? 2 : 0))
                for row in try context.fetch(FetchDescriptor<StockMovementModel>()) {
                    #expect(row.payloadData == ledger[row.id])
                    #expect(row.isPendingSync)
                }
                #expect(try context.fetchCount(FetchDescriptor<StockRemoteStateModel>()) == 0)
                #expect(try context.fetchCount(FetchDescriptor<StockSyncConflictModel>()) == 0)
                #expect(try context.fetchCount(FetchDescriptor<StockSyncCursorModel>()) == 0)
                #expect(try context.fetchCount(FetchDescriptor<StockSyncRetryModel>()) == 0)
                try verifyStockSyncMigrationDocuments(documents, in: context)
                let source = StockLocalDataSource()
                #expect(try source.append(movement, in: context) == movement)
                #expect(try source.quantity(for: eligible.id, in: context) == (version == 3 ? -6 : -4))
            }
            #expect(releasedContainer == nil)
            let reopened = try stockSyncMigrationContainer(at: storeURL)
            let context = ModelContext(reopened)
            try verifyStockSyncMigrationBaseline(in: context, fixture: fixture, eligible: eligible)
            #expect(try preservedPayloads(in: context) == payloads)
            try verifyStockSyncMigrationDocuments(documents, in: context)
            let source = StockLocalDataSource()
            #expect(try source.append(movement, in: context) == movement)
            let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
            #expect(rows.count == (version == 3 ? 2 : 1))
            let row = try #require(rows.first { $0.id == movement.id.rawValue })
            for item in rows where version == 3 {
                #expect(item.payloadData == ledger[item.id])
                #expect(item.isPendingSync)
            }
            #expect(try row.toDomain() == movement)
            #expect(row.isPendingSync)
            #expect(try source.quantity(for: eligible.id, in: context) == (version == 3 ? -6 : -4))
        }
    }

    @Test
    func `unknown store is rejected and original bytes remain readable`() throws {
        try withPhaseFiveMigrationStore { storeURL in
            let schema = Schema([ProductModel.self])
            let product = Product(id: ProductID(rawValue: UUID()), name: "Must survive", status: .inactive)
            do {
                let container = try stockSyncMigrationContainer(schema: schema, at: storeURL, migrate: false)
                let context = ModelContext(container)
                context.insert(ProductModel(product))
                try context.save()
            }
            #expect(throws: (any Error).self) {
                try stockSyncMigrationContainer(at: storeURL)
            }
            let reopened = try stockSyncMigrationContainer(schema: schema, at: storeURL, migrate: false)
            let rows = try ModelContext(reopened).fetch(FetchDescriptor<ProductModel>())
            #expect(rows.count == 1)
            #expect(try #require(rows.first).toDomain() == product)
        }
    }
}

private struct StockSyncMigrationDocumentPayload: Equatable {
    let draftID: UUID
    let draftClientID: UUID
    let draftRevision: Int
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

private func stockSyncMigrationDocuments(in context: ModelContext) throws -> StockSyncMigrationDocumentPayload {
    let drafts = try context.fetch(FetchDescriptor<ClientDocumentDraftModel>())
    let documents = try context.fetch(FetchDescriptor<ClientSignedDocumentModel>())
    try #require(drafts.count == 1 && documents.count == 1)
    let draft = try #require(drafts.first)
    let document = try #require(documents.first)
    _ = try draft.toDomain()
    _ = try document.toDomain()
    return StockSyncMigrationDocumentPayload(
        draftID: draft.id,
        draftClientID: draft.clientID,
        draftRevision: draft.revision,
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

private func verifyStockSyncMigrationDocuments(
    _ expected: StockSyncMigrationDocumentPayload?,
    in context: ModelContext
) throws {
    if let expected {
        #expect(try stockSyncMigrationDocuments(in: context) == expected)
    } else {
        #expect(try context.fetch(FetchDescriptor<ClientDocumentDraftModel>()).isEmpty)
        #expect(try context.fetch(FetchDescriptor<ClientSignedDocumentModel>()).isEmpty)
    }
}

private func verifyStockSyncMigrationBaseline(
    in context: ModelContext,
    fixture: PhaseFiveMigrationFixture,
    eligible: Product
) throws {
    let id = eligible.id.rawValue
    let rows = try context.fetch(FetchDescriptor<ProductModel>(predicate: #Predicate { $0.id == id }))
    #expect(try #require(rows.first).toDomain() == eligible)
    try verifyPhaseFiveMigrationRows(in: context, fixture: fixture, additionalProducts: [eligible])
}

private func stockSyncMigrationContainer(
    schema: Schema = Schema(versionedSchema: StockSyncSchema.self),
    at storeURL: URL,
    migrate: Bool = true
) throws -> ModelContainer {
    let configuration = ModelConfiguration(
        "StockSyncMigration",
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
