/// An actor-isolated Services repository for previews and deterministic tests.
actor InMemoryServiceRepository: ServiceRepository {
    private var services: [Service]
    private let productRepository: any ProductRepository

    init(services: [Service] = [], productRepository: any ProductRepository = InMemoryProductRepository()) {
        self.services = services
        self.productRepository = productRepository
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

extension InMemoryServiceRepository {
    func service(id: ServiceID) async throws -> Service? {
        try Task.checkCancellation()
        return services.first { $0.id == id }
    }

    func createService(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        try Task.checkCancellation()
        guard !services.contains(where: { $0.id == id }) else { throw ServiceError.alreadyExists }
        try await validateProductLink(profile)
        try Task.checkCancellation()
        guard !services.contains(where: { $0.id == id }) else { throw ServiceError.alreadyExists }
        let service = try Service(
            id: id,
            name: profile.name,
            type: profile.type,
            linkedProductID: profile.linkedProductID,
            price: profile.price,
            taxRate: profile.taxRate,
            discount: profile.discount,
            status: .active
        )
        services.append(service)
        return service
    }

    func updateService(id: ServiceID, profile: ServiceProfile) async throws -> Service {
        try Task.checkCancellation()
        guard services.contains(where: { $0.id == id }) else { throw ServiceError.notFound }
        try await validateProductLink(profile)
        try Task.checkCancellation()
        guard let index = services.firstIndex(where: { $0.id == id }) else { throw ServiceError.notFound }
        let service = try Service(
            id: id,
            name: profile.name,
            type: profile.type,
            linkedProductID: profile.linkedProductID,
            price: profile.price,
            taxRate: profile.taxRate,
            discount: profile.discount,
            status: services[index].status
        )
        services[index] = service
        return service
    }

    func deactivateService(_ id: ServiceID) async throws {
        try Task.checkCancellation()
        guard let index = services.firstIndex(where: { $0.id == id }) else { throw ServiceError.notFound }
        let service = services[index]
        guard service.status != .inactive else { return }
        services[index] = try Service(
            id: service.id,
            name: service.name,
            type: service.type,
            linkedProductID: service.linkedProductID,
            price: service.price,
            taxRate: service.taxRate,
            discount: service.discount,
            status: .inactive
        )
    }
}

private extension InMemoryServiceRepository {
    func validateProductLink(_ profile: ServiceProfile) async throws {
        guard let id = profile.linkedProductID else { return }
        do {
            _ = try await GetLinkableProductUseCase(repository: productRepository)(id)
        } catch let error as ServiceError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw ServiceError.persistenceUnavailable
        }
    }
}
