extension AppDependencies {
    /// Shares Service persistence and active Product observation without retaining the caller's context.
    static func serviceFormFactory(
        persistenceActor: ServicePersistenceActor,
        observationSignal: ServiceObservationSignal,
        productRepository: any ProductRepository,
        assistant: (any ServiceDraftInterpreter)? = nil
    ) -> ServiceFormFactory {
        let repository = DefaultServiceRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        return { destination, locale in
            let adapter = ServiceContextualPersistenceAdapter(observationSignal: observationSignal)
            return ServiceFormViewModel(
                destination: destination,
                getService: GetServiceUseCase(repository: repository),
                observeLinkableProducts: ObserveLinkableProductsUseCase(repository: productRepository),
                create: { id, profile, context in
                    try await adapter.create(id: id, profile: profile, in: context)
                },
                update: { id, profile, context in
                    try await adapter.update(id: id, profile: profile, in: context)
                },
                deactivate: { id, context in
                    try await adapter.deactivate(id, in: context)
                },
                locale: locale,
                assistant: assistant
            )
        }
    }

    /// Supplies finite snapshot reads and rejects writes before accessing the caller's context.
    static func readOnlyServiceFormFactory(
        repository: any ServiceRepository,
        productRepository: any ProductRepository
    ) -> ServiceFormFactory {
        { destination, locale in
            ServiceFormViewModel(
                destination: destination,
                getService: GetServiceUseCase(repository: repository),
                observeLinkableProducts: ObserveLinkableProductsUseCase(repository: productRepository),
                create: { _, _, _ in
                    throw ServiceError.persistenceUnavailable
                },
                update: { _, _, _ in
                    throw ServiceError.persistenceUnavailable
                },
                deactivate: { _, _ in
                    throw ServiceError.persistenceUnavailable
                },
                locale: locale
            )
        }
    }
}
