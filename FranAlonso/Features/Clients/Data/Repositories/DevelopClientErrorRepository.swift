#if FRANALONSO_AUTH_FIXTURE
/// A deterministic Develop-only Clients failure for runtime error-state validation.
struct DevelopClientErrorRepository: ClientRepository {

    func client(id: ClientID) async throws -> Client? { throw ClientError.persistenceUnavailable }

    func createClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        throw ClientError.persistenceUnavailable
    }

    func updateClient(id: ClientID, profile: ClientProfile) async throws -> Client {
        throw ClientError.persistenceUnavailable
    }

    func deactivateClient(_ id: ClientID) async throws { throw ClientError.persistenceUnavailable }

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
