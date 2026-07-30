import Foundation

/// Provides Services Domain access backed exclusively by the local SwiftData source of truth.
///
/// Saves complete after the service and its pending remote operation are committed locally.
/// Remote execution belongs to `ServiceSyncEngine` and is intentionally not started here.
struct DefaultServiceRepository: ServiceRepository {
    private let persistenceActor: ServicePersistenceActor
    private let observationSignal: ServiceObservationSignal
    private let makeOperationID: @Sendable () -> UUID

    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        let changes = await observationSignal.stream()
        let pair = AsyncThrowingStream<[Service], any Error>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )
        let observationTask = Task {
            do {
                for await _ in changes {
                    try Task.checkCancellation()
                    pair.continuation.yield(
                        try await persistenceActor.fetchAll()
                    )
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

    func saveService(_ service: Service) async throws {
        try await persistenceActor.persistPendingUpsert(
            service,
            operationID: makeOperationID()
        )
        await observationSignal.publishChange()
    }
}

extension DefaultServiceRepository {
    /// Creates a local-first repository from its isolated persistence and observation roles.
    ///
    /// - Parameters:
    ///   - persistenceActor: The actor that owns the context-free SwiftData route.
    ///   - observationSignal: The shared invalidation used by every local write route.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        persistenceActor: ServicePersistenceActor,
        observationSignal: ServiceObservationSignal,
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            makeOperationID: operationID
        )
    }
}
