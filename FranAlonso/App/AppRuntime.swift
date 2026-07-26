import SwiftData

/// Owns the application-lifetime Clients composition without starting remote work.
@MainActor
final class AppRuntime {
    let dependencies: AppDependencies
    private let persistenceActor: ClientPersistenceActor
    private let observationSignal: ClientObservationSignal
    private let environment: FirestoreEnvironment
    private let makeRemoteDataSource: (
        FirestoreEnvironment
    ) -> any ClientRemoteDataSource
    private(set) var clientSyncEngine: ClientSyncEngine?

    /// Creates the shared local runtime for one explicit backend environment.
    ///
    /// The remote factory remains unused until Firebase configuration succeeds. Creating the
    /// resulting engine never starts synchronization; a later approved trigger must call it.
    init(
        modelContainer: ModelContainer,
        environment: FirestoreEnvironment,
        makeRemoteDataSource: @escaping (
            FirestoreEnvironment
        ) -> any ClientRemoteDataSource = {
            FirestoreClientRemoteDataSource(environment: $0)
        }
    ) {
        let persistenceActor = ClientPersistenceActor(
            modelContainer: modelContainer
        )
        let observationSignal = ClientObservationSignal()

        self.persistenceActor = persistenceActor
        self.observationSignal = observationSignal
        self.environment = environment
        self.makeRemoteDataSource = makeRemoteDataSource
        dependencies = .live(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal
        )
    }

    /// Composes the inactive Clients sync engine once Firebase is ready.
    ///
    /// - Parameter firebaseIsConfigured: Whether the default Firebase app is available.
    func activateClientSync(firebaseIsConfigured: Bool) {
        guard firebaseIsConfigured, clientSyncEngine == nil else {
            return
        }

        clientSyncEngine = ClientSyncEngine(
            persistenceActor: persistenceActor,
            remoteDataSource: makeRemoteDataSource(environment),
            observationSignal: observationSignal
        )
    }
}
