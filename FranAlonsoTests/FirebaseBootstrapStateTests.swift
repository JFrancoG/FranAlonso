import Testing
@testable import FranAlonso

@Suite("Firebase bootstrap state")
@MainActor
struct FirebaseBootstrapStateTests {
    @Test("The application starts pending before the delegate launch callback")
    func applicationStartsPending() {
        #expect(AppDelegate().firebaseBootstrapState == .pending)
    }

    @Test(
        "The launch result becomes an explicit terminal bootstrap state",
        arguments: [(true, FirebaseBootstrapState.configured), (false, .failed)]
    )
    func launchResultBecomesExplicitTerminalState(configurationSucceeded: Bool, expectedState: FirebaseBootstrapState) {
        let delegate = AppDelegate()

        delegate.completeFirebaseBootstrap(configurationSucceeded: configurationSucceeded)

        #expect(delegate.firebaseBootstrapState == expectedState)
    }

#if FRANALONSO_AUTH_FIXTURE
    @Test("Fixture launch becomes ready without configuring Firebase")
    func fixtureLaunchBecomesReadyWithoutConfiguringFirebase() {
        let delegate = AppDelegate()
        var configurationCalls = 0

        delegate.completeApplicationBootstrap(
            for: .authenticationFixture(
                .standard(.signedOut)
            ),
            configureFirebase: {
                configurationCalls += 1
                return true
            }
        )

        #expect(delegate.firebaseBootstrapState == .fixtureReady)
        #expect(configurationCalls == 0)
    }

    @Test("Invalid fixture configuration fails without configuring Firebase")
    func invalidFixtureConfigurationFailsWithoutConfiguringFirebase() {
        let delegate = AppDelegate()
        var configurationCalls = 0

        delegate.completeApplicationBootstrap(
            for: .invalidFixtureConfiguration,
            configureFirebase: {
                configurationCalls += 1
                return true
            }
        )

        #expect(delegate.firebaseBootstrapState == .fixtureConfigurationFailed)
        #expect(configurationCalls == 0)
    }
#endif
}
