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
            plan: .authenticationFixture(.signedOut),
            makeLive: liveFactory.make,
            makeFixture: fixtureFactory.make(mode:)
        )

        #expect(liveFactory.liveInvocationCount == 0)
        #expect(fixtureFactory.fixtureModes == [.signedOut])
    }

    @Test("The real fixture has no live runtime and all 28 schema tables start empty")
    func realFixtureHasNoLiveRuntimeAndStartsPristine() async throws {
        let composition = try ApplicationComposition.make(
            plan: .authenticationFixture(.signedOut)
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
            plan: .authenticationFixture(.signedOut),
            makeFixture: { mode in
                try DevelopAuthenticationFixture.make(
                    mode: mode,
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
            plan: .authenticationFixture(.restoredSession)
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
}

@MainActor
private final class ApplicationCompositionFactorySpy {
    private(set) var liveInvocationCount = 0
    private(set) var fixtureModes: [DevelopAuthenticationFixture.Mode] = []

    func make() throws -> ApplicationComposition {
        liveInvocationCount += 1
        return try makeComposition()
    }

    func make(mode: DevelopAuthenticationFixture.Mode) throws -> ApplicationComposition {
        fixtureModes.append(mode)
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
