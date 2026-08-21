#if FRANALONSO_AUTH_FIXTURE
import SwiftData

/// A deterministic Develop-only authentication composition with no live service dependencies.
struct DevelopAuthenticationFixture {
    enum Mode: Equatable {
        case signedOut
        case restoredSession
    }

    enum ClientsMode: Equatable {
        case standard
        case observationError
    }

    struct Configuration: Equatable {
        let authenticationMode: Mode
        let clientsMode: ClientsMode

        private init(
            authenticationMode: Mode,
            clientsMode: ClientsMode
        ) {
            self.authenticationMode = authenticationMode
            self.clientsMode = clientsMode
        }

        static func standard(_ authenticationMode: Mode) -> Configuration {
            Configuration(
                authenticationMode: authenticationMode,
                clientsMode: .standard
            )
        }

        static let clientsObservationError = Configuration(
            authenticationMode: .restoredSession,
            clientsMode: .observationError
        )
    }

    static let signedOutLaunchArgument = "--franalonso-auth-fixture-signed-out"
    static let restoredSessionLaunchArgument = "--franalonso-auth-fixture-restored-session"
    static let clientsObservationErrorLaunchArgument = "--franalonso-clients-fixture-observation-error"
    static let principalID = "fixture-auth-principal-v1"
    static let email = "accessibility@franalonso.invalid"
    static let password = "FranAlonso-Fixture-Only"

    let modelContainer: ModelContainer
    let dependencies: AppDependencies
    let authenticationRootViewModel: AuthenticationRootViewModel

    @MainActor
    var applicationComposition: ApplicationComposition {
        ApplicationComposition(
            modelContainer: modelContainer,
            dependencies: dependencies,
            runtime: nil,
            authenticationRootViewModel: authenticationRootViewModel
        )
    }

    /// Composes real application layers over isolated local storage and deterministic auth state.
    @MainActor
    static func make(
        configuration: Configuration,
        biometricAuthenticator: BiometricAuthenticator = .localAuthentication()
    ) throws -> DevelopAuthenticationFixture {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        let clientRepository: (any ClientRepository)? = switch configuration.clientsMode {
        case .standard:
            nil
        case .observationError:
            DevelopClientErrorRepository()
        }
        let dependencies = AppDependencies.local(
            modelContainer: container,
            analyticsDataSource: DevelopAnalyticsDataSource(),
            crashDataSource: DevelopCrashDataSource(),
            clientRepository: clientRepository
        )
        let dataSource = DevelopAuthenticationDataSource(
            initialState: configuration.authenticationMode == .signedOut ? .signedOut : .restoredSession
        )
        let repository = DefaultAuthenticationRepository(dataSource: dataSource)
        let root = AuthenticationRootViewModel(
            signIn: SignInUseCase(repository: repository),
            observeSession: ObserveSessionUseCase(repository: repository),
            signOut: SignOutUseCase(repository: repository),
            biometricAuthenticator: biometricAuthenticator,
            authorizeLocalPrincipal: AuthorizeLocalPrincipalUseCase(
                authorizer: localPrincipalAuthorizer()
            )
        )

        return DevelopAuthenticationFixture(
            modelContainer: container,
            dependencies: dependencies,
            authenticationRootViewModel: root
        )
    }

    /// Creates a fail-closed local terminal for malformed fixture arguments.
    @MainActor
    static func makeInvalidApplicationComposition() throws -> ApplicationComposition {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        let dependencies = AppDependencies.local(
            modelContainer: container,
            analyticsDataSource: DevelopAnalyticsDataSource(),
            crashDataSource: DevelopCrashDataSource()
        )

        return ApplicationComposition(
            modelContainer: container,
            dependencies: dependencies,
            runtime: nil,
            authenticationRootViewModel: nil
        )
    }

    /// Authorizes only the fake principal owned by this isolated fixture.
    static func localPrincipalAuthorizer() -> LocalPrincipalAuthorizer {
        LocalPrincipalAuthorizer { session in
            guard session.id == principalID else {
                throw LocalPrincipalAuthorizationError.differentPrincipal
            }
        }
    }
}

private struct DevelopAnalyticsDataSource: AnalyticsDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) {}

    func log(_ event: AnalyticsEvent) {}
}

private struct DevelopCrashDataSource: CrashDataSource {
    func setCollectionEnabled(_ isEnabled: Bool) {}

    func record(_ diagnostic: CrashDiagnostic) {}
}
#endif
