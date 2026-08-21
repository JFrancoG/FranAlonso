import Foundation

/// The immutable process-wide route selected before application bootstrap begins.
enum ApplicationLaunchPlan: Equatable {
    case live

#if FRANALONSO_AUTH_FIXTURE
    case authenticationFixture(DevelopAuthenticationFixture.Mode)
#endif

    /// The sole launch decision consumed by both the application delegate and composition root.
    static let current = resolve(
        appEnvironment: Bundle.main.object(
            forInfoDictionaryKey: "AppEnvironment"
        ) as? String,
        bundleIdentifier: Bundle.main.bundleIdentifier,
        arguments: ProcessInfo.processInfo.arguments
    )

    /// Resolves a fixture only when its compile-time, environment, bundle and argument gates agree.
    static func resolve(
        appEnvironment: String?,
        bundleIdentifier: String?,
        arguments: [String]
    ) -> ApplicationLaunchPlan {
#if FRANALONSO_AUTH_FIXTURE
        guard appEnvironment == "develop" else { return .live }
        guard bundleIdentifier == "com.plusprojects.FranAlonso.develop" else {
            return .live
        }

        let fixtureArguments = arguments.filter {
            $0.hasPrefix("--franalonso-auth-fixture-")
        }
        guard fixtureArguments.count == 1 else { return .live }

        return switch fixtureArguments[0] {
        case DevelopAuthenticationFixture.signedOutLaunchArgument:
            .authenticationFixture(.signedOut)
        case DevelopAuthenticationFixture.restoredSessionLaunchArgument:
            .authenticationFixture(.restoredSession)
        default:
            .live
        }
#else
        .live
#endif
    }
}
