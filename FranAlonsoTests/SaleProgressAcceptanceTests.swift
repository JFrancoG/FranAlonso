import Foundation
import SwiftData
import Testing
@testable import FranAlonso

struct SaleProgressAcceptanceTests {
    @Test
    func `a causal identity collision rolls back progress and permits a new acceptance attempt`() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let draft = try viewModelSale()
        let context = ModelContext(container)
        let id = viewModelUUID(970)
        try source.persistPendingUpsert(draft, operationID: id, in: context)
        let before = try source.pendingOperations(in: ModelContext(container))
        #expect(throws: SaleProgressError.persistenceUnavailable) {
            _ = try source.advanceSale(
                draft,
                action: .start,
                operationID: id,
                in: context
            )
        }
        #expect(!context.hasChanges)
        #expect(try source.sale(id: draft.id, in: ModelContext(container)) == draft)
        #expect(try source.pendingOperations(in: ModelContext(container)) == before)
        let accepted = try source.advanceSale(
            draft,
            action: .start,
            operationID: viewModelUUID(971),
            in: context
        )
        #expect(accepted.status == .inProgress)
        #expect(try source.pendingOperations(in: ModelContext(container)).count == 2)
    }

    @Test
    func `dirty context is rejected without erasing unrelated unsaved work`() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let draft = try viewModelSale()
        let context = ModelContext(container)
        try source.upsert(draft, in: context)
        context.insert(try SaleModel(viewModelSale(index: 2)))
        #expect(throws: SaleProgressError.persistenceUnavailable) {
            _ = try source.advanceSale(
                draft,
                action: .start,
                operationID: viewModelUUID(971),
                in: context
            )
        }
        #expect(context.hasChanges)
        #expect(try source.sale(id: draft.id, in: ModelContext(container)) == draft)
        #expect(try source.pendingOperations(in: ModelContext(container)).isEmpty)
    }

    @Test
    func `discarded identity cannot be resurrected by starting work`() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let context = ModelContext(container)
        let draft = try viewModelSale()
        try source.createDraft(draft, operationID: viewModelUUID(970), in: context)
        try source.discardDraft(draft.id, operationID: viewModelUUID(971), in: context)
        let before = try source.pendingOperations(in: ModelContext(container))
        #expect(throws: SaleProgressError.deleted) {
            _ = try source.advanceSale(
                draft,
                action: .start,
                operationID: viewModelUUID(972),
                in: context
            )
        }
        #expect(try source.sale(id: draft.id, in: ModelContext(container)) == nil)
        #expect(try source.pendingOperations(in: ModelContext(container)) == before)
    }

    @Test
    func `conflict evidence is preserved while work acceptance is rejected`() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let context = ModelContext(container)
        let draft = try viewModelSale()
        try source.persistPendingUpsert(draft, operationID: viewModelUUID(970), in: context)
        let operation = try #require(try source.pendingOperations(in: context).first)
        try source.recordConflict(
            operation: operation,
            reason: .baseChanged,
            remoteRecord: nil,
            in: context
        )
        let before = try source.pendingOperations(in: ModelContext(container))
        #expect(throws: SaleProgressError.conflict) {
            _ = try source.advanceSale(
                draft,
                action: .start,
                operationID: viewModelUUID(971),
                in: context
            )
        }
        #expect(try source.sale(id: draft.id, in: ModelContext(container)) == draft)
        #expect(try source.pendingOperations(in: ModelContext(container)) == before)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<SaleSyncConflictModel>()) == 1)
    }

    @Test
    func `missing identity never creates a sale or pending progress`() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        let draft = try viewModelSale()
        #expect(throws: SaleProgressError.notFound) {
            _ = try source.advanceSale(
                draft,
                action: .start,
                operationID: viewModelUUID(971),
                in: ModelContext(container)
            )
        }
        #expect(try source.fetchAll(in: ModelContext(container)).isEmpty)
        #expect(try source.pendingOperations(in: ModelContext(container)).isEmpty)
    }

    @Test
    func `older work replay cannot downgrade a later completed line`() throws {
        let draft = try viewModelSale()
        var started = draft
        try started.start()
        var current = started
        try current.startLine(id: current.lines[0].id)
        try current.completeLine(id: current.lines[0].id)
        #expect(throws: SaleProgressError.staleSale) {
            _ = try SaleProgressAcceptancePolicy()(expected: draft, current: current, action: .start)
        }
        #expect(current.status == .awaitingPayment)
    }
}
