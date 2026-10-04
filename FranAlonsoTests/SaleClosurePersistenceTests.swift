import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Atomic retained-document sale closure")
@MainActor
struct SaleClosurePersistenceTests {
    @Test(
        "sale and causal successor become durable together while document and stock bytes stay unchanged",
        arguments: [BillingDocumentKind.ticket, .invoice]
    )
    func saleAndCausalSuccessorBecomeDurableTogetherWhileDocumentAndStockBytesStayUnchanged(
        _ kind: BillingDocumentKind
    ) throws {
        let container = try SaleClosureTestFixtures.container()
        let context = ModelContext(container)
        let document = try billingRenderingDocument(kind: kind)
        try SaleClosureTestFixtures.seed(document, in: context)
        let source = SaleLocalDataSource()
        try source.persistPendingUpsert(
            document.request.sale,
            operationID: SaleClosureTestFixtures.predecessorID,
            in: context
        )
        context.insert(ProductModel(Product(
            id: saleStockProductID(1),
            name: "Synthetic closure stock fixture",
            status: .active
        )))
        try context.save()
        _ = try StockLocalDataSource().append(
            stockTestMovement(productID: saleStockProductID(1), delta: 7, ordinal: 91),
            in: context
        )
        let documents = try SaleClosureTestFixtures.persistedDeliveries(in: context)
        let stock = try stockPayloads(in: context)
        let accepted = try SaleClosureTestFixtures.close(document, in: context)
        let independent = ModelContext(container)
        #expect(try accepted == SaleClosureTestFixtures.closed(document))
        #expect(try source.sale(id: accepted.id, in: independent) == accepted)
        let queue = try source.pendingOperations(in: independent)
        #expect(queue.map(\.operationID) == [
            SaleClosureTestFixtures.predecessorID, SaleClosureTestFixtures.operationID
        ])
        #expect(queue.last?.predecessorOperationID == SaleClosureTestFixtures.predecessorID)
        #expect(try SaleClosureTestFixtures.persistedDeliveries(in: independent) == documents)
        #expect(try stockPayloads(in: independent) == stock)
        #expect(!context.hasChanges)
    }

    @Test("a new reentry date preserves closure and void without saving or enqueuing", arguments: [false, true])
    func aNewReentryDatePreservesClosureAndVoidWithoutSavingOrEnqueuing(_ voided: Bool) throws {
        let container = try SaleClosureTestFixtures.container()
        let context = ModelContext(container)
        let document = try billingRenderingDocument()
        try SaleClosureTestFixtures.seed(document, in: context)
        var accepted = try SaleClosureTestFixtures.close(document, in: context)
        if voided {
            try accepted.void(reversalID: saleReversalTestID, voidedAt: saleReversalTestDate)
            try SaleLocalDataSource().upsert(accepted, in: context)
        }
        let before = try SaleLocalDataSource().pendingOperations(in: ModelContext(container))
        let documents = try SaleClosureTestFixtures.persistedDeliveries(in: ModelContext(container))
        let source = SaleClosureTestFixtures.source(save: { _ in
            throw SaleClosureCommitFailure.unexpectedSave
        })
        let replay = try SaleClosureTestFixtures.close(
            document,
            at: Date(timeIntervalSince1970: 9_000),
            source: source,
            in: context
        )
        #expect(replay == accepted)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)) == before)
        #expect(try SaleClosureTestFixtures.persistedDeliveries(in: ModelContext(container)) == documents)
        #expect(!context.hasChanges)
    }

    @Test(
        "durable pending number or PDF keeps the sale operational",
        arguments: [BillingPersistenceCheckpoint.prepared, .numbered]
    )
    func durablePendingNumberOrPDFKeepsTheSaleOperational(_ checkpoint: BillingPersistenceCheckpoint) throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleClosureTestFixtures.seed(document, checkpoint: checkpoint, in: context)
        #expect(throws: SaleClosureError.documentPending) {
            _ = try SaleClosureTestFixtures.close(document, in: context)
        }
        #expect(
            try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container)) == document.request.sale
        )
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
    }

    @Test("missing delivery never fabricates a closure from a document identifier")
    func missingDeliveryNeverFabricatesAClosureFromADocumentIdentifier() throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleLocalDataSource().upsert(document.request.sale, in: context)
        #expect(throws: SaleClosureError.documentNotFound) {
            _ = try SaleClosureTestFixtures.close(document, in: context)
        }
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
    }

    @Test(
        "corrupt document envelopes or indexed bindings cannot close the sale",
        arguments: [
            BillingPersistenceEnvelopeDamage.version, .payload, .documentID, .saleID, .kind, .principal
        ]
    )
    func corruptDocumentEnvelopesOrIndexedBindingsCannotCloseTheSale(
        _ damage: BillingPersistenceEnvelopeDamage
    ) throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleClosureTestFixtures.seed(document, in: context)
        let row = try #require(try context.fetch(FetchDescriptor<BillingDocumentDeliveryModel>()).first)
        damage.apply(to: row)
        try context.save()
        let bytes = row.payload
        #expect(throws: SaleClosureError.invalidDocument) {
            _ = try SaleClosureTestFixtures.close(document, in: context)
        }
        #expect(row.payload == bytes)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(
            try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container)) == document.request.sale
        )
    }

    @Test("nonempty corrupt retained PDF cannot authorize closure")
    func nonemptyCorruptRetainedPDFCannotAuthorizeClosure() throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleLocalDataSource().upsert(document.request.sale, in: context)
        var delivery = try SaleClosureTestFixtures.delivery(document, checkpoint: .numbered)
        try delivery.acceptPDF(Data("nonempty corrupt PDF bytes".utf8))
        let row = try BillingDocumentDeliveryModel(SaleClosureTestFixtures.delivery(document))
        row.payload = try JSONEncoder().encode(SaleClosureDeliveryEnvelope(delivery: delivery))
        context.insert(row)
        try context.save()
        #expect(throws: SaleClosureError.invalidDocument) {
            _ = try SaleClosureTestFixtures.close(document, in: context)
        }
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
    }

    @Test("document already claimed by another closed sale rejects acceptance")
    func documentAlreadyClaimedByAnotherClosedSaleRejectsAcceptance() throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleClosureTestFixtures.seed(document, in: context)
        var foreign = try SaleClosureTestFixtures.replacingID(document.request.sale)
        try foreign.close(documentID: document.id, closedAt: SaleClosureTestFixtures.closedAt)
        try SaleLocalDataSource().upsert(foreign, in: context)
        #expect(throws: SaleClosureError.conflictingDocument) {
            _ = try SaleClosureTestFixtures.close(document, in: context)
        }
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(
            try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container)) == document.request.sale
        )
    }

    @Test("another principal cannot close a retained local document")
    func anotherPrincipalCannotCloseARetainedLocalDocument() throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleClosureTestFixtures.seed(document, in: context)
        #expect(throws: SaleClosureError.unauthorized) {
            _ = try SaleLocalDataSource().closeSale(
                SaleClosureTestFixtures.command(document),
                principalID: "foreign-synthetic-principal",
                operationID: SaleClosureTestFixtures.operationID,
                in: context
            )
        }
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
    }

    @Test("dirty context is rejected without rolling back unrelated unsaved work")
    func dirtyContextIsRejectedWithoutRollingBackUnrelatedUnsavedWork() throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleClosureTestFixtures.seed(document, in: context)
        context.insert(try SaleModel(SaleClosureTestFixtures.replacingID(document.request.sale)))
        #expect(throws: SaleClosureError.persistenceUnavailable) {
            _ = try SaleClosureTestFixtures.close(document, in: context)
        }
        #expect(context.hasChanges)
        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 2)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<SaleModel>()) == 1)
    }

    @Test("failed local save rolls back closure and its successor before retry")
    func failedLocalSaveRollsBackClosureAndItsSuccessorBeforeRetry() throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleClosureTestFixtures.seed(document, in: context)
        let documents = try SaleClosureTestFixtures.persistedDeliveries(in: ModelContext(container))
        let failing = SaleClosureTestFixtures.source(save: { staged in
            let queued = try SaleLocalDataSource().pendingOperations(in: staged)
            #expect(queued.map(\.operationID) == [SaleClosureTestFixtures.operationID])
            #expect(
                try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container))
                    == document.request.sale
            )
            throw SaleClosureCommitFailure.detailedFailure
        })
        #expect(throws: SaleClosureError.persistenceUnavailable) {
            _ = try SaleClosureTestFixtures.close(document, source: failing, in: context)
        }
        #expect(!context.hasChanges)
        #expect(
            try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container)) == document.request.sale
        )
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
        #expect(try SaleClosureTestFixtures.persistedDeliveries(in: ModelContext(container)) == documents)
        let accepted = try SaleClosureTestFixtures.close(document, in: context)
        #expect(try accepted == SaleClosureTestFixtures.closed(document))
    }
}

private struct SaleClosureDeliveryEnvelope: Codable {
    let delivery: BillingDocumentDelivery
}
