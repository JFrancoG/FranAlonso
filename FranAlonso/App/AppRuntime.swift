import Observation
import SwiftData

/// Owns application-lifetime local and remote composition without starting sync work.
@Observable
@MainActor
final class AppRuntime {
    let dependencies: AppDependencies
    private let modelContainer: ModelContainer
    private let persistenceActor: ClientPersistenceActor
    private let observationSignal: ClientObservationSignal
    private let productPersistenceActor: ProductPersistenceActor
    private let productObservationSignal: ProductObservationSignal
    private let servicePersistenceActor: ServicePersistenceActor
    private let serviceObservationSignal: ServiceObservationSignal
    private let salePersistenceActor: SalePersistenceActor
    private let saleObservationSignal: SaleObservationSignal
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
    private let makeSaleRemoteDataSource: (
        FirestoreEnvironment
    ) -> any SaleRemoteDataSource
    private let makeAuthenticationRootViewModel: @MainActor (
        ModelContainer
    ) -> AuthenticationRootViewModel
    private(set) var clientSyncEngine: ClientSyncEngine?
    private(set) var productSyncEngine: ProductSyncEngine?
    private(set) var serviceSyncEngine: ServiceSyncEngine?
    private(set) var saleSyncEngine: SaleSyncEngine?
    private(set) var authenticationRootViewModel: AuthenticationRootViewModel?

    /// Creates the shared local runtime for one explicit backend environment.
    ///
    /// Remote factories remain unused until Firebase configuration succeeds. Creating the
    /// resulting engines never starts synchronization; a later approved trigger must call them.
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
        },
        makeSaleRemoteDataSource: @escaping (
            FirestoreEnvironment
        ) -> any SaleRemoteDataSource = {
            FirestoreSaleRemoteDataSource(environment: $0)
        },
        makeAuthenticationRootViewModel: @escaping @MainActor (
            ModelContainer
        ) -> AuthenticationRootViewModel = { modelContainer in
            let dataSource = FirebaseAuthenticationDataSource()
            let repository = DefaultAuthenticationRepository(dataSource: dataSource)
            let localDataSource = KeychainLocalPrincipalDataSource(modelContainer: modelContainer)
            let localAuthorizer = LocalPrincipalAuthorizer { session in
                try await localDataSource.authorize(principalID: session.id)
            }

            return AuthenticationRootViewModel(
                signIn: SignInUseCase(repository: repository),
                observeSession: ObserveSessionUseCase(repository: repository),
                signOut: SignOutUseCase(repository: repository),
                biometricAuthenticator: .localAuthentication(),
                authorizeLocalPrincipal: AuthorizeLocalPrincipalUseCase(authorizer: localAuthorizer)
            )
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
        let salePersistenceActor = SalePersistenceActor(
            modelContainer: modelContainer
        )
        let saleObservationSignal = SaleObservationSignal()

        self.modelContainer = modelContainer
        self.persistenceActor = persistenceActor
        self.observationSignal = observationSignal
        self.productPersistenceActor = productPersistenceActor
        self.productObservationSignal = productObservationSignal
        self.servicePersistenceActor = servicePersistenceActor
        self.serviceObservationSignal = serviceObservationSignal
        self.salePersistenceActor = salePersistenceActor
        self.saleObservationSignal = saleObservationSignal
        self.environment = environment
        self.makeClientRemoteDataSource = makeClientRemoteDataSource
        self.makeProductRemoteDataSource = makeProductRemoteDataSource
        self.makeServiceRemoteDataSource = makeServiceRemoteDataSource
        self.makeSaleRemoteDataSource = makeSaleRemoteDataSource
        self.makeAuthenticationRootViewModel = makeAuthenticationRootViewModel
        dependencies = .live(
            persistenceActor: persistenceActor,
            observationSignal: observationSignal,
            productPersistenceActor: productPersistenceActor,
            productObservationSignal: productObservationSignal,
            servicePersistenceActor: servicePersistenceActor,
            serviceObservationSignal: serviceObservationSignal,
            salePersistenceActor: salePersistenceActor,
            saleObservationSignal: saleObservationSignal
        )
    }

    /// Composes the application authentication root once Firebase is ready.
    ///
    /// Construction is idempotent and is the only point that resolves the live Firebase Auth,
    /// LocalAuthentication, Keychain and local-store inspection adapters.
    ///
    /// - Parameter firebaseIsConfigured: Whether the default Firebase app is available.
    func activateAuthentication(firebaseIsConfigured: Bool) {
        guard firebaseIsConfigured, authenticationRootViewModel == nil else {
            return
        }

        authenticationRootViewModel = makeAuthenticationRootViewModel(modelContainer)
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

    /// Composes the inactive Sales sync engine once Firebase is ready.
    ///
    /// - Parameter firebaseIsConfigured: Whether the default Firebase app is available.
    func activateSaleSync(firebaseIsConfigured: Bool) {
        guard firebaseIsConfigured, saleSyncEngine == nil else {
            return
        }

        saleSyncEngine = SaleSyncEngine(
            persistenceActor: salePersistenceActor,
            remoteDataSource: makeSaleRemoteDataSource(environment),
            observationSignal: saleObservationSignal
        )
    }
}
