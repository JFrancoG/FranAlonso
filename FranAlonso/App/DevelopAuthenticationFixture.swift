#if FRANALONSO_AUTH_FIXTURE
import SwiftData

/// A deterministic Develop-only authentication composition with no live service dependencies.
struct DevelopAuthenticationFixture {
    enum Mode: Equatable {
        case signedOut
        case restoredSession
    }

    static let signedOutLaunchArgument = "--franalonso-auth-fixture-signed-out"
    static let restoredSessionLaunchArgument = "--franalonso-auth-fixture-restored-session"
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
        mode: Mode,
        biometricAuthenticator: BiometricAuthenticator = .localAuthentication()
    ) throws -> DevelopAuthenticationFixture {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        let dependencies = AppDependencies.local(
            modelContainer: container,
            analyticsDataSource: DevelopAnalyticsDataSource(),
            crashDataSource: DevelopCrashDataSource()
        )
        let dataSource = DevelopAuthenticationDataSource(
            initialState: mode == .signedOut ? .signedOut : .restoredSession
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
