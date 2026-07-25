import Foundation

/// Provides Clients Domain access backed exclusively by the local SwiftData source of truth.
///
/// Saves complete after the client and its pending remote operation are committed locally.
/// Remote execution belongs to `ClientSyncEngine` and is intentionally not started here.
struct DefaultClientRepository: ClientRepository {
    private let persistenceActor: ClientPersistenceActor
    private let observationSignal: ClientObservationSignal
    private let makeOperationID: @Sendable () -> UUID

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        let changes = await observationSignal.stream()
        let pair = AsyncThrowingStream<[Client], any Error>.makeStream(
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

    func saveClient(_ client: Client) async throws {
        try await persistenceActor.persistPendingUpsert(
            client,
            operationID: makeOperationID()
        )
        await observationSignal.publishChange()
    }
}

extension DefaultClientRepository {
    /// Creates a local-first repository from its isolated persistence and observation roles.
    ///
    /// - Parameters:
    ///   - persistenceActor: The actor that owns the context-free SwiftData route.
    ///   - observationSignal: The shared invalidation used by every local write route.
    ///   - operationID: A deterministic operation-identity source, injectable for tests.
    init(
        persistenceActor: ClientPersistenceActor,
        observationSignal: ClientObservationSignal,
        operationID: @escaping @Sendable () -> UUID = { UUID() }
    ) {
        self.init(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            makeOperationID: operationID
        )
    }
}
