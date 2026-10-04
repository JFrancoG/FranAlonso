import Foundation
import Testing
@testable import FranAlonso

@Suite("Paid sale closure acceptance")
struct SaleClosureDomainTests {
    @Test(
        "unpaid snapshots cannot construct a closure command",
        arguments: [SaleStatus.draft, .inProgress, .awaitingPayment]
    )
    func unpaidSnapshotsCannotConstructAClosureCommand(_ status: SaleStatus) throws {
        var sale = try viewModelSale()
        if status != .draft {
            try sale.start()
        }
        if status == .awaitingPayment {
            for line in sale.lines {
                try sale.startLine(id: line.id)
                try sale.completeLine(id: line.id)
            }
        }
        let document = try billingRenderingDocument()
        #expect(throws: SaleClosureError.requiresPayment) {
            _ = try SaleClosureRequest(
                expected: sale,
                requestID: document.request.id,
                closedAt: SaleClosureTestFixtures.closedAt
            )
        }
    }

    @Test("nonfinite closure dates are rejected before persistence", arguments: [Double.infinity, -.infinity, .nan])
    func nonfiniteClosureDatesAreRejectedBeforePersistence(_ seconds: Double) throws {
        let document = try billingRenderingDocument()
        #expect(throws: SaleClosureError.invalidTimestamp) {
            _ = try SaleClosureTestFixtures.command(document, at: Date(timeIntervalSince1970: seconds))
        }
    }

    @Test(
        "numbered document and retained PDF close without an upload receipt",
        arguments: [BillingDocumentKind.ticket, .invoice]
    )
    func numberedDocumentAndRetainedPDFCloseWithoutAnUploadReceipt(_ kind: BillingDocumentKind) throws {
        let document = try billingRenderingDocument(kind: kind)
        let delivery = try SaleClosureTestFixtures.delivery(document)
        let accepted = try SaleClosureAcceptancePolicy()(
            SaleClosureTestFixtures.command(document),
            current: document.request.sale,
            delivery: delivery,
            principalID: SaleClosureTestFixtures.principalID
        )
        #expect(try accepted == SaleClosureTestFixtures.closed(document))
        #expect(!delivery.isFinal)
        #expect(WorkdaySalesPolicy()([accepted]).isEmpty)
        #expect(SalesHistoryPolicy()([accepted]).count == 1)
    }

    @Test(
        "number or PDF still pending never closes the paid sale",
        arguments: [BillingPersistenceCheckpoint.prepared, .numbered]
    )
    func numberOrPDFStillPendingNeverClosesThePaidSale(_ checkpoint: BillingPersistenceCheckpoint) throws {
        let document = try billingRenderingDocument()
        #expect(throws: SaleClosureError.documentPending) {
            _ = try SaleClosureAcceptancePolicy()(
                SaleClosureTestFixtures.command(document),
                current: document.request.sale,
                delivery: SaleClosureTestFixtures.delivery(document, checkpoint: checkpoint),
                principalID: SaleClosureTestFixtures.principalID
            )
        }
    }

    @Test("reentry with a new date preserves durable closure and any later void", arguments: [false, true])
    func reentryWithANewDatePreservesDurableClosureAndAnyLaterVoid(_ voided: Bool) throws {
        let document = try billingRenderingDocument()
        var current = try SaleClosureTestFixtures.closed(document)
        if voided {
            try current.void(reversalID: saleReversalTestID, voidedAt: saleReversalTestDate)
        }
        let accepted = try SaleClosureAcceptancePolicy()(
            SaleClosureTestFixtures.command(document, at: Date(timeIntervalSince1970: 9_000)),
            current: current,
            delivery: SaleClosureTestFixtures.delivery(document),
            principalID: SaleClosureTestFixtures.principalID
        )
        #expect(accepted == current)
    }

    @Test("changed commercial snapshot is rejected even with matching sale and document identities")
    func changedCommercialSnapshotIsRejectedEvenWithMatchingSaleAndDocumentIdentities() throws {
        let document = try billingRenderingDocument()
        let changed = try billingRenderingDocument(name: "Changed synthetic captured service").request.sale
        #expect(throws: SaleClosureError.staleSale) {
            _ = try SaleClosureAcceptancePolicy()(
                SaleClosureTestFixtures.command(document),
                current: changed,
                delivery: SaleClosureTestFixtures.delivery(document),
                principalID: SaleClosureTestFixtures.principalID
            )
        }
    }

    @Test("changed payment is rejected before document attachment")
    func changedPaymentIsRejectedBeforeDocumentAttachment() throws {
        let document = try billingRenderingDocument()
        #expect(throws: SaleClosureError.staleSale) {
            _ = try SaleClosureAcceptancePolicy()(
                SaleClosureTestFixtures.command(document),
                current: SaleClosureTestFixtures.replacingPayment(document.request.sale),
                delivery: SaleClosureTestFixtures.delivery(document),
                principalID: SaleClosureTestFixtures.principalID
            )
        }
    }

    @Test("another request cannot attach a known document")
    func anotherRequestCannotAttachAKnownDocument() throws {
        let document = try billingRenderingDocument()
        let request = try SaleClosureRequest(
            expected: document.request.sale,
            requestID: BillingDocumentRequestID(rawValue: SaleClosureTestFixtures.operationID),
            closedAt: SaleClosureTestFixtures.closedAt
        )
        #expect(throws: SaleClosureError.conflictingDocument) {
            _ = try SaleClosureAcceptancePolicy()(
                request,
                current: document.request.sale,
                delivery: SaleClosureTestFixtures.delivery(document),
                principalID: SaleClosureTestFixtures.principalID
            )
        }
    }

    @Test("a different principal cannot close another shell document")
    func aDifferentPrincipalCannotCloseAnotherShellDocument() throws {
        let document = try billingRenderingDocument()
        #expect(throws: SaleClosureError.unauthorized) {
            _ = try SaleClosureAcceptancePolicy()(
                SaleClosureTestFixtures.command(document),
                current: document.request.sale,
                delivery: SaleClosureTestFixtures.delivery(document),
                principalID: "another-synthetic-principal"
            )
        }
    }

    @Test("closure under a different document is never silently replaced")
    func closureUnderADifferentDocumentIsNeverSilentlyReplaced() throws {
        let document = try billingRenderingDocument()
        var current = document.request.sale
        try current.close(
            documentID: BillingDocumentID(rawValue: SaleClosureTestFixtures.operationID),
            closedAt: SaleClosureTestFixtures.closedAt
        )
        #expect(throws: SaleClosureError.conflictingDocument) {
            _ = try SaleClosureAcceptancePolicy()(
                SaleClosureTestFixtures.command(document),
                current: current,
                delivery: SaleClosureTestFixtures.delivery(document),
                principalID: SaleClosureTestFixtures.principalID
            )
        }
    }
}
