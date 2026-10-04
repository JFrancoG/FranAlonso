import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Recoverable sale closure on disk")
@MainActor
struct SaleClosureDurabilityTests {
    @Test(
        "failed commit reopens paid sale then retry persists one closure and write-free replay",
        arguments: [BillingDocumentKind.ticket, .invoice]
    )
    func failedCommitReopensPaidSaleThenRetryPersistsOneClosureAndWriteFreeReplay(_ kind: BillingDocumentKind) throws {
        try withPhaseFiveMigrationStore { url in
            let document = try billingRenderingDocument(kind: kind)
            let probe = SaleClosureDiskOwnerProbe()
            let bytes = try failClosureOnDisk(document, at: url, probe: probe)
            #expect(probe.container == nil)
            try verifyPaidClosureOnDisk(
                document,
                bytes: bytes,
                at: url,
                probe: probe
            )
            #expect(probe.container == nil)
            let accepted = try acceptClosureOnDisk(document, at: url, probe: probe)
            #expect(probe.container == nil)
            try verifyAcceptedClosureOnDisk(
                document,
                accepted: accepted,
                bytes: bytes,
                replayAt: Date(timeIntervalSince1970: 4_000),
                at: url,
                probe: probe
            )
            #expect(probe.container == nil)
            try verifyAcceptedClosureOnDisk(
                document,
                accepted: accepted,
                bytes: bytes,
                replayAt: Date(timeIntervalSince1970: 8_000),
                at: url,
                probe: probe
            )
            #expect(probe.container == nil)
        }
    }

    @Test("closure keeps the failed upload checkpoint available for durable retry after reopening")
    func closureKeepsTheFailedUploadCheckpointAvailableForDurableRetryAfterReopening() throws {
        try withPhaseFiveMigrationStore { url in
            let document = try billingRenderingDocument()
            let probe = SaleClosureDiskOwnerProbe()
            let delivery = try closeWithFailedUploadOnDisk(document, at: url, probe: probe)
            #expect(probe.container == nil)
            try verifyClosedUploadCheckpointOnDisk(
                document,
                expected: delivery,
                at: url,
                probe: probe
            )
            #expect(probe.container == nil)
        }
    }
}

@MainActor
private final class SaleClosureDiskOwnerProbe {
    weak var container: ModelContainer?
}

@MainActor
private func failClosureOnDisk(
    _ document: BillingDocument,
    at url: URL,
    probe: SaleClosureDiskOwnerProbe
) throws -> [UUID: Data] {
    let container = try SaleClosureTestFixtures.container(at: url)
    probe.container = container
    let context = container.mainContext
    try SaleClosureTestFixtures.seed(document, in: context)
    let bytes = try SaleClosureTestFixtures.persistedDeliveries(in: context)
    let source = SaleClosureTestFixtures.source(save: { staged in
        #expect(try staged.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 1)
        throw SaleClosureCommitFailure.detailedFailure
    })
    #expect(throws: SaleClosureError.persistenceUnavailable) {
        _ = try SaleClosureTestFixtures.close(document, source: source, in: context)
    }
    #expect(!context.hasChanges)
    return bytes
}

@MainActor
private func verifyPaidClosureOnDisk(
    _ document: BillingDocument,
    bytes: [UUID: Data],
    at url: URL,
    probe: SaleClosureDiskOwnerProbe
) throws {
    let container = try SaleClosureTestFixtures.container(at: url)
    probe.container = container
    let context = ModelContext(container)
    #expect(try SaleLocalDataSource().sale(id: document.saleID, in: context) == document.request.sale)
    #expect(try SaleLocalDataSource().pendingOperations(in: context).isEmpty)
    #expect(try SaleClosureTestFixtures.persistedDeliveries(in: context) == bytes)
    #expect(WorkdaySalesPolicy()([document.request.sale]).awaitingClosure.count == 1)
}

@MainActor
private func acceptClosureOnDisk(
    _ document: BillingDocument,
    at url: URL,
    probe: SaleClosureDiskOwnerProbe
) throws -> Sale {
    let container = try SaleClosureTestFixtures.container(at: url)
    probe.container = container
    return try SaleClosureTestFixtures.close(document, in: container.mainContext)
}

@MainActor
private func verifyAcceptedClosureOnDisk(
    _ document: BillingDocument,
    accepted: Sale,
    bytes: [UUID: Data],
    replayAt: Date,
    at url: URL,
    probe: SaleClosureDiskOwnerProbe
) throws {
    let container = try SaleClosureTestFixtures.container(at: url)
    probe.container = container
    let context = container.mainContext
    let source = SaleClosureTestFixtures.source(save: { _ in
        throw SaleClosureCommitFailure.unexpectedSave
    })
    #expect(try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container)) == accepted)
    #expect(try SaleClosureTestFixtures.close(
        document,
        at: replayAt,
        source: source,
        in: context
    ) == accepted)
    #expect(try SaleClosureTestFixtures.persistedDeliveries(in: ModelContext(container)) == bytes)
    #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).map(\.operationID) == [
        SaleClosureTestFixtures.operationID
    ])
    #expect(try ModelContext(container).fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    #expect(WorkdaySalesPolicy()([accepted]).isEmpty)
    #expect(SalesHistoryPolicy()([accepted]) == [accepted])
    #expect(!context.hasChanges)
}

@MainActor
private func closeWithFailedUploadOnDisk(
    _ document: BillingDocument,
    at url: URL,
    probe: SaleClosureDiskOwnerProbe
) throws -> BillingDocumentDelivery {
    let container = try SaleClosureTestFixtures.container(at: url)
    probe.container = container
    let context = container.mainContext
    var delivery = try SaleClosureTestFixtures.delivery(document, checkpoint: .attempt)
    try delivery.recordFailure(phase: .upload, reason: .unavailable, attempt: 1)
    try SaleLocalDataSource().upsert(document.request.sale, in: context)
    context.insert(try BillingDocumentDeliveryModel(delivery))
    try context.save()
    _ = try SaleClosureTestFixtures.close(document, in: context)
    return delivery
}

@MainActor
private func verifyClosedUploadCheckpointOnDisk(
    _ document: BillingDocument,
    expected: BillingDocumentDelivery,
    at url: URL,
    probe: SaleClosureDiskOwnerProbe
) throws {
    let container = try SaleClosureTestFixtures.container(at: url)
    probe.container = container
    let context = ModelContext(container)
    let row = try #require(try context.fetch(FetchDescriptor<BillingDocumentDeliveryModel>()).first)
    let delivery = try row.toDomain()
    #expect(delivery == expected)
    #expect(delivery.failure?.phase == .upload)
    #expect(delivery.uploadAttempts == 1)
    #expect(delivery.receipt == nil)
    let accepted = try #require(try SaleLocalDataSource().sale(id: document.saleID, in: context))
    #expect(try accepted == SaleClosureTestFixtures.closed(document))
    #expect(WorkdaySalesPolicy()([accepted]).isEmpty)
}
