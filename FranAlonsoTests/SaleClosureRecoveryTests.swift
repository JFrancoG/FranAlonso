import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale closure fences and shared observation", .timeLimit(.minutes(1)))
@MainActor
struct SaleClosureRecoveryTests {
    @Test(
        "identity fences preserve pending and conflict evidence",
        arguments: [
            ("missing", SaleClosureError.notFound),
            ("tombstone", .deleted),
            ("pendingDiscard", .deleted),
            ("conflict", .conflict)
        ]
    )
    func identityFencesPreservePendingAndConflictEvidence(_ fence: String, error: SaleClosureError) throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        let source = SaleLocalDataSource()
        try SaleClosureTestFixtures.seed(document, in: context)
        switch fence {
        case "missing":
            context.delete(try #require(try context.fetch(FetchDescriptor<SaleModel>()).first))
            try context.save()
        case "tombstone":
            context.insert(try SaleRemoteStateModel(record: SaleRemoteRecord(
                content: .tombstone(saleID: document.saleID.rawValue),
                version: .versioned(revision: 1, lastOperationID: SaleClosureTestFixtures.predecessorID),
                changeSequence: 1
            )))
            try context.save()
        case "pendingDiscard":
            context.insert(try SalePendingDiscardModel(
                saleID: document.saleID.rawValue,
                operationID: SaleClosureTestFixtures.predecessorID,
                predecessorOperationID: nil,
                base: .absent
            ))
            try context.save()
        default:
            try source.persistPendingUpsert(
                document.request.sale,
                operationID: SaleClosureTestFixtures.predecessorID,
                in: context
            )
            try source.recordConflict(
                operation: #require(try source.pendingOperations(in: context).first),
                reason: .baseChanged,
                remoteRecord: nil,
                in: context
            )
        }
        let before = try source.pendingOperations(in: ModelContext(container))
        let documents = try SaleClosureTestFixtures.persistedDeliveries(in: ModelContext(container))
        #expect(throws: error) {
            _ = try SaleClosureTestFixtures.close(document, in: context)
        }
        #expect(try source.pendingOperations(in: ModelContext(container)) == before)
        #expect(try SaleClosureTestFixtures.persistedDeliveries(in: ModelContext(container)) == documents)
        #expect(!context.hasChanges)
    }

    @Test("cancellation thrown before local commit rolls back staged closure and successor")
    func cancellationThrownBeforeLocalCommitRollsBackStagedClosureAndSuccessor() throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        let context = ModelContext(container)
        try SaleClosureTestFixtures.seed(document, in: context)
        context.autosaveEnabled = true
        let source = SaleClosureTestFixtures.source(save: { staged in
            #expect(try staged.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 1)
            throw CancellationError()
        })
        #expect(throws: CancellationError.self) {
            _ = try SaleClosureTestFixtures.close(document, source: source, in: context)
        }
        #expect(!context.hasChanges)
        #expect(context.autosaveEnabled)
        #expect(
            try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container)) == document.request.sale
        )
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).isEmpty)
    }

    @Test(
        "actor and ephemeral-context acceptance update the existing shared Sales observation",
        arguments: [false, true]
    )
    func actorAndEphemeralContextAcceptanceUpdateTheExistingSharedSalesObservation(_ contextual: Bool) async throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        try SaleClosureTestFixtures.seed(document, in: ModelContext(container))
        let signal = SaleObservationSignal()
        let repository = SaleClosureTestFixtures.repository(container, signal: signal)
        let stream = await repository.observeSales()
        var iterator = stream.makeAsyncIterator()
        #expect(try await iterator.next() == [document.request.sale])
        let request = try SaleClosureTestFixtures.command(document)
        let accepted: Sale
        if contextual {
            accepted = try await SaleContextualPersistenceAdapter(observationSignal: signal).closeSale(
                request,
                principalID: SaleClosureTestFixtures.principalID,
                in: container.mainContext
            )
        } else {
            accepted = try await repository.closeSale(request, principalID: SaleClosureTestFixtures.principalID)
        }
        let materialized = try #require(try await iterator.next())
        #expect(materialized == [accepted])
        #expect(WorkdaySalesPolicy()(materialized).isEmpty)
        #expect(SalesHistoryPolicy()(materialized) == [accepted])
        let release = Task {
            for try await _ in stream {
            }
        }
        release.cancel()
        _ = await release.result
    }

    @Test("concurrent commands sharing the actor create one closure and one successor")
    func concurrentCommandsSharingTheActorCreateOneClosureAndOneSuccessor() async throws {
        let container = try SaleClosureTestFixtures.container()
        let document = try billingRenderingDocument()
        try SaleClosureTestFixtures.seed(document, in: ModelContext(container))
        let repository = SaleClosureTestFixtures.repository(container)
        let request = try SaleClosureTestFixtures.command(document)
        async let first = repository.closeSale(request, principalID: SaleClosureTestFixtures.principalID)
        async let second = repository.closeSale(request, principalID: SaleClosureTestFixtures.principalID)
        let values = try await [first, second]
        #expect(try values == Array(repeating: SaleClosureTestFixtures.closed(document), count: 2))
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).count == 1)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<BillingDocumentDeliveryModel>()) == 1)
    }
}
