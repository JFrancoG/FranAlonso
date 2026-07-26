import Observation
import UIKit

@Observable
@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {
    private(set) var firebaseIsConfigured = false

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        firebaseIsConfigured = configureFirebase()
        return true
    }
}
