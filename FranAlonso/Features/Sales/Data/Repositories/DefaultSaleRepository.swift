import Foundation

/// Provides Sales Domain access backed exclusively by the local SwiftData source of truth.
///
/// Saves complete after the sale and its pending remote operation are committed locally.
/// Remote execution belongs to `SaleSyncEngine` and is intentionally not started here.
struct DefaultSaleRepository: SaleRepository {
    private let persistenceActor: SalePersistenceActor
    private let observationSignal: SaleObservationSignal
    private let makeOperationID: @Sendable () -> UUID

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        let changes = await observationSignal.stream()
        let pair = AsyncThrowingStream<[Sale], any Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
        let observationTask = Task {
            do {
                for await _ in changes {
                    try Task.checkCancellation()
                    pair.continuation.yield(try await persistenceActor.fetchAll())
                }
                pair.continuation.finish()
            } catch {
                pair.continuation.finish(throwing: error)
            }
        }
        pair.continuation.onTermination = { _ in
            observationTask.cancel()
        }
        return pair.stream
    }

    func saveSale(_ sale: Sale) async throws {
        try await persistenceActor.persistPendingUpsert(sale, operationID: makeOperationID())
        await observationSignal.publishChange()
    }

    func sale(id: SaleID) async throws -> Sale? {
        try await persistenceActor.sale(id: id)
    }

    func createDraft(_ draft: Sale) async throws {
        try await persistenceActor.createDraft(draft, operationID: makeOperationID())
        await observationSignal.publishChange()
    }

    func updateDraft(_ expected: Sale, clientID: ClientID?, lines: [SaleLine]) async throws -> Sale {
        let draft = try await persistenceActor.updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            operationID: makeOperationID()
        )
        await observationSignal.publishChange()
        return draft
    }

    func discardDraft(_ id: SaleID) async throws {
        try await persistenceActor.discardDraft(id, operationID: makeOperationID())
        await observationSignal.publishChange()
    }
}

extension DefaultSaleRepository {
    /// Creates a local-first repository from its isolated persistence and observation roles.
    ///
    /// - Parameters:
    ///   - persistenceActor: The actor that owns the context-free SwiftData route.
    ///   - observationSignal: The shared invalidation used by every local write route.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        persistenceActor: SalePersistenceActor,
        observationSignal: SaleObservationSignal,
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            makeOperationID: operationID
        )
    }
}
