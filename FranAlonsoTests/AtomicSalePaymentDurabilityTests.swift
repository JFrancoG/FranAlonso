import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Durable atomic sale payment")
@MainActor
struct AtomicSalePaymentDurabilityTests {
    @Test
    func `failed payment reopens unpaid then retry persists the complete immutable receipt twice`() throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appending(path: "atomic-sale.store")
        let original = try saleStockFixture(paid: false)
        let lifetime = AtomicPaymentLifetime()
        try failAtomicPaymentOnDisk(at: url, sale: original, lifetime: lifetime)
        #expect(lifetime.container == nil)
        for _ in 0..<2 {
            try verifyFailedAtomicPaymentOnDisk(at: url, sale: original, lifetime: lifetime)
            #expect(lifetime.container == nil)
        }
        let payloads = try acceptAtomicPaymentOnDisk(at: url, sale: original, lifetime: lifetime)
        #expect(lifetime.container == nil)
        for _ in 0..<2 {
            try replayAtomicPaymentOnDisk(
                at: url,
                sale: original,
                payloads: payloads,
                lifetime: lifetime
            )
            #expect(lifetime.container == nil)
        }
    }
}

@MainActor
private final class AtomicPaymentLifetime {
    weak var container: ModelContainer?
}

private func atomicPaymentDiskContainer(at url: URL) throws -> ModelContainer {
    let schema = Schema(versionedSchema: StockMovementsSchema.self)
    let configuration = ModelConfiguration(
        "AtomicPaymentDurability",
        schema: schema,
        url: url,
        allowsSave: true,
        cloudKitDatabase: .none
    )
    return try ModelContainer(
        for: schema,
        migrationPlan: PhaseFiveSchemaMigrationPlan.self,
        configurations: [configuration]
    )
}

@MainActor
private func failAtomicPaymentOnDisk(at url: URL, sale: Sale, lifetime: AtomicPaymentLifetime) throws {
    let container = try atomicPaymentDiskContainer(at: url)
    lifetime.container = container
    _ = try saleStockRepository(in: container)
    let context = container.mainContext
    try SaleLocalDataSource().persistPendingUpsert(sale, operationID: saleStockUUID(0x91, 1), in: context)
    let source = SaleLocalDataSource { staged in
        #expect(try staged.fetchCount(FetchDescriptor<StockMovementModel>()) == 3)
        #expect(try staged.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 2)
        throw AtomicPaymentFailure.commit
    }
    #expect(throws: SalePaymentError.persistenceUnavailable) {
        try atomicSourcePay(sale, source: source, in: context)
    }
    #expect(!context.hasChanges)
    #expect(context.autosaveEnabled)
}

@MainActor
private func verifyFailedAtomicPaymentOnDisk(at url: URL, sale: Sale, lifetime: AtomicPaymentLifetime) throws {
    let container = try atomicPaymentDiskContainer(at: url)
    lifetime.container = container
    let context = ModelContext(container)
    let source = SaleLocalDataSource()
    #expect(try source.sale(id: sale.id, in: context) == sale)
    let operations = try source.pendingOperations(in: context)
    #expect(operations.map(\.operationID) == [saleStockUUID(0x91, 1)])
    #expect(try context.fetchCount(FetchDescriptor<StockMovementModel>()) == 0)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == 0)
}

@MainActor
private func acceptAtomicPaymentOnDisk(
    at url: URL,
    sale: Sale,
    lifetime: AtomicPaymentLifetime
) throws -> [UUID: Data] {
    let container = try atomicPaymentDiskContainer(at: url)
    lifetime.container = container
    _ = try atomicSourcePay(sale, source: SaleLocalDataSource(), in: container.mainContext)
    return try stockPayloads(in: ModelContext(container))
}

@MainActor
private func replayAtomicPaymentOnDisk(
    at url: URL,
    sale: Sale,
    payloads: [UUID: Data],
    lifetime: AtomicPaymentLifetime
) throws {
    let container = try atomicPaymentDiskContainer(at: url)
    lifetime.container = container
    let context = container.mainContext
    let before = try SaleLocalDataSource().pendingOperations(in: context)
    #expect(before.map(\.operationID) == [saleStockUUID(0x91, 1), saleStockUUID(0x91, 2)])
    let noSave = SaleLocalDataSource { _ in
        throw AtomicPaymentFailure.unexpectedSave
    }
    let accepted = try atomicSourcePay(sale, source: noSave, in: context)
    #expect(try accepted == saleStockFixture())
    #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)) == before)
    #expect(payloads.count == 3)
    #expect(try stockPayloads(in: ModelContext(container)) == payloads)
    let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
    #expect(rows.allSatisfy { $0.payloadVersion == 2 && $0.isPendingSync })
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == -5)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(2), in: context) == -4)
    #expect(!context.hasChanges)
    #expect(context.autosaveEnabled)
}
