import Foundation
import Testing

@Suite("Build environment configuration")
struct BuildEnvironmentConfigurationTests {
    @Test("The hosted application identifies an approved environment and bundle")
    func hostedApplicationIdentifiesAnApprovedEnvironmentAndBundle() throws {
        let environment = try #require(
            Bundle.main.object(forInfoDictionaryKey: "AppEnvironment") as? String
        )
        let bundleIdentifier = try #require(Bundle.main.bundleIdentifier)
        let displayName = try #require(
            Bundle.main.object(forInfoDictionaryKey: "CFBundleDisplayName") as? String
        )

        switch environment {
        case "develop":
            #expect(bundleIdentifier == "com.plusprojects.FranAlonso.develop")
            #expect(displayName == "Fran DEV")
        case "production":
            #expect(bundleIdentifier == "com.plusprojects.FranAlonso")
            #expect(displayName == "Fran Alonso")
        default:
            Issue.record("Unexpected AppEnvironment: \(environment)")
        }
    }

    @Test("The bundled Firebase configuration belongs to the hosted application")
    func bundledFirebaseConfigurationBelongsToHostedApplication() throws {
        let configurationURL = try #require(
            Bundle.main.url(
                forResource: "GoogleService-Info",
                withExtension: "plist"
            )
        )
        let configuration = try PropertyListDecoder().decode(
            FirebaseServiceConfiguration.self,
            from: Data(contentsOf: configurationURL)
        )

        #expect(configuration.bundleIdentifier == Bundle.main.bundleIdentifier)
        #expect(configuration.projectIdentifier == "agendapeluqueria-3155f")
    }

    @Test("The hosted application supports iPhone portrait and landscape")
    func hostedApplicationSupportsIPhonePortraitAndLandscape() throws {
        let orientations = try #require(
            Bundle.main.object(
                forInfoDictionaryKey: "UISupportedInterfaceOrientations"
            ) as? [String]
        )
        let requiredOrientations = Set([
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight"
        ])

        #expect(Set(orientations).isSuperset(of: requiredOrientations))
    }

    @Test("The build phase rejects Firebase configuration from another project")
    func buildPhaseRejectsFirebaseConfigurationFromAnotherProject() throws {
        let project = try repositoryFile(
            at: "FranAlonso.xcodeproj/project.pbxproj"
        )

        #expect(project.contains("configured_project_identifier"))
        #expect(
            project.contains(
                "\\\"${configured_project_identifier}\\\" != \\\"${FIREBASE_PROJECT_ID}\\\""
            )
        )
    }

    @Test("The project defines the complete environment configuration matrix")
    func projectDefinesTheCompleteEnvironmentConfigurationMatrix() throws {
        let project = try repositoryFile(
            at: "FranAlonso.xcodeproj/project.pbxproj"
        )

        for configuration in [
            "Debug-Develop",
            "Release-Develop",
            "Debug-Production",
            "Release-Production"
        ] {
            #expect(
                occurrenceCount(
                    of: "name = \"\(configuration)\";",
                    in: project
                ) == 3
            )
        }

        #expect(!project.contains("name = Debug;"))
        #expect(!project.contains("name = Release;"))
        #expect(
            occurrenceCount(
                of: "/* Configuration/BuildSettings/Develop.xcconfig */;",
                in: project
            ) == 2
        )
        #expect(
            occurrenceCount(
                of: "/* Configuration/BuildSettings/Production.xcconfig */;",
                in: project
            ) == 2
        )

        #expect(
            occurrenceCount(
                of: "defaultConfigurationName = \"Release-Production\";",
                in: project
            ) == 3
        )
    }

    @Test("Shared schemes map every action to their own environment")
    func sharedSchemesMapEveryActionToTheirOwnEnvironment() throws {
        try verifyScheme(
            named: "FranAlonso-Develop",
            debugConfiguration: "Debug-Develop",
            releaseConfiguration: "Release-Develop"
        )
        try verifyScheme(
            named: "FranAlonso-Production",
            debugConfiguration: "Debug-Production",
            releaseConfiguration: "Release-Production"
        )
    }

    @Test("Environment xcconfig files select distinct bundles and Firebase plists")
    func environmentConfigurationsSelectDistinctBundlesAndFirebasePlists() throws {
        let develop = try repositoryFile(
            at: "Configuration/BuildSettings/Develop.xcconfig"
        )
        let production = try repositoryFile(
            at: "Configuration/BuildSettings/Production.xcconfig"
        )

        #expect(develop.contains("APP_ENVIRONMENT = develop"))
        #expect(
            develop.contains(
                "FIREBASE_PROJECT_ID = agendapeluqueria-3155f"
            )
        )
        #expect(
            develop.contains(
                "PRODUCT_BUNDLE_IDENTIFIER = com.plusprojects.FranAlonso.develop"
            )
        )
        #expect(
            develop.contains(
                "FIREBASE_CONFIG_PATH = $(PROJECT_DIR)/Configuration/Firebase/Develop/GoogleService-Info.plist"
            )
        )

        #expect(production.contains("APP_ENVIRONMENT = production"))
        #expect(
            production.contains(
                "FIREBASE_PROJECT_ID = agendapeluqueria-3155f"
            )
        )
        #expect(
            production.contains(
                "PRODUCT_BUNDLE_IDENTIFIER = com.plusprojects.FranAlonso"
            )
        )
        #expect(
            production.contains(
                "FIREBASE_CONFIG_PATH = $(PROJECT_DIR)/Configuration/Firebase/Production/GoogleService-Info.plist"
            )
        )
    }

    @Test("Environment configurations select distinct primary app icons")
    func environmentConfigurationsSelectDistinctPrimaryAppIcons() throws {
        let develop = try repositoryFile(
            at: "Configuration/BuildSettings/Develop.xcconfig"
        )
        let production = try repositoryFile(
            at: "Configuration/BuildSettings/Production.xcconfig"
        )
        let project = try repositoryFile(
            at: "FranAlonso.xcodeproj/project.pbxproj"
        )

        #expect(
            develop.contains(
                "ASSETCATALOG_COMPILER_APPICON_NAME = franalonso-develop"
            )
        )
        #expect(
            production.contains(
                "ASSETCATALOG_COMPILER_APPICON_NAME = franalonso"
            )
        )
        #expect(!project.contains("ASSETCATALOG_COMPILER_APPICON_NAME"))

        let productionFill =
            "extended-srgb:0.00000,0.53333,1.00000,1.00000"
        let developFill =
            "extended-srgb:0.30196,0.72157,0.96078,1.00000"
        let productionIcon = try repositoryFile(
            at: "FranAlonso/Resources/franalonso.icon/icon.json"
        )
        let developIcon = try repositoryFile(
            at: "FranAlonso/Resources/franalonso-develop.icon/icon.json"
        )

        #expect(productionIcon.contains(productionFill))
        #expect(developIcon.contains(developFill))
        #expect(
            productionIcon.replacingOccurrences(
                of: productionFill,
                with: developFill
            ).trimmingCharacters(in: .whitespacesAndNewlines)
                == developIcon.trimmingCharacters(in: .whitespacesAndNewlines)
        )

        for assetName in ["FranAlonsoIconBack.png", "FranAlonsoIconFront.png"] {
            let productionAsset = try repositoryData(
                at: "FranAlonso/Resources/franalonso.icon/Assets/\(assetName)"
            )
            let developAsset = try repositoryData(
                at: "FranAlonso/Resources/franalonso-develop.icon/Assets/\(assetName)"
            )

            #expect(productionAsset == developAsset)
        }
    }

    @Test("The authentication fixture compiles only in app and test Debug-Develop targets")
    func authenticationFixtureCompilesOnlyInDebugDevelopTargets() throws {
        let project = try repositoryFile(
            at: "FranAlonso.xcodeproj/project.pbxproj"
        )
        let fixtureCondition = "FRANALONSO_AUTH_FIXTURE"
        let expectedConfigurations = [
            "E08BC64A2FDB2B72008EECFF": false,
            "E08BC64B2FDB2B72008EECFF": false,
            "E0C0D010300F000100000001": false,
            "E0C0D011300F000100000001": false,
            "E08BC64D2FDB2B72008EECFF": true,
            "E08BC64E2FDB2B72008EECFF": false,
            "E0C0D012300F000100000001": false,
            "E0C0D013300F000100000001": false,
            "E08BC6502FDB2B72008EECFF": true,
            "E08BC6512FDB2B72008EECFF": false,
            "E0C0D014300F000100000001": false,
            "E0C0D015300F000100000001": false
        ]

        #expect(expectedConfigurations.count == 12)
        #expect(
            buildConfigurationIDs(in: project)
                == Set(expectedConfigurations.keys)
        )

        for (configurationID, expectsFixture) in expectedConfigurations {
            let settings = buildSettings(
                configurationID: configurationID,
                in: project
            )
            #expect(!settings.isEmpty)
            #expect(settings.contains(fixtureCondition) == expectsFixture)
        }

        for configurationPath in [
            "Configuration/BuildSettings/Develop.xcconfig",
            "Configuration/BuildSettings/Production.xcconfig"
        ] {
            let inheritedSettings = try repositoryFile(at: configurationPath)
            #expect(!inheritedSettings.contains(fixtureCondition))
        }
    }

    @Test("Develop launch arguments are present and disabled by default")
    func developFixtureLaunchArgumentsAreDisabledByDefault() throws {
        let developScheme = try repositoryFile(
            at: "FranAlonso.xcodeproj/xcshareddata/xcschemes/FranAlonso-Develop.xcscheme"
        )
        let productionScheme = try repositoryFile(
            at: "FranAlonso.xcodeproj/xcshareddata/xcschemes/FranAlonso-Production.xcscheme"
        )

        for argument in [
            "--franalonso-auth-fixture-signed-out",
            "--franalonso-auth-fixture-restored-session"
        ] {
            #expect(
                developScheme.contains(
                    "argument = \"\(argument)\"\n            isEnabled = \"NO\""
                )
            )
            #expect(!productionScheme.contains(argument))
        }
    }

    @Test("Fixture implementation files are excluded as complete compilation units")
    func fixtureImplementationFilesAreCompletelyGuarded() throws {
        for relativePath in [
            "FranAlonso/App/DevelopAuthenticationFixture.swift",
            "FranAlonso/Features/Authentication/Data/Adapters/DevelopAuthenticationDataSource.swift"
        ] {
            let source = try repositoryFile(at: relativePath)
                .trimmingCharacters(in: .whitespacesAndNewlines)

            #expect(source.hasPrefix("#if FRANALONSO_AUTH_FIXTURE"))
            #expect(source.hasSuffix("#endif"))
        }
    }

    @Test("Every shared fixture seam remains inside its compilation guard")
    func sharedFixtureSeamsRemainInsideCompilationGuard() throws {
        let guardedSeams = [
            (
                "FranAlonso/App/ApplicationLaunchPlan.swift",
                "case authenticationFixture(DevelopAuthenticationFixture.Mode)"
            ),
            (
                "FranAlonso/App/ApplicationComposition.swift",
                "let authenticationRootViewModel: AuthenticationRootViewModel?"
            ),
            (
                "FranAlonso/App/AppDelegate.swift",
                "case fixtureReady"
            ),
            (
                "FranAlonso/App/AppDependencies.swift",
                "static func local("
            ),
            (
                "FranAlonso/App/FranAlonsoApp.swift",
                "private let authenticationRootViewModel: AuthenticationRootViewModel?"
            )
        ]

        for (relativePath, seam) in guardedSeams {
            let source = try repositoryFile(at: relativePath)
            #expect(
                sourceContainsFixtureGuarded(seam, in: source),
                "Expected \(seam) to be excluded outside Debug-Develop"
            )
        }
    }
}

private struct FirebaseServiceConfiguration: Decodable {
    let bundleIdentifier: String
    let projectIdentifier: String

    enum CodingKeys: String, CodingKey {
        case bundleIdentifier = "BUNDLE_ID"
        case projectIdentifier = "PROJECT_ID"
    }
}

private func verifyScheme(named schemeName: String, debugConfiguration: String, releaseConfiguration: String) throws {
    let scheme = try repositoryFile(
        at: "FranAlonso.xcodeproj/xcshareddata/xcschemes/\(schemeName).xcscheme"
    )
    let normalizedScheme = scheme
        .split(whereSeparator: \.isWhitespace)
        .joined(separator: " ")

    for action in ["TestAction", "LaunchAction", "AnalyzeAction"] {
        #expect(
            normalizedScheme.contains(
                "<\(action) buildConfiguration = \"\(debugConfiguration)\""
            )
        )
    }

    for action in ["ProfileAction", "ArchiveAction"] {
        #expect(
            normalizedScheme.contains(
                "<\(action) buildConfiguration = \"\(releaseConfiguration)\""
            )
        )
    }
}

private func repositoryFile(at relativePath: String) throws -> String {
    let testsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
    let repositoryRoot = testsDirectory.deletingLastPathComponent()
    let fileURL = repositoryRoot.appending(path: relativePath)

    return try String(contentsOf: fileURL, encoding: .utf8)
}

private func repositoryData(at relativePath: String) throws -> Data {
    let testsDirectory = URL(fileURLWithPath: #filePath)
        .deletingLastPathComponent()
    let repositoryRoot = testsDirectory.deletingLastPathComponent()
    let fileURL = repositoryRoot.appending(path: relativePath)

    return try Data(contentsOf: fileURL)
}

private func occurrenceCount(of value: String, in text: String) -> Int {
    text.components(separatedBy: value).count - 1
}

private func buildSettings(configurationID: String, in project: String) -> Substring {
    let startMarker = "\(configurationID) /*"
    guard let start = project.range(of: startMarker)?.lowerBound else { return "" }
    let suffix = project[start...]
    guard let end = suffix.range(of: "\n\t\t};")?.upperBound else { return "" }

    return suffix[..<end]
}

private func buildConfigurationIDs(in project: String) -> Set<String> {
    let lines = project.split(separator: "\n", omittingEmptySubsequences: false)
    var identifiers = Set<String>()

    for index in lines.indices where lines[index].contains("isa = XCBuildConfiguration;") && index > lines.startIndex {
        let header = lines[lines.index(before: index)]
            .trimmingCharacters(in: .whitespaces)
        if let identifier = header.split(separator: " ").first {
            identifiers.insert(String(identifier))
        }
    }

    return identifiers
}

private func sourceContainsFixtureGuarded(_ value: String, in source: String) -> Bool {
    guard let valueRange = source.range(of: value) else { return false }
    let prefix = source[..<valueRange.lowerBound]
    guard let guardRange = prefix.range(
        of: "#if FRANALONSO_AUTH_FIXTURE",
        options: .backwards
    ) else {
        return false
    }

    let lastEnd = prefix.range(of: "#endif", options: .backwards)
    let lastElse = prefix.range(of: "#else", options: .backwards)
    let guardStartsAfterEnd = lastEnd.map {
        guardRange.lowerBound > $0.lowerBound
    } ?? true
    let guardStartsAfterElse = lastElse.map {
        guardRange.lowerBound > $0.lowerBound
    } ?? true

    return guardStartsAfterEnd && guardStartsAfterElse
}
