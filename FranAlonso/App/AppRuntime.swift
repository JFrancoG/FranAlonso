import SwiftData

/// Owns application-lifetime local and remote composition without starting sync work.
@MainActor
final class AppRuntime {
    let dependencies: AppDependencies
    private let persistenceActor: ClientPersistenceActor
    private let observationSignal: ClientObservationSignal
    private let productPersistenceActor: ProductPersistenceActor
    private let productObservationSignal: ProductObservationSignal
    private let servicePersistenceActor: ServicePersistenceActor
    private let serviceObservationSignal: ServiceObservationSignal
    private let environment: FirestoreEnvironment
    private let makeClientRemoteDataSource: (
        FirestoreEnvironment
    ) -> any ClientRemoteDataSource
    private let makeProductRemoteDataSource: (
        FirestoreEnvironment
    ) -> any ProductRemoteDataSource
    private let makeServiceRemoteDataSource: (
        FirestoreEnvironment
    ) -> any ServiceRemoteDataSource
    private(set) var clientSyncEngine: ClientSyncEngine?
    private(set) var productSyncEngine: ProductSyncEngine?
    private(set) var serviceSyncEngine: ServiceSyncEngine?

    /// Creates the shared local runtime for one explicit backend environment.
    ///
    /// The remote factory remains unused until Firebase configuration succeeds. Creating the
    /// resulting engine never starts synchronization; a later approved trigger must call it.
    init(
        modelContainer: ModelContainer,
        environment: FirestoreEnvironment,
        makeClientRemoteDataSource: @escaping (
            FirestoreEnvironment
        ) -> any ClientRemoteDataSource = {
            FirestoreClientRemoteDataSource(environment: $0)
        },
        makeProductRemoteDataSource: @escaping (
            FirestoreEnvironment
        ) -> any ProductRemoteDataSource = {
            FirestoreProductRemoteDataSource(environment: $0)
        },
        makeServiceRemoteDataSource: @escaping (
            FirestoreEnvironment
        ) -> any ServiceRemoteDataSource = {
            FirestoreServiceRemoteDataSource(environment: $0)
        }
    ) {
        let persistenceActor = ClientPersistenceActor(
            modelContainer: modelContainer
        )
        let observationSignal = ClientObservationSignal()
        let productPersistenceActor = ProductPersistenceActor(
            modelContainer: modelContainer
        )
        let productObservationSignal = ProductObservationSignal()
        let servicePersistenceActor = ServicePersistenceActor(
            modelContainer: modelContainer
        )
        let serviceObservationSignal = ServiceObservationSignal()

        self.persistenceActor = persistenceActor
        self.observationSignal = observationSignal
        self.productPersistenceActor = productPersistenceActor
        self.productObservationSignal = productObservationSignal
        self.servicePersistenceActor = servicePersistenceActor
        self.serviceObservationSignal = serviceObservationSignal
        self.environment = environment
        self.makeClientRemoteDataSource = makeClientRemoteDataSource
        self.makeProductRemoteDataSource = makeProductRemoteDataSource
        self.makeServiceRemoteDataSource = makeServiceRemoteDataSource
        dependencies = .live(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            productPersistenceActor: productPersistenceActor,
            productObservationSignal: productObservationSignal,
            servicePersistenceActor: servicePersistenceActor,
            serviceObservationSignal: serviceObservationSignal
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
            remoteDataSource: makeClientRemoteDataSource(environment),
            observationSignal: observationSignal
        )
    }

    /// Composes the inactive Products sync engine once Firebase is ready.
    ///
    /// - Parameter firebaseIsConfigured: Whether the default Firebase app is available.
    func activateProductSync(firebaseIsConfigured: Bool) {
        guard firebaseIsConfigured, productSyncEngine == nil else {
            return
        }

        productSyncEngine = ProductSyncEngine(
            persistenceActor: productPersistenceActor,
            remoteDataSource: makeProductRemoteDataSource(environment),
            observationSignal: productObservationSignal
        )
    }

    /// Composes the inactive Services sync engine once Firebase is ready.
    ///
    /// - Parameter firebaseIsConfigured: Whether the default Firebase app is available.
    func activateServiceSync(firebaseIsConfigured: Bool) {
        guard firebaseIsConfigured, serviceSyncEngine == nil else {
            return
        }

        serviceSyncEngine = ServiceSyncEngine(
            persistenceActor: servicePersistenceActor,
            remoteDataSource: makeServiceRemoteDataSource(environment),
            observationSignal: serviceObservationSignal
        )
    }
}
