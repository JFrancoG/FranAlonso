extension AppDependencies {
    /// Composes a form over the runtime's existing persistence and observation roles.
    /// The caller must supply contexts from the same container when invoking form mutations.
    /// Reading and contextual writing share invalidation; no new persistence actor or stream source is created.
    @MainActor
    static func makeClientFormViewModel(
        destination: ClientFormDestination,
        persistenceActor: ClientPersistenceActor,
        observationSignal: ClientObservationSignal
    ) -> ClientFormViewModel {
        let repository = DefaultClientRepository(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
        let adapter = ClientContextualPersistenceAdapter(observationSignal: observationSignal)
        return ClientFormViewModel(
            destination: destination,
            getClient: GetClientUseCase(repository: repository),
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
