import SwiftData
import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Develop authentication fixture composition")
@MainActor
struct DevelopAuthenticationFixtureCompositionTests {
    @Test("Fixture selection never constructs the live runtime")
    func fixtureSelectionNeverConstructsLiveRuntime() throws {
        let liveFactory = ApplicationCompositionFactorySpy()
        let fixtureFactory = ApplicationCompositionFactorySpy()

        _ = try ApplicationComposition.make(
            plan: .authenticationFixture(.standard(.signedOut)),
            makeLive: liveFactory.make,
            makeFixture: fixtureFactory.make(configuration:),
            makeInvalidFixture: fixtureFactory.makeInvalid
        )

        #expect(liveFactory.liveInvocationCount == 0)
        #expect(fixtureFactory.fixtureConfigurations == [.standard(.signedOut)])
        #expect(fixtureFactory.invalidInvocationCount == 0)
    }

    @Test("The real fixture has no live runtime and all 28 schema tables start empty")
    func realFixtureHasNoLiveRuntimeAndStartsPristine() async throws {
        let composition = try ApplicationComposition.make(
            plan: .authenticationFixture(.standard(.signedOut))
        )
        let pristineDataSource = SwiftDataStorePristineDataSource(
            modelContainer: composition.modelContainer
        )

        #expect(composition.runtime == nil)
        #expect(composition.authenticationRootViewModel != nil)
        #expect(try await pristineDataSource.isPristine())
    }

    @Test("The fixture authorizer accepts only the exact deterministic principal")
    func fixtureAuthorizerAcceptsOnlyExactPrincipal() async {
        let authorizer = DevelopAuthenticationFixture.localPrincipalAuthorizer()

        await #expect(throws: Never.self) {
            try await authorizer.authorize(
                AuthenticationSession(id: DevelopAuthenticationFixture.principalID)
            )
        }
        await #expect(throws: LocalPrincipalAuthorizationError.differentPrincipal) {
            try await authorizer.authorize(
                AuthenticationSession(id: "different-fixture-principal")
            )
        }
    }

    @Test("Signed-out fixture traverses DataSource, Repository, Use Cases and root")
    func signedOutFixtureTraversesFullAuthenticationChain() async throws {
        let composition = try ApplicationComposition.make(
            plan: .authenticationFixture(.standard(.signedOut)),
            makeFixture: { configuration in
                try DevelopAuthenticationFixture.make(
                    configuration: configuration,
                    biometricAuthenticator: BiometricAuthenticator(
                        canAuthenticate: { true },
                        authenticate: { _ in }
                    )
                ).applicationComposition
            }
        )
        let root = try #require(composition.authenticationRootViewModel)
        let observation = Task { @MainActor in
            await root.sessionViewModel.load()
        }

        await waitUntil { root.sessionViewModel.sessionEventRevision == 1 }
        root.sessionEventDidChange()
        #expect(root.state == .signedOut)

        root.loginViewModel.email = DevelopAuthenticationFixture.email
        root.loginViewModel.password = DevelopAuthenticationFixture.password
        await root.loginViewModel.signIn()
        let session = try #require(root.loginViewModel.succeededSession)
        root.registerRecentSignIn(session)
        await waitUntil { root.sessionViewModel.sessionEventRevision == 2 }
        root.sessionEventDidChange()
        await root.authorizeLocalAccessIfNeeded()
        #expect(root.state == .authenticated(session))

        await root.signOut()
        await waitUntil { root.sessionViewModel.sessionEventRevision == 3 }
        root.sessionEventDidChange()
        #expect(root.state == .signedOut)

        observation.cancel()
        await observation.value
    }

    @Test("Restored fixture reaches a locked root without invoking sign in")
    func restoredFixtureReachesLockedRootWithoutSignIn() async throws {
        let composition = try ApplicationComposition.make(
            plan: .authenticationFixture(.standard(.restoredSession))
        )
        let root = try #require(composition.authenticationRootViewModel)
        let observation = Task { @MainActor in
            await root.sessionViewModel.load()
        }

        await waitUntil { root.sessionViewModel.sessionEventRevision == 1 }
        root.sessionEventDidChange()

        #expect(root.state == .locked)
        #expect(root.loginViewModel.state == .idle)

        observation.cancel()
        await observation.value
    }

    @Test("Invalid fixture configuration never constructs a live or auth fixture")
    func invalidFixtureConfigurationNeverConstructsOtherRoutes() throws {
        let liveFactory = ApplicationCompositionFactorySpy()
        let fixtureFactory = ApplicationCompositionFactorySpy()
        _ = try ApplicationComposition.make(
            plan: .invalidFixtureConfiguration,
            makeLive: liveFactory.make,
            makeFixture: fixtureFactory.make(configuration:),
            makeInvalidFixture: fixtureFactory.makeInvalid
        )

        #expect(liveFactory.liveInvocationCount == 0)
        #expect(fixtureFactory.fixtureConfigurations.isEmpty)
        #expect(fixtureFactory.invalidInvocationCount == 1)
    }

    @Test("The real invalid fixture composition is pristine and isolated")
    func realInvalidFixtureCompositionIsPristineAndIsolated() async throws {
        let composition = try ApplicationComposition.make(
            plan: .invalidFixtureConfiguration
        )
        let pristineDataSource = SwiftDataStorePristineDataSource(
            modelContainer: composition.modelContainer
        )

        #expect(composition.runtime == nil)
        #expect(composition.authenticationRootViewModel == nil)
        #expect(try await pristineDataSource.isPristine())
    }

    @Test("Clients error fixture traverses Repository, Use Case and ViewModel")
    func clientsErrorFixtureTraversesRealPresentationChain() async throws {
        let composition = try ApplicationComposition.make(
            plan: .authenticationFixture(.clientsObservationError)
        )
        let root = try #require(composition.authenticationRootViewModel)
        let rootObservation = Task { @MainActor in
            await root.sessionViewModel.load()
        }

        await waitUntil { root.sessionViewModel.sessionEventRevision == 1 }
        root.sessionEventDidChange()
        #expect(root.state == .locked)

        let clients = ClientListViewModel(
            observeClients: composition.dependencies.observeClients
        )
        await clients.load()
        #expect(clients.state == .failed)

        rootObservation.cancel()
        await rootObservation.value
    }

    @Test("Standard restored fixture keeps the empty Clients state")
    func standardRestoredFixtureKeepsEmptyClientsState() async throws {
        let composition = try ApplicationComposition.make(
            plan: .authenticationFixture(.standard(.restoredSession))
        )
        let clients = ClientListViewModel(
            observeClients: composition.dependencies.observeClients
        )
        let observation = Task { @MainActor in
            await clients.load()
        }

        await waitUntil { clients.state == .empty }
        #expect(clients.state == .empty)

        observation.cancel()
        await observation.value
    }
}

@MainActor
private final class ApplicationCompositionFactorySpy {
    private(set) var liveInvocationCount = 0
    private(set) var fixtureConfigurations: [
        DevelopAuthenticationFixture.Configuration
    ] = []
    private(set) var invalidInvocationCount = 0

    func make() throws -> ApplicationComposition {
        liveInvocationCount += 1
        return try makeComposition()
    }

    func make(configuration: DevelopAuthenticationFixture.Configuration) throws -> ApplicationComposition {
        fixtureConfigurations.append(configuration)
        return try makeComposition()
    }

    func makeInvalid() throws -> ApplicationComposition {
        invalidInvocationCount += 1
        return try makeComposition()
    }

    private func makeComposition() throws -> ApplicationComposition {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        return ApplicationComposition(
            modelContainer: container,
            dependencies: .preview(),
            runtime: nil,
            authenticationRootViewModel: nil
        )
    }
}

private extension LoginViewModel {
    var succeededSession: AuthenticationSession? {
        guard case let .succeeded(session) = state else { return nil }
        return session
    }
}

@MainActor
private func waitUntil(
    _ condition: @MainActor () -> Bool
) async {
    for _ in 0..<10_000 {
        if condition() {
            return
        }
        await Task.yield()
    }

    Issue.record("Expected fixture root transition did not occur")
}
#endif
