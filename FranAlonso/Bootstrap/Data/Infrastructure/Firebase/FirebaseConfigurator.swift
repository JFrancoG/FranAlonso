import FirebaseCore

/// Configures the default Firebase app once when local options are available.
///
/// - Returns: `true` when the default app already exists or configuration succeeds.
@MainActor
func configureFirebase() -> Bool {
    if FirebaseApp.app() != nil {
        return true
    }
    guard FirebaseOptions.defaultOptions() != nil else { return false }

    FirebaseApp.configure()
    return FirebaseApp.app() != nil
}
