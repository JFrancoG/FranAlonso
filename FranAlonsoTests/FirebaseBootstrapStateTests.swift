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
    func launchResultBecomesExplicitTerminalState(
        configurationSucceeded: Bool,
        expectedState: FirebaseBootstrapState
    ) {
        let delegate = AppDelegate()

        delegate.completeFirebaseBootstrap(configurationSucceeded: configurationSucceeded)

        #expect(delegate.firebaseBootstrapState == expectedState)
    }
}
