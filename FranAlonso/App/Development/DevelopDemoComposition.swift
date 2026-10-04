#if FRANALONSO_AUTH_FIXTURE
import SwiftData

/// Owns one isolated launch of the reusable client, product and service demonstration.
struct DevelopDemoComposition {
    enum Configuration: Equatable {
        case clients
        case clientsResponseLost
        case workday
    }

    let applicationComposition: ApplicationComposition
    let documentRemoteStore: InMemoryClientDocumentStorage.RemoteStore

    /// Seeds a fresh in-memory scenario before exposing real application capabilities.
    ///
    /// Authentication, persistence and document flows remain real; external auth, telemetry and document storage
    /// are isolated substitutes. A seed failure aborts composition without returning a partial scenario or runtime.
    @MainActor
    static func make(configuration: Configuration) throws -> DevelopDemoComposition {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        try DevelopDemoScenario.clients.seed(in: container)
        try DevelopDemoProductScenario.seed(in: container)
        try DevelopDemoServiceScenario.seed(in: container)
        if configuration == .workday {
            try SalesPreviewFixtures.workday.seed(in: container.mainContext)
            try SalesPreviewFixtures.history.seed(in: container.mainContext)
        }
        let remote = InMemoryClientDocumentStorage.RemoteStore()
        let storage = InMemoryClientDocumentStorage(
            remote: remote,
            failures: configuration == .clientsResponseLost ? [.responseLost] : []
        )
        let repository = DefaultAuthenticationRepository(
            dataSource: DevelopAuthenticationDataSource(initialState: .signedOut)
        )
        let root = AuthenticationRootViewModel(
            signIn: SignInUseCase(repository: repository),
            observeSession: ObserveSessionUseCase(repository: repository),
            signOut: SignOutUseCase(repository: repository),
            biometricAuthenticator: .localAuthentication(),
            authorizeLocalPrincipal: AuthorizeLocalPrincipalUseCase(
                authorizer: DevelopAuthenticationFixture.localPrincipalAuthorizer()
            )
        )
        let dependencies = AppDependencies.local(
            modelContainer: container,
            analyticsDataSource: DemoAnalyticsDataSource(),
            crashDataSource: DemoCrashDataSource(),
            authenticationRoot: root,
            clientDocumentStorage: storage,
            serviceDraftInterpreter: FoundationModelsServiceDraftInterpreter(),
            billingReservation: .demonstration(DevelopDemoBillingReservationRepository()),
            billingStorage: InMemoryBillingDocumentPDFStorageRepository(),
            billingComposer: DevelopDemoBillingPDFComposer()
        )
        return DevelopDemoComposition(
            applicationComposition: ApplicationComposition(
                modelContainer: container,
                dependencies: dependencies,
                runtime: nil,
                authenticationRootViewModel: root,
                demoConfiguration: configuration
            ),
            documentRemoteStore: remote
        )
    }
}

private struct DemoAnalyticsDataSource: AnalyticsDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) {}

    func log(_ event: AnalyticsEvent) {}
}

private struct DemoCrashDataSource: CrashDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) {}

    func record(_ diagnostic: CrashDiagnostic) {}
}
#endif
