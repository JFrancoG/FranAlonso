import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Application launch plan")
struct ApplicationLaunchPlanTests {
    @Test(
        arguments: [
            ("--franalonso-demo-clients", DevelopDemoComposition.Configuration.clients),
            ("--franalonso-demo-clients-response-lost", .clientsResponseLost)
        ]
    )
    func `an exact Develop gate selects the requested demo`(
        argument: String,
        configuration: DevelopDemoComposition.Configuration
    ) {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: ["/demo/app", argument]
        )

        #expect(plan == .demo(configuration))
    }

    @Test(arguments: [DevelopDemoComposition.Configuration.clients, .clientsResponseLost])
    @MainActor
    func `a demo route invokes only its own composition factory`(
        configuration: DevelopDemoComposition.Configuration
    ) throws {
        let expected = try DevelopAuthenticationFixture.makeInvalidApplicationComposition()
        var liveCalls = 0
        var fixtureCalls = 0
        var invalidCalls = 0
        var demoConfigurations: [DevelopDemoComposition.Configuration] = []

        let composition = ApplicationComposition.make(
            plan: .demo(configuration),
            makeLive: {
                liveCalls += 1
                return expected
            },
            makeFixture: { _ in
                fixtureCalls += 1
                return expected
            },
            makeDemo: { selectedConfiguration in
                demoConfigurations.append(selectedConfiguration)
                return expected
            },
            makeInvalidFixture: {
                invalidCalls += 1
                return expected
            }
        )

        #expect(composition.modelContainer === expected.modelContainer)
        #expect(demoConfigurations == [configuration])
        #expect(liveCalls == 0)
        #expect(fixtureCalls == 0)
        #expect(invalidCalls == 0)
    }

    @Test
    @MainActor
    func `a failed demo composition propagates its failure without opening another route`() throws {
        enum DemoFailure: Error {
            case seed
        }
        let unexpected = try DevelopAuthenticationFixture.makeInvalidApplicationComposition()
        var fallbackCalls = 0

        #expect(throws: DemoFailure.seed) {
            try ApplicationComposition.make(
                plan: .demo(.clients),
                makeLive: {
                    fallbackCalls += 1
                    return unexpected
                },
                makeFixture: { _ in
                    fallbackCalls += 1
                    return unexpected
                },
                makeDemo: { _ in
                    throw DemoFailure.seed
                },
                makeInvalidFixture: {
                    fallbackCalls += 1
                    return unexpected
                }
            )
        }

        #expect(fallbackCalls == 0)
    }

    @Test(
        "An exact Develop gate resolves each supported fixture",
        arguments: [
            (
                DevelopAuthenticationFixture.signedOutLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(.standard(.signedOut))
            ),
            (
                DevelopAuthenticationFixture.restoredSessionLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(.standard(.restoredSession))
            ),
            (
                DevelopAuthenticationFixture.localAccessDeniedLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(.localAccessDenied)
            ),
            (
                DevelopAuthenticationFixture.observationFailedLaunchArgument,
                ApplicationLaunchPlan.authenticationFixture(.observationFailed)
            )
        ]
    )
    func exactDevelopGateResolvesFixture(argument: String, expectedPlan: ApplicationLaunchPlan) {
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

        #expect(plan == .authenticationFixture(.clientsObservationError))
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

    @Test(
        arguments: [
            ["--franalonso-demo-unknown"],
            ["--franalonso-demo-clients", "--franalonso-demo-clients"],
            ["--franalonso-demo-clients-response-lost", "--franalonso-demo-clients-response-lost"],
            ["--franalonso-demo-clients", "--franalonso-demo-clients-response-lost"],
            ["--franalonso-demo-clients", "--franalonso-demo-unknown"],
            ["--franalonso-demo-clients", "--franalonso-auth-fixture-signed-out"],
            ["--franalonso-demo-clients-response-lost", "--franalonso-auth-fixture-restored-session"],
            ["--franalonso-demo-clients", "--franalonso-clients-fixture-observation-error"],
            [
                "--franalonso-demo-clients",
                "--franalonso-auth-fixture-restored-session",
                "--franalonso-clients-fixture-observation-error"
            ]
        ]
    )
    func `malformed or conflicting demo intent fails closed`(_ arguments: [String]) {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: ["/demo/app"] + arguments
        )

        #expect(plan == .invalidFixtureConfiguration)
    }

    @Test(
        arguments: [
            (nil, "com.plusprojects.FranAlonso.develop"),
            ("production", "com.plusprojects.FranAlonso.develop"),
            ("develop", nil),
            ("develop", "com.plusprojects.FranAlonso")
        ] as [(String?, String?)]
    )
    func `demo intent fails closed outside exact Develop identity`(environment: String?, bundleIdentifier: String?) {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: environment,
            bundleIdentifier: bundleIdentifier,
            arguments: ["/demo/app", "--franalonso-demo-clients"]
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
