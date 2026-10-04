import Foundation
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
        "A sole document row denies a missing binding before secure claim",
        arguments: [LocalDocumentRow.draft, .pendingDocument, .uploadedDocument]
    )
    fileprivate func soleDocumentRowDeniesMissingBindingBeforeSecureClaim(_ row: LocalDocumentRow) async throws {
        let schema = Schema(versionedSchema: ClientDocumentsSchema.self)
        let container = try ModelContainer.inMemory(for: schema)
        try await insertDocumentRow(row, in: container.mainContext)
        try container.mainContext.save()
        let dataSource = SwiftDataStorePristineDataSource(modelContainer: container)
        let secureClaims = DocumentStoreSecureClaims()
        let binding = KeychainLocalPrincipalDataSource(
            readBinding: { .missing },
            addBinding: { _ in await secureClaims.add() },
            isStorePristine: { try await dataSource.isPristine() }
        )
        let useCase = AuthorizeLocalPrincipalUseCase(authorizer: LocalPrincipalAuthorizer { session in
            try await binding.authorize(principalID: session.id)
        })

        #expect(try await !dataSource.isPristine())
        await #expect(throws: LocalPrincipalAuthorizationError.localStoreNotPristine) {
            try await useCase(session: AuthenticationSession(id: "document-store-principal"))
        }
        #expect(await secureClaims.count == 0)
    }

    @Test("A sole stock movement denies an unbound store without claiming the secure binding")
    func soleStockMovementDeniesMissingBindingBeforeSecureClaim() async throws {
        let container = try ModelContainer.inMemory(for: Schema(versionedSchema: StockMovementsSchema.self))
        let id = StockMovementID(rawValue: UUID())
        let movement = try StockMovement(
            id: id,
            productID: ProductID(rawValue: UUID()),
            quantityDelta: 1,
            reason: "Orphan ledger row",
            occurredAt: Date(timeIntervalSinceReferenceDate: 95),
            origin: .manual(reference: id)
        )
        container.mainContext.insert(try StockMovementModel(movement))
        try container.mainContext.save()
        let inspector = SwiftDataStorePristineDataSource(modelContainer: container)
        let claims = DocumentStoreSecureClaims()
        let binding = KeychainLocalPrincipalDataSource(
            readBinding: { .missing },
            addBinding: { _ in await claims.add() },
            isStorePristine: { try await inspector.isPristine() }
        )
        let useCase = AuthorizeLocalPrincipalUseCase(authorizer: LocalPrincipalAuthorizer { session in
            try await binding.authorize(principalID: session.id)
        })

        #expect(try await !inspector.isPristine())
        await #expect(throws: LocalPrincipalAuthorizationError.localStoreNotPristine) {
            try await useCase(session: AuthenticationSession(id: "stock-store-principal"))
        }
        #expect(await claims.count == 0)
    }

    @Test("Any persisted feature metadata makes the store non-pristine", arguments: LocalStoreFeature.allCases)
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

    @Test(
        "A sole billing or stock metadata row denies claim before secure storage is written",
        arguments: [
            LocalPublishedRow.billing,
            .stockRemote,
            .stockConflict,
            .stockCursor,
            .stockRetry
        ]
    )
    fileprivate func solePublishedRowDeniesClaimBeforeSecureWrite(_ row: LocalPublishedRow) async throws {
        let container = try ModelContainer.inMemory(for: Schema(versionedSchema: BillingDocumentsSchema.self))
        let context = container.mainContext
        let id = try #require(UUID(uuidString: "13100000-0000-0000-0000-000000000001"))
        switch row {
        case .billing:
            let delivery = try BillingDocumentDelivery(
                request: billingTransactionRequest(index: 1310),
                principalID: "existing-billing-principal"
            )
            context.insert(try BillingDocumentDeliveryModel(delivery))
        case .stockRemote:
            context.insert(StockRemoteStateModel(
                movementID: id,
                payloadVersion: 1,
                recordData: Data("retained orphan remote payload".utf8)
            ))
        case .stockConflict:
            context.insert(StockSyncConflictModel(
                movementID: id,
                payloadVersion: 1,
                conflictData: Data("retained orphan conflict payload".utf8)
            ))
        case .stockCursor:
            context.insert(StockSyncCursorModel(feedID: "stock", changeSequence: 53))
        case .stockRetry:
            context.insert(StockSyncRetryModel(try SyncRetryState(
                scope: .pull,
                backoffStep: 2,
                notBefore: Date(timeIntervalSinceReferenceDate: 1310),
                lastRecoverableCategory: .unavailable
            )))
        }
        try context.save()
        let inspector = SwiftDataStorePristineDataSource(modelContainer: container)
        let claims = DocumentStoreSecureClaims()
        let binding = KeychainLocalPrincipalDataSource(
            readBinding: { .missing },
            addBinding: { _ in
                await claims.add()
            },
            isStorePristine: {
                try await inspector.isPristine()
            }
        )
        let useCase = AuthorizeLocalPrincipalUseCase(authorizer: LocalPrincipalAuthorizer { session in
            try await binding.authorize(principalID: session.id)
        })

        #expect(try await !inspector.isPristine())
        await #expect(throws: LocalPrincipalAuthorizationError.localStoreNotPristine) {
            try await useCase(session: AuthenticationSession(id: "unbound-new-principal"))
        }
        #expect(await claims.count == 0)
    }
}

private enum LocalPublishedRow {
    case billing, stockRemote, stockConflict, stockCursor, stockRetry
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

private enum LocalDocumentRow {
    case draft
    case pendingDocument
    case uploadedDocument
}

private actor DocumentStoreSecureClaims {
    private(set) var count = 0

    func add() -> KeychainLocalPrincipalDataSource.AddResult {
        count += 1
        return .stored
    }
}

@MainActor
private func insertDocumentRow(_ row: LocalDocumentRow, in context: ModelContext) async throws {
    let draftID = try #require(UUID(uuidString: "85000000-0000-0000-0000-000000000006"))
    switch row {
    case .draft:
        let draft = try ClientDocumentDraft(.init(
            id: draftID,
            clientID: ClientDocumentTestFixtures.clientID,
            profile: ClientProfile(displayName: "Draft without client row"),
            snapshot: nil,
            binding: nil,
            signedAt: nil,
            revision: 0
        ))
        context.insert(try ClientDocumentDraftModel(draft))
    case .pendingDocument, .uploadedDocument:
        let snapshot = try await ClientDocumentTestFixtures.snapshot()
        let document = try await ClientDocumentTestFixtures.render(snapshot)
        let model = try ClientSignedDocumentModel(draftID: draftID, document: document)
        if case .uploadedDocument = row {
            try model.setState(.uploaded(ClientDocumentUploadReceipt(
                documentID: document.id,
                principalID: "document-store-principal",
                reference: ClientConsentReference(rawValue: "synthetic/document-uploaded")
            )))
        }
        context.insert(model)
    }
}
