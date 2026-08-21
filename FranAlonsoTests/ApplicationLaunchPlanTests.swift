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
                ApplicationLaunchPlan.authenticationFixture(.signedOut)
            ),
            (
                DevelopAuthenticationFixture.restoredSessionLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(.restoredSession)
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

    @Test("A missing environment or bundle gate always resolves live")
    func missingEnvironmentOrBundleGateResolvesLive() {
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

            #expect(plan == .live)
        }
    }

    @Test(
        "Absent, unknown, duplicate or conflicting fixture arguments resolve live",
        arguments: [
            ["/fixture/app"],
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
    func unsupportedFixtureArgumentsResolveLive(_ arguments: [String]) {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: arguments
        )

        #expect(plan == .live)
    }
}
#endif
