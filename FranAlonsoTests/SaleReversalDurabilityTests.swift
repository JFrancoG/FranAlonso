import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Durable atomic sale reversal")
@MainActor
struct SaleReversalDurabilityTests {
    @Test
    func `disk failure reopens closed then retry persists mixed payloads without rewriting historical bytes`() throws {
        try withPhaseFiveMigrationStore { url in
            let closed = try saleReversalClosedFixture()
            let lifetime = SaleReversalLifetime()
            let originals = try failReversalOnDisk(at: url, closed: closed, lifetime: lifetime)
            #expect(lifetime.container == nil)
            try verifyClosedReversalDisk(
                at: url,
                closed: closed,
                originals: originals,
                lifetime: lifetime
            )
            #expect(lifetime.container == nil)
            let complete = try acceptReversalOnDisk(at: url, closed: closed, lifetime: lifetime)
            #expect(lifetime.container == nil)
            #expect(complete.count == 7)
            #expect(originals.allSatisfy { complete[$0.key] == $0.value })
            for _ in 0..<2 {
                try verifyAcceptedReversalDisk(
                    at: url,
                    closed: closed,
                    bytes: complete,
                    lifetime: lifetime
                )
                #expect(lifetime.container == nil)
            }
        }
    }
}

@MainActor
private func failReversalOnDisk(at url: URL, closed: Sale, lifetime: SaleReversalLifetime) throws -> [UUID: Data] {
    let container = try stockSyncDiskContainer(at: url)
    lifetime.container = container
    try seedSaleReversal(closed, in: container)
    let context = container.mainContext
    _ = try StockLocalDataSource().append(
        stockTestMovement(productID: saleStockProductID(1), delta: 10, ordinal: 70),
        in: context
    )
    let before = try stockPayloads(in: context)
    let source = saleReversalDataSource(save: { staged in
        #expect(try staged.fetchCount(FetchDescriptor<StockMovementModel>()) == 7)
        #expect(try staged.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 1)
        #expect(try SaleLocalDataSource().sale(id: closed.id, in: ModelContext(container)) == closed)
        throw AtomicPaymentFailure.commit
    })
    #expect(throws: SaleReversalError.persistenceUnavailable) {
        try saleReversalSourceVoid(closed, source: source, in: context)
    }
    #expect(!context.hasChanges)
    return before
}

@MainActor
private func verifyClosedReversalDisk(
    at url: URL,
    closed: Sale,
    originals: [UUID: Data],
    lifetime: SaleReversalLifetime
) throws {
    let container = try stockSyncDiskContainer(at: url)
    lifetime.container = container
    let context = ModelContext(container)
    #expect(try SaleLocalDataSource().sale(id: closed.id, in: context) == closed)
    #expect(try stockPayloads(in: context) == originals)
    #expect(try SaleLocalDataSource().pendingOperations(in: context).isEmpty)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == 5)
}

@MainActor
private func acceptReversalOnDisk(at url: URL, closed: Sale, lifetime: SaleReversalLifetime) throws -> [UUID: Data] {
    let container = try stockSyncDiskContainer(at: url)
    lifetime.container = container
    _ = try saleReversalSourceVoid(closed, in: container.mainContext)
    return try stockPayloads(in: ModelContext(container))
}

@MainActor
private func verifyAcceptedReversalDisk(
    at url: URL,
    closed: Sale,
    bytes: [UUID: Data],
    lifetime: SaleReversalLifetime
) throws {
    let container = try stockSyncDiskContainer(at: url)
    lifetime.container = container
    let context = container.mainContext
    let queue = try SaleLocalDataSource().pendingOperations(in: context)
    #expect(queue.map(\.operationID) == [saleStockUUID(0x98, 1)])
    #expect(try saleReversalSourceVoid(
        closed,
        source: saleReversalDataSource(save: { _ in throw AtomicPaymentFailure.unexpectedSave }),
        in: context
    ) == saleReversalVoidedFixture(closed))
    #expect(try stockPayloads(in: ModelContext(container)) == bytes)
    #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)) == queue)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(1), in: context) == 10)
    #expect(try StockLocalDataSource().quantity(for: saleStockProductID(2), in: context) == 0)
    let versions = try context.fetch(FetchDescriptor<StockMovementModel>()).map(\.payloadVersion).sorted()
    #expect(versions == [1, 2, 2, 2, 3, 3, 3])
}
