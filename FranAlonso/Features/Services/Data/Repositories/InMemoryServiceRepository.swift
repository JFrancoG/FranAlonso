actor InMemoryServiceRepository: ServiceRepository {
    private var services: [Service]

    init(services: [Service] = []) {
        self.services = services
    }

    func observeServices() async -> AsyncThrowingStream<[Service], any Error> {
        AsyncThrowingStream { continuation in
            continuation.yield(services)
            continuation.finish()
        }
    }

    func saveService(_ service: Service) async throws {
        if let index = services.firstIndex(where: { $0.id == service.id }) {
            services[index] = service
        } else {
            services.append(service)
        }
    }
}
