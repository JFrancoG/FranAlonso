import Foundation
import SwiftData
import Testing

@testable import FranAlonso

@Suite("Durable Stock synchronization")
@MainActor
struct StockSyncDurabilityTests {
    @Test
    func `reopen retains pending conflicts accepted identities cursor and independent retry scopes`() throws {
        try withPhaseFiveMigrationStore { url in
            let product = try stockTestProduct()
            let local = try stockTestMovement(productID: product.id, delta: -1, ordinal: 1)
            let pending = try stockTestMovement(productID: product.id, delta: 2, ordinal: 2)
            let accepted = try stockTestMovement(productID: product.id, delta: -5, ordinal: 3)
            let remote = try stockSyncTestRecord(
                stockTestMovement(productID: product.id, delta: -7, ordinal: 1),
                sequence: 1
            )
            let pull = try SyncRetryState(
                scope: .pull,
                backoffStep: 6,
                notBefore: Date(timeIntervalSinceReferenceDate: 500),
                lastRecoverableCategory: .unavailable
            )
            let push = try SyncRetryState(
                scope: .operation(pending.id.rawValue),
                backoffStep: 2,
                notBefore: Date(timeIntervalSinceReferenceDate: 400),
                lastRecoverableCategory: .aborted
            )
            var bytes: [UUID: Data] = [:]
            weak var lifetime: ModelContainer?
            do {
                let container = try stockSyncDiskContainer(at: url)
                lifetime = container
                try seedStockTestProduct(product, in: container)
                let context = ModelContext(container)
                context.insert(try StockMovementModel(local))
                context.insert(try StockMovementModel(pending))
                try context.save()
                let source = StockSyncLocalDataSource()
                try source.reconcile(
                    StockRemoteChangeBatch(
                        records: [remote, stockSyncTestRecord(accepted, sequence: 2)],
                        nextCursor: StockSyncCursor(changeSequence: 2)
                    ),
                    in: context
                )
                try source.persistRetry(pull, in: context)
                try source.persistRetry(push, in: context)
                bytes = try stockPayloads(in: context)
            }
            #expect(lifetime == nil)
            for _ in 0..<2 {
                do {
                    let container = try stockSyncDiskContainer(at: url)
                    lifetime = container
                    let context = ModelContext(container)
                    let source = StockSyncLocalDataSource()
                    #expect(try stockPayloads(in: context) == bytes)
                    #expect(try source.pending(in: context) == [pending])
                    #expect(try source.conflicts(in: context).first?.remote == remote)
                    #expect(try source.conflicts(in: context).first?.local.toDomain() == local)
                    #expect(try source.cursor(in: context)?.changeSequence == 2)
                    #expect(try source.retryState(for: .pull, in: context) == pull)
                    #expect(try source.retryState(for: .operation(pending.id.rawValue), in: context) == push)
                    #expect(try context.fetchCount(FetchDescriptor<StockRemoteStateModel>()) == 1)
                    #expect(try StockLocalDataSource().quantity(for: product.id, in: context) == -4)
                    #expect(
                        try #require(
                            context.fetch(FetchDescriptor<StockMovementModel>()).first { $0.id == accepted.id.rawValue }
                        ).isPendingSync == false
                    )
                }
                #expect(lifetime == nil)
            }
        }
    }

    @Test
    func `failed acknowledgement retains pending payload and operation retry on disk`() throws {
        try withPhaseFiveMigrationStore { url in
            let product = try stockTestProduct()
            let movement = try stockTestMovement(productID: product.id, delta: -3, ordinal: 1)
            let state = try SyncRetryState(
                scope: .operation(movement.id.rawValue),
                backoffStep: 3,
                notBefore: Date(timeIntervalSinceReferenceDate: 400),
                lastRecoverableCategory: .deadlineExceeded
            )
            var bytes: [UUID: Data] = [:]
            weak var lifetime: ModelContainer?
            let release = StockSyncDiskLifetime()
            bytes = try failStockSyncAcknowledgement(
                at: url,
                product: product,
                movement: movement,
                state: state,
                lifetime: release
            )
            #expect(release.container == nil)
            do {
                let container = try stockSyncDiskContainer(at: url)
                lifetime = container
                let context = ModelContext(container)
                #expect(try stockPayloads(in: context) == bytes)
                #expect(try StockSyncLocalDataSource().pending(in: context) == [movement])
                #expect(try StockSyncLocalDataSource().retryState(for: state.scope, in: context) == state)
                #expect(try context.fetchCount(FetchDescriptor<StockRemoteStateModel>()) == 0)
                try StockSyncLocalDataSource().acknowledge(
                    movement,
                    record: stockSyncTestRecord(movement, sequence: 9),
                    in: context
                )
            }
            #expect(lifetime == nil)
            let reopened = try stockSyncDiskContainer(at: url)
            let context = ModelContext(reopened)
            #expect(try stockPayloads(in: context) == bytes)
            #expect(try StockSyncLocalDataSource().pending(in: context).isEmpty)
            #expect(try StockSyncLocalDataSource().retryState(for: state.scope, in: context) == nil)
            #expect(try context.fetchCount(FetchDescriptor<StockRemoteStateModel>()) == 1)
        }
    }
}

func stockSyncDiskContainer(at url: URL) throws -> ModelContainer {
    let schema = Schema(versionedSchema: StockSyncSchema.self)
    let configuration = ModelConfiguration(
        "StockSyncDurability",
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
private final class StockSyncDiskLifetime {
    weak var container: ModelContainer?
}

@MainActor
private func failStockSyncAcknowledgement(
    at url: URL,
    product: Product,
    movement: StockMovement,
    state: SyncRetryState,
    lifetime: StockSyncDiskLifetime
) throws -> [UUID: Data] {
    let container = try stockSyncDiskContainer(at: url)
    lifetime.container = container
    try seedStockTestProduct(product, in: container)
    let context = ModelContext(container)
    context.insert(try StockMovementModel(movement))
    try context.save()
    try StockSyncLocalDataSource().persistRetry(state, in: context)
    let bytes = try stockPayloads(in: context)
    let source = StockSyncLocalDataSource(save: { _ in throw StockSyncError.storageFailure })
    #expect(throws: StockSyncError.storageFailure) {
        try source.acknowledge(movement, record: stockSyncTestRecord(movement, sequence: 9), in: context)
    }
    #expect(!context.hasChanges)
    return bytes
}
