struct AnalyticsPayload: Equatable, Sendable {
    let name: String
    let parameters: [String: String]
}

enum AnalyticsScreen: String, Sendable {
    case bootstrap
}

enum AnalyticsEvent: Equatable, Sendable {
    case appOpened
    case screenViewed(AnalyticsScreen)

    var payload: AnalyticsPayload {
        switch self {
        case .appOpened:
            AnalyticsPayload(name: "app_opened", parameters: [:])
        case let .screenViewed(screen):
            AnalyticsPayload(
                name: "screen_viewed",
                parameters: ["screen": screen.rawValue]
            )
        }
    }
}

enum CrashDiagnostic: Int, Equatable, Sendable {
    case controlledValidation = 1_001

    var errorDomain: String {
        "com.plusprojects.FranAlonso.telemetry"
    }
}

enum TelemetryConsent: Sendable {
    case denied
    case granted

    var isGranted: Bool {
        self == .granted
    }
}
