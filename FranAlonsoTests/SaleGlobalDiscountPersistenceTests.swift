import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale global discount persistence")
struct SaleGlobalDiscountPersistenceTests {
    @Test("Raw schema3 v1 reads without rewrite and appends v2 with every old causal byte intact")
    func historicalSchemaThreeReopensAndAcceptsSuccessorTwice() throws {
        try SaleGlobalDiscountDataFixture.withStore { url in
            let historicalBytes: [String: Data]
            do {
                let container = try SaleGlobalDiscountDataFixture.fileContainer(at: url, raw: true)
                let context = ModelContext(container)
                insertGlobalHistoricalRows(in: context)
                try context.save()
                historicalBytes = try globalHistoricalBytes(in: context)
            }

            do {
                let container = try SaleGlobalDiscountDataFixture.fileContainer(at: url)
                let context = ModelContext(container)
                let source = SaleLocalDataSource()
                let id = SaleID(rawValue: SaleGlobalDiscountDataFixture.saleID)
                let before = try #require(try source.sale(id: id, in: context))
                #expect(before.globalDiscount == nil)
                #expect(try SaleCalculator().calculate(sale: before, currency: .eur).total.amount == 90)
                #expect(try globalHistoricalBytes(in: context) == historicalBytes)
                #expect(!context.hasChanges)
                let root = try #require(try context.fetch(FetchDescriptor<SaleModel>()).first)
                #expect(root.linesPayloadVersion == 1)
                #expect(root.linesData == Data(SaleGlobalDiscountDataFixture.linesV1.utf8))

                let accepted = try source.updateDraft(
                    before,
                    clientID: before.clientID,
                    lines: before.lines,
                    globalDiscount: SaleGlobalDiscount(
                        discount: try Discount(percentage: 20),
                        policy: .lineThenGlobalV1
                    ),
                    operationID: SaleGlobalDiscountDataFixture.operationB,
                    in: context
                )

                #expect(accepted.globalDiscount?.policy == .lineThenGlobalV1)
                #expect(try SaleCalculator().calculate(sale: accepted, currency: .eur).total.amount == 72)
                #expect(root.linesPayloadVersion == 2)
                #expect(try globalHistoricalBytes(in: context) == historicalBytes)
                try verifyGlobalSuccessor(in: context)
            }

            for _ in 0..<2 {
                let container = try SaleGlobalDiscountDataFixture.fileContainer(at: url)
                let context = ModelContext(container)
                let sale = try #require(
                    try SaleLocalDataSource().sale(
                        id: SaleID(rawValue: SaleGlobalDiscountDataFixture.saleID),
                        in: context
                    )
                )
                #expect(sale.globalDiscount?.policy == .lineThenGlobalV1)
                #expect(sale.globalDiscount?.discount.percentage == 20)
                #expect(sale.lines.first?.discount?.percentage == 10)
                #expect(try SaleCalculator().calculate(sale: sale, currency: .eur).total.amount == 72)
                #expect(try globalHistoricalBytes(in: context) == historicalBytes)
                try verifyGlobalSuccessor(in: context)
                #expect(!context.hasChanges)
            }
        }
    }

    @Test("The default repository accepts an explicit global and its old overload preserves it")
    func defaultRepositoryPreservesGlobalAcrossOldOverload() async throws {
        let container = try SaleGlobalDiscountDataFixture.memoryContainer()
        let actor = SalePersistenceActor(modelContainer: container)
        let repository = DefaultSaleRepository(persistenceActor: actor, observationSignal: SaleObservationSignal())
        let initial = try SaleGlobalDiscountDataFixture.domain()
        try await repository.createDraft(initial)
        let discounted = try await repository.updateDraft(
            initial,
            clientID: initial.clientID,
            lines: initial.lines,
            globalDiscount: SaleGlobalDiscount(discount: try Discount(percentage: 20), policy: .lineThenGlobalV1)
        )
        let newClient = ClientID(rawValue: UUID(uuidString: "92000000-0000-0000-0000-000000000020")!)
        let changedClient = try await repository.updateDraft(discounted, clientID: newClient, lines: discounted.lines)
        let durable = try #require(try await repository.sale(id: initial.id))

        #expect(changedClient.clientID == newClient)
        #expect(durable.globalDiscount?.discount.percentage == 20)
        #expect(durable.lines.first?.discount?.percentage == 10)
        #expect(try SaleCalculator().calculate(sale: durable, currency: .eur).total.amount == 72)
    }

    @MainActor
    @Test("The contextual route preserves global during client edits and removes only that term explicitly")
    func contextualRoutePreservesAndRemovesGlobalIndependently() async throws {
        let container = try SaleGlobalDiscountDataFixture.memoryContainer()
        let context = ModelContext(container)
        let adapter = SaleContextualPersistenceAdapter(observationSignal: SaleObservationSignal())
        let initial = try SaleGlobalDiscountDataFixture.domain(globalPercentage: 20)
        try await adapter.createDraft(initial, in: context)
        let edited = try await adapter.updateDraft(
            initial,
            clientID: nil,
            lines: initial.lines,
            in: context
        )
        #expect(edited.globalDiscount?.discount.percentage == 20)

        let removed = try await adapter.updateDraft(
            edited,
            clientID: edited.clientID,
            lines: edited.lines,
            globalDiscount: nil,
            in: context
        )
        let durable = try #require(try SaleLocalDataSource().sale(id: initial.id, in: ModelContext(container)))

        #expect(removed.globalDiscount == nil)
        #expect(durable.globalDiscount == nil)
        #expect(durable.lines.first?.discount?.percentage == 10)
        #expect(try SaleCalculator().calculate(sale: durable, currency: .eur).total.amount == 90)
    }

    @Test("An obsolete snapshot differing only in global fails without a new durable operation")
    func globalOnlyStaleSnapshotCannotOverwriteCurrentTerms() throws {
        let container = try SaleGlobalDiscountDataFixture.memoryContainer()
        let context = ModelContext(container)
        let source = SaleLocalDataSource()
        let original = try SaleGlobalDiscountDataFixture.domain()
        try source.createDraft(original, operationID: SaleGlobalDiscountDataFixture.operationA, in: context)
        _ = try source.updateDraft(
            original,
            clientID: original.clientID,
            lines: original.lines,
            globalDiscount: SaleGlobalDiscount(discount: try Discount(percentage: 20), policy: .lineThenGlobalV1),
            operationID: SaleGlobalDiscountDataFixture.operationB,
            in: context
        )
        let before = try source.pendingUpserts(in: context)

        #expect(throws: SaleDraftError.staleDraft) {
            _ = try source.updateDraft(
                original,
                clientID: original.clientID,
                lines: original.lines,
                globalDiscount: nil,
                operationID: UUID(uuidString: "92000000-0000-0000-0000-000000000030")!,
                in: context
            )
        }

        #expect(try source.pendingUpserts(in: context) == before)
        #expect(try source.sale(id: original.id, in: context)?.globalDiscount?.discount.percentage == 20)
        #expect(!context.hasChanges)
    }
}

private func insertGlobalHistoricalRows(in context: ModelContext) {
    context.insert(SaleGlobalDiscountDataFixture.rawModel())
    context.insert(
        SalePendingUpsertModel(
            saleID: SaleGlobalDiscountDataFixture.saleID,
            operationID: SaleGlobalDiscountDataFixture.operationA,
            predecessorOperationID: nil,
            baseVersion: 1,
            baseData: SaleGlobalDiscountDataFixture.legacyBaseV1,
            payloadVersion: 1,
            payloadData: Data(SaleGlobalDiscountDataFixture.saleV1.utf8)
        )
    )
    context.insert(
        SaleRemoteStateModel(
            saleID: SaleGlobalDiscountDataFixture.saleID,
            recordVersion: 1,
            recordData: SaleGlobalDiscountDataFixture.remoteV1
        )
    )
    let conflictSale = SaleGlobalDiscountDataFixture.saleV1.replacingOccurrences(
        of: SaleGlobalDiscountDataFixture.saleID.uuidString,
        with: SaleGlobalDiscountDataFixture.conflictSaleID.uuidString
    )
    let conflictBase = Data(#"{"legacy":{"_0":\#(conflictSale)}}"#.utf8)
    let conflictRemote = Data(#"{"content":{"live":{"_0":\#(conflictSale)}},"version":{"legacy":{}}}"#.utf8)
    context.insert(
        SaleSyncConflictModel(
            saleID: SaleGlobalDiscountDataFixture.conflictSaleID,
            operationID: UUID(uuidString: "92000000-0000-0000-0000-000000000092")!,
            predecessorOperationID: nil,
            operationKindRawValue: "upsert",
            reasonRawValue: "baseChanged",
            payloadVersion: 1,
            baseData: conflictBase,
            localSaleData: Data(conflictSale.utf8),
            remoteRecordData: conflictRemote
        )
    )
}

private func globalHistoricalBytes(in context: ModelContext) throws -> [String: Data] {
    let operations = try context.fetch(FetchDescriptor<SalePendingUpsertModel>())
    let a = try #require(operations.first { $0.operationID == SaleGlobalDiscountDataFixture.operationA })
    let remote = try #require(try context.fetch(FetchDescriptor<SaleRemoteStateModel>()).first)
    let conflict = try #require(try context.fetch(FetchDescriptor<SaleSyncConflictModel>()).first)
    let historical = try a.decodePayload().toDomain()
    #expect(historical.globalDiscount == nil)
    #expect(try SaleCalculator().calculate(sale: historical, currency: .eur).total.amount == 90)
    _ = try a.decodeBase()
    _ = try remote.decodeRecord().liveSale?.toDomain()
    #expect(try conflict.decodeOperation().saleID == SaleGlobalDiscountDataFixture.conflictSaleID)
    #expect(try conflict.decodeLocalSale()?.toDomain().globalDiscount == nil)
    #expect(try conflict.decodeRemoteRecord()?.liveSale?.toDomain().globalDiscount == nil)
    #expect(a.baseVersion == 1)
    #expect(a.payloadVersion == 1)
    #expect(remote.recordVersion == 1)
    #expect(conflict.payloadVersion == 1)
    return [
        "pending": a.payloadData,
        "base": try #require(a.baseData),
        "remote": remote.recordData,
        "conflictBase": conflict.baseData,
        "conflictLocal": try #require(conflict.localSaleData),
        "conflictRemote": try #require(conflict.remoteRecordData)
    ]
}

private func verifyGlobalSuccessor(in context: ModelContext) throws {
    let operations = try SaleLocalDataSource().pendingUpserts(in: context)
    let expectedIDs = [SaleGlobalDiscountDataFixture.operationA, SaleGlobalDiscountDataFixture.operationB]
    #expect(operations.map(\.operationID) == expectedIDs)
    let successor = try #require(operations.last)
    #expect(successor.predecessorOperationID == SaleGlobalDiscountDataFixture.operationA)
    #expect(successor.sale.payloadVersion == 2)
    #expect(try successor.sale.toDomain().globalDiscount?.policy == .lineThenGlobalV1)
    #expect(try successor.sale.toDomain().globalDiscount?.discount.percentage == 20)
    let model = try #require(
        try context.fetch(FetchDescriptor<SalePendingUpsertModel>())
            .first { $0.operationID == SaleGlobalDiscountDataFixture.operationB }
    )
    #expect(model.payloadVersion == 1)
    #expect(model.baseVersion == 1)
}
