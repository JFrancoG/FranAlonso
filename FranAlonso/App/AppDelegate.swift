import Observation
import UIKit

/// The terminal or pending state of default Firebase application configuration.
enum FirebaseBootstrapState: Equatable {
    case pending
    case configured
    case failed
}

@Observable
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    private(set) var firebaseBootstrapState: FirebaseBootstrapState = .pending

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        completeFirebaseBootstrap(configurationSucceeded: configureFirebase())
        return true
    }

    /// Records the launch-time Firebase configuration result as an explicit terminal state.
    ///
    /// - Parameter configurationSucceeded: Whether the default Firebase app is available.
    func completeFirebaseBootstrap(configurationSucceeded: Bool) {
        firebaseBootstrapState = configurationSucceeded ? .configured : .failed
    }
}
