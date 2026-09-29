extension AppDependencies {
    /// Shares runtime-owned Service persistence and invalidation without retaining the caller's context.
    static func serviceFormFactory(
        persistenceActor: ServicePersistenceActor,
        observationSignal: ServiceObservationSignal
    ) -> ServiceFormFactory {
        let repository = DefaultServiceRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        return { destination in
            let adapter = ServiceContextualPersistenceAdapter(observationSignal: observationSignal)
            return ServiceFormViewModel(
                destination: destination,
                getService: GetServiceUseCase(repository: repository),
                create: { id, profile, context in
                    try await adapter.create(id: id, profile: profile, in: context)
                },
                update: { id, profile, context in
                    try await adapter.update(id: id, profile: profile, in: context)
                },
                deactivate: { id, context in
                    try await adapter.deactivate(id, in: context)
                }
            )
        }
    }

    /// Supplies finite snapshot reads and rejects writes before accessing the caller's context.
    static func readOnlyServiceFormFactory(repository: any ServiceRepository) -> ServiceFormFactory {
        { destination in
            ServiceFormViewModel(
                destination: destination,
                getService: GetServiceUseCase(repository: repository),
                create: { _, _, _ in
                    throw ServiceError.persistenceUnavailable
                },
                update: { _, _, _ in
                    throw ServiceError.persistenceUnavailable
                },
                deactivate: { _, _ in
                    throw ServiceError.persistenceUnavailable
                }
            )
        }
    }
}
