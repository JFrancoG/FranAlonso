/// An actor-isolated Services repository for previews and deterministic tests.
actor InMemoryServiceRepository: ServiceRepository {
    private var services: [Service]

    init(services: [Service] = []) {
        self.services = services
    }

    /// Emits the current in-memory snapshot once and then finishes.
    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(services)
            continuation.finish()
        }
    }

    /// Inserts a service or replaces the snapshot with the same stable identity.
    func saveService(_ service: Service) async throws {
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
        } else {
            services.append(service)
        }
    }
}
