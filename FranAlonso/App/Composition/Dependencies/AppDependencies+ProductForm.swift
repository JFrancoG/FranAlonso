extension AppDependencies {
    /// Shares runtime-owned Product persistence and invalidation without retaining the caller's context.
    static func productFormFactory(
        persistenceActor: ProductPersistenceActor,
        observationSignal: ProductObservationSignal
    ) -> ProductFormFactory {
        let repository = DefaultProductRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        return { destination in
            let adapter = ProductContextualPersistenceAdapter(observationSignal: observationSignal)
            return ProductFormViewModel(
                destination: destination,
                getProduct: GetProductUseCase(repository: repository),
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
    static func readOnlyProductFormFactory(repository: any ProductRepository) -> ProductFormFactory {
        { destination in
            ProductFormViewModel(
                destination: destination,
                getProduct: GetProductUseCase(repository: repository),
                create: { _, _, _ in
                    throw ProductError.persistenceUnavailable
                },
                update: { _, _, _ in
                    throw ProductError.persistenceUnavailable
                },
                deactivate: { _, _ in
                    throw ProductError.persistenceUnavailable
                }
            )
        }
    }
}
