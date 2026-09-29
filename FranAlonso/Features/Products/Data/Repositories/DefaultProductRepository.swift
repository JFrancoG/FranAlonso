import Foundation

/// Provides Products Domain access backed exclusively by the local SwiftData source of truth.
///
/// Saves complete after the product and its pending remote operation are committed locally.
/// Remote execution belongs to `ProductSyncEngine` and is intentionally not started here.
struct DefaultProductRepository: ProductRepository {
    private let persistenceActor: ProductPersistenceActor
    private let observationSignal: ProductObservationSignal
    private let makeOperationID: @Sendable () -> UUID

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        let changes = await observationSignal.stream()
        let pair = AsyncThrowingStream<[Product], any Error>.makeStream(bufferingPolicy: .bufferingNewest(1))
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

    func saveProduct(_ product: Product) async throws {
        try await persistenceActor.persistPendingUpsert(product, operationID: makeOperationID())
        await observationSignal.publishChange()
    }
}

extension DefaultProductRepository {
    /// Creates a local-first repository from its isolated persistence and observation roles.
    ///
    /// - Parameters:
    ///   - persistenceActor: The actor that owns the context-free SwiftData route.
    ///   - observationSignal: The shared invalidation used by every local write route.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        persistenceActor: ProductPersistenceActor,
        observationSignal: ProductObservationSignal,
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            makeOperationID: operationID
        )
    }
}

extension DefaultProductRepository {
    func product(id: ProductID) async throws -> Product? {
        try await persistenceActor.product(id: id)
    }

    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        let product = try await persistenceActor.createProduct(id: id, profile: profile, operationID: makeOperationID())
        await observationSignal.publishChange()
        return product
    }

    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        let product = try await persistenceActor.updateProduct(id: id, profile: profile, operationID: makeOperationID())
        await observationSignal.publishChange()
        return product
    }

    func deactivateProduct(_ id: ProductID) async throws {
        let changed = try await persistenceActor.deactivateProduct(id, operationID: makeOperationID())
        guard changed else { return }
        await observationSignal.publishChange()
    }
}
