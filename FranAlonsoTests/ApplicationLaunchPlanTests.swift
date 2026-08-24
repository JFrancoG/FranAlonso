import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Application launch plan")
struct ApplicationLaunchPlanTests {
    @Test(
        "An exact Develop gate resolves each supported fixture",
        arguments: [
            (
                DevelopAuthenticationFixture.signedOutLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(
                    .standard(.signedOut)
                )
            ),
            (
                DevelopAuthenticationFixture.restoredSessionLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(
                    .standard(.restoredSession)
                )
            ),
            (
                DevelopAuthenticationFixture.localAccessDeniedLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(
                    .localAccessDenied
                )
            ),
            (
                DevelopAuthenticationFixture.observationFailedLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(
                    .observationFailed
                )
            )
        ]
    )
    func exactDevelopGateResolvesFixture(
        argument: String,
        expectedPlan: ApplicationLaunchPlan
    ) {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: ["/fixture/app", argument]
        )

        #expect(plan == expectedPlan)
    }

    @Test("The Clients error fixture requires one exact restored session pair")
    func clientsErrorFixtureRequiresExactRestoredSessionPair() {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: [
                "/fixture/app",
                DevelopAuthenticationFixture.restoredSessionLaunchArgument,
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ]
        )

        #expect(
            plan == .authenticationFixture(
                .clientsObservationError
            )
        )
    }

    @Test(
        "Every malformed Clients fixture intent fails closed",
        arguments: [
            [
                "/fixture/app",
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.signedOutLaunchArgument,
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.localAccessDeniedLaunchArgument,
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.observationFailedLaunchArgument,
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.restoredSessionLaunchArgument,
                "--franalonso-clients-fixture-unknown"
            ],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.restoredSessionLaunchArgument,
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument,
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.restoredSessionLaunchArgument,
                DevelopAuthenticationFixture.signedOutLaunchArgument,
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ],
            [
                "/fixture/app",
                "--franalonso-auth-fixture-unknown",
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ]
        ]
    )
    func malformedClientsFixtureIntentFailsClosed(_ arguments: [String]) {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: arguments
        )

        #expect(plan == .invalidFixtureConfiguration)
    }

    @Test("A Clients fixture intent fails closed when its Develop identity gate is invalid")
    func clientsFixtureIntentFailsClosedOutsideExactDevelopIdentity() {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "production",
            bundleIdentifier: "com.plusprojects.FranAlonso",
            arguments: [
                "/fixture/app",
                DevelopAuthenticationFixture.restoredSessionLaunchArgument,
                DevelopAuthenticationFixture.clientsObservationErrorLaunchArgument
            ]
        )

        #expect(plan == .invalidFixtureConfiguration)
    }

    @Test("An explicit Authentication fixture intent fails closed outside its exact Develop identity")
    func authenticationFixtureIntentFailsClosedOutsideExactDevelopIdentity() {
        let invalidGates: [(appEnvironment: String?, bundleIdentifier: String?)] = [
            (nil, "com.plusprojects.FranAlonso.develop"),
            ("production", "com.plusprojects.FranAlonso.develop"),
            ("develop", nil),
            ("develop", "com.plusprojects.FranAlonso")
        ]

        for gate in invalidGates {
            let plan = ApplicationLaunchPlan.resolve(
                appEnvironment: gate.appEnvironment,
                bundleIdentifier: gate.bundleIdentifier,
                arguments: [
                    "/fixture/app",
                    DevelopAuthenticationFixture.signedOutLaunchArgument
                ]
            )

            #expect(plan == .invalidFixtureConfiguration)
        }
    }

    @Test(
        "Every malformed Authentication fixture intent fails closed",
        arguments: [
            ["/fixture/app", "--franalonso-auth-fixture-unknown"],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.signedOutLaunchArgument,
                DevelopAuthenticationFixture.signedOutLaunchArgument
            ],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.signedOutLaunchArgument,
                DevelopAuthenticationFixture.restoredSessionLaunchArgument
            ],
            [
                "/fixture/app",
                DevelopAuthenticationFixture.signedOutLaunchArgument,
                "--franalonso-auth-fixture-unknown"
            ]
        ]
    )
    func malformedAuthenticationFixtureIntentFailsClosed(_ arguments: [String]) {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: arguments
        )

        #expect(plan == .invalidFixtureConfiguration)
    }

    @Test("No fixture intent preserves the live route")
    func noFixtureIntentPreservesLiveRoute() {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: ["/fixture/app", "--unrelated-argument"]
        )

        #expect(plan == .live)
    }
}
#endif
