#if FRANALONSO_AUTH_FIXTURE
/// A deterministic Develop-only Clients failure for runtime error-state validation.
struct DevelopClientErrorRepository: ClientRepository {
    enum Failure: Error, Equatable {
        case unavailable
    }

    func observeClients() async -> AsyncThrowingStream<[Client], any Error> {
        AsyncThrowingStream { continuation in
            continuation.finish(throwing: Failure.unavailable)
        }
    }

    func saveClient(_ client: Client) async throws {
        throw Failure.unavailable
    }
}
#endif
