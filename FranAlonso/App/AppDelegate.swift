import Observation
import UIKit

/// The terminal or pending state of application bootstrap.
enum FirebaseBootstrapState: Equatable {
    case pending
    case configured
    case failed
#if FRANALONSO_AUTH_FIXTURE
    case fixtureReady
    case fixtureConfigurationFailed
#endif
}

@Observable
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    private(set) var firebaseBootstrapState: FirebaseBootstrapState = .pending

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        completeApplicationBootstrap(
            for: ApplicationLaunchPlan.current,
            configureFirebase: configureFirebase
        )
        return true
    }

    /// Selects fixture readiness before any live Firebase configuration can be requested.
    func completeApplicationBootstrap(
        for plan: ApplicationLaunchPlan,
        configureFirebase: () -> Bool
    ) {
#if FRANALONSO_AUTH_FIXTURE
        switch plan {
        case .live:
            completeFirebaseBootstrap(
                configurationSucceeded: configureFirebase()
            )
        case .authenticationFixture:
            firebaseBootstrapState = .fixtureReady
        case .invalidFixtureConfiguration:
            firebaseBootstrapState = .fixtureConfigurationFailed
        }
#else
        completeFirebaseBootstrap(
            configurationSucceeded: configureFirebase()
        )
#endif
    }

    /// Records the launch-time Firebase configuration result as an explicit terminal state.
    ///
    /// - Parameter configurationSucceeded: Whether the default Firebase app is available.
    func completeFirebaseBootstrap(configurationSucceeded: Bool) {
        firebaseBootstrapState = configurationSucceeded ? .configured : .failed
    }
}
