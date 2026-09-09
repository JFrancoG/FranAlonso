extension AppDependencies {
    /// Captures runtime-owned Clients roles while leaving the calling screen's context ephemeral.
    static func clientFormFactory(
        persistenceActor: ClientPersistenceActor,
        observationSignal: ClientObservationSignal
    ) -> ClientFormFactory {
        { destination in
            makeClientFormViewModel(
                destination: destination,
                persistenceActor: persistenceActor,
                observationSignal: observationSignal
            )
        }
    }

    /// Allows deterministic snapshot reads while rejecting every mutation before touching its context.
    /// Injected tests and finite previews must choose this capability explicitly, without a live fallback.
    static func readOnlyClientFormFactory(repository: any ClientRepository) -> ClientFormFactory {
        { destination in
            ClientFormViewModel(
                destination: destination,
                getClient: GetClientUseCase(repository: repository),
                create: { _, _, _ in
                    throw ClientError.persistenceUnavailable
                },
                update: { _, _, _ in
                    throw ClientError.persistenceUnavailable
                },
                deactivate: { _, _ in
                    throw ClientError.persistenceUnavailable
                }
            )
        }
    }

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
