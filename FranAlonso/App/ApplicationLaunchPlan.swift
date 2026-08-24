import Foundation

/// The immutable process-wide route selected before application bootstrap begins.
enum ApplicationLaunchPlan: Equatable {
    case live

#if FRANALONSO_AUTH_FIXTURE
    case authenticationFixture(DevelopAuthenticationFixture.Configuration)
    case invalidFixtureConfiguration
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
        let authenticationArguments = arguments.filter {
            $0.hasPrefix("--franalonso-auth-fixture-")
        }
        let clientsArguments = arguments.filter {
            $0.hasPrefix("--franalonso-clients-fixture-")
        }
        let hasFixtureIntent = !authenticationArguments.isEmpty || !clientsArguments.isEmpty

        guard hasFixtureIntent else { return .live }
        guard appEnvironment == "develop" else {
            return .invalidFixtureConfiguration
        }
        guard bundleIdentifier == "com.plusprojects.FranAlonso.develop" else {
            return .invalidFixtureConfiguration
        }

        if !clientsArguments.isEmpty {
            guard authenticationArguments == [
                DevelopAuthenticationFixture.restoredSessionLaunchArgument
            ] else {
                return .invalidFixtureConfiguration
            }
            guard clientsArguments == [
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ] else {
                return .invalidFixtureConfiguration
            }

            return .authenticationFixture(.clientsObservationError)
        }

        guard authenticationArguments.count == 1 else {
            return .invalidFixtureConfiguration
        }

        return switch authenticationArguments[0] {
        case DevelopAuthenticationFixture.signedOutLaunchArgument:
            .authenticationFixture(.standard(.signedOut))
        case DevelopAuthenticationFixture.restoredSessionLaunchArgument:
            .authenticationFixture(.standard(.restoredSession))
        case DevelopAuthenticationFixture.localAccessDeniedLaunchArgument:
            .authenticationFixture(.localAccessDenied)
        case DevelopAuthenticationFixture.observationFailedLaunchArgument:
            .authenticationFixture(.observationFailed)
        default:
            .invalidFixtureConfiguration
        }
#else
        .live
#endif
    }
}
