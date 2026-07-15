import FirebaseCore

@MainActor
enum FirebaseConfigurator {
    static func configure() {
        guard FirebaseApp.app() == nil, FirebaseOptions.defaultOptions() != nil else {
            return
        }

        FirebaseApp.configure()
    }
}
