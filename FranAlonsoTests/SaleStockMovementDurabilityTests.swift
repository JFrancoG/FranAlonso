import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Durable sale stock consumption")
struct SaleStockMovementDurabilityTests {
    @Test
    @MainActor
    func `sale movements preserve bytes identity pending state and replay after two complete reopenings`() async throws {
        let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appending(path: "sale-stock.store")
        let sale = try saleStockFixture()
        let lifetime = SaleStockLifetime()
        let payloads = try await acceptSaleStockOnDisk(at: url, sale: sale, lifetime: lifetime)
        #expect(payloads.count == 3)
        #expect(lifetime.container == nil)
        #expect(lifetime.writer == nil)
        try await replaySaleStockOnDisk(
            at: url,
            sale: sale,
            payloads: payloads,
            lifetime: lifetime
        )
        #expect(lifetime.container == nil)
        #expect(lifetime.writer == nil)
        try verifySaleStockOnDisk(at: url, payloads: payloads, lifetime: lifetime)
        #expect(lifetime.container == nil)
    }
}

@MainActor
private final class SaleStockLifetime {
    weak var container: ModelContainer?
    weak var writer: StockPersistenceActor?
}

private func saleStockDiskContainer(at url: URL) throws -> ModelContainer {
    let schema = Schema(versionedSchema: StockMovementsSchema.self)
    let configuration = ModelConfiguration(
        "SaleStockDurability",
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
private func acceptSaleStockOnDisk(at url: URL, sale: Sale, lifetime: SaleStockLifetime) async throws -> [UUID: Data] {
    let container = try saleStockDiskContainer(at: url)
    _ = try saleStockRepository(in: container)
    let writer = StockPersistenceActor(modelContainer: container)
    let repository = DefaultStockRepository(persistenceActor: writer, observationSignal: ProductObservationSignal())
    lifetime.container = container
    lifetime.writer = writer
    _ = try await CreateSaleStockMovementsUseCase(repository: repository)(sale: sale, paymentID: saleStockPaymentID)
    return try stockPayloads(in: ModelContext(container))
}

@MainActor
private func replaySaleStockOnDisk(
    at url: URL,
    sale: Sale,
    payloads: [UUID: Data],
    lifetime: SaleStockLifetime
) async throws {
    let container = try saleStockDiskContainer(at: url)
    let writer = StockPersistenceActor(modelContainer: container)
    let repository = DefaultStockRepository(persistenceActor: writer, observationSignal: ProductObservationSignal())
    lifetime.container = container
    lifetime.writer = writer
    let result = try await CreateSaleStockMovementsUseCase(repository: repository)(
        sale: sale,
        paymentID: saleStockPaymentID
    )
    #expect(result.count == 3)
    #expect(result.map(\.quantityDelta) == [-2, -3, -4])
    #expect(result.map(\.origin) == sale.lines.prefix(3).map {
        .sale(saleID: sale.id, lineID: $0.id, paymentID: saleStockPaymentID)
    })
    #expect(result.allSatisfy { $0.occurredAt == Date(timeIntervalSinceReferenceDate: 100.125) })
    #expect(try stockPayloads(in: ModelContext(container)) == payloads)
    #expect(try await repository.quantity(for: saleStockProductID(1)) == -5)
    #expect(try await repository.quantity(for: saleStockProductID(2)) == -4)
}

@MainActor
private func verifySaleStockOnDisk(at url: URL, payloads: [UUID: Data], lifetime: SaleStockLifetime) throws {
    let container = try saleStockDiskContainer(at: url)
    lifetime.container = container
    let context = ModelContext(container)
    #expect(try stockPayloads(in: context) == payloads)
    let rows = try context.fetch(FetchDescriptor<StockMovementModel>())
    #expect(rows.count == 3)
    #expect(rows.allSatisfy { $0.isPendingSync && $0.payloadVersion == 2 })
    let source = StockLocalDataSource()
    #expect(try source.quantity(for: saleStockProductID(1), in: context) == -5)
    #expect(try source.quantity(for: saleStockProductID(2), in: context) == -4)
    #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 0)
    #expect(try context.fetchCount(FetchDescriptor<ProductPendingUpsertModel>()) == 0)
}
