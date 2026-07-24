import FirebaseCore

/// Configures the default Firebase app once when local options are available.
@MainActor
func configureFirebase() {
    guard FirebaseApp.app() == nil, FirebaseOptions.defaultOptions() != nil else {
        return
    }

    FirebaseApp.configure()
}
