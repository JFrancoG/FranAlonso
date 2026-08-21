import Foundation
import SwiftData

/// The dependencies and optional runtime selected before SwiftUI creates the application root.
@MainActor
struct ApplicationComposition {
    let modelContainer: ModelContainer
    let dependencies: AppDependencies
    let runtime: AppRuntime?
#if FRANALONSO_AUTH_FIXTURE
    let authenticationRootViewModel: AuthenticationRootViewModel?
#endif

#if FRANALONSO_AUTH_FIXTURE
    /// Selects exactly one live or fixture composition path from the immutable launch plan.
    static func make(
        plan: ApplicationLaunchPlan = .current,
        makeLive: @MainActor () throws -> ApplicationComposition = {
            try makeLiveComposition()
        },
        makeFixture: @MainActor (
            DevelopAuthenticationFixture.Mode
        ) throws -> ApplicationComposition = { mode in
            try DevelopAuthenticationFixture.make(mode: mode).applicationComposition
        }
    ) rethrows -> ApplicationComposition {
        switch plan {
        case .live:
            try makeLive()
        case let .authenticationFixture(mode):
            try makeFixture(mode)
        }
    }
#else
    /// Creates the only composition route available outside the fixture compilation boundary.
    static func make(
        plan _: ApplicationLaunchPlan = .current
    ) throws -> ApplicationComposition {
        try makeLiveComposition()
    }
#endif
}

private extension ApplicationComposition {
    static func makeLiveComposition() throws -> ApplicationComposition {
        let container = try ModelContainer.production(
            for: Schema.franAlonso,
            migrationPlan: PhaseFiveSchemaMigrationPlan.self
        )
        guard
            let environmentName = Bundle.main.object(
                forInfoDictionaryKey: "AppEnvironment"
            ) as? String,
            let environment = FirestoreEnvironment(rawValue: environmentName)
        else {
            throw ApplicationCompositionError.environmentUnavailable
        }
        let runtime = AppRuntime(
            modelContainer: container,
            environment: environment
        )

#if FRANALONSO_AUTH_FIXTURE
        return ApplicationComposition(
            modelContainer: container,
            dependencies: runtime.dependencies,
            runtime: runtime,
            authenticationRootViewModel: nil
        )
#else
        return ApplicationComposition(
            modelContainer: container,
            dependencies: runtime.dependencies,
            runtime: runtime
        )
#endif
    }
}

private enum ApplicationCompositionError: Error {
    case environmentUnavailable
}
