//
//  ProjectSanityTests.swift
//  FranAlonsoTests
//
//  Created by Jesús Franco on 11.06.2026.
//

import Foundation
import Testing
@testable import FranAlonso

#if swift(<6.0)
#error("FranAlonsoTests must compile in Swift 6 language mode")
#endif

private enum DefaultIsolationFixture {
    static let value = 42
}

@Suite("Project sanity")
@MainActor
struct ProjectSanityTests {
    @Test("Application composition root can be created")
    func applicationCompositionRootCanBeCreated() {
        _ = FranAlonsoApp()
    }
}

@Suite("Concurrency configuration")
struct ConcurrencyConfigurationTests {
    @Test("Default isolation remains nonisolated")
    func defaultIsolationRemainsNonisolated() async {
        let value = await Task { @concurrent in
            DefaultIsolationFixture.value
        }.value

        #expect(value == 42)
    }
}

@Suite("Localization configuration")
struct LocalizationConfigurationTests {
    @Test("Critical localization symbol is generated")
    func criticalLocalizationSymbolIsGenerated() {
        let resource: LocalizedStringResource = .bootstrapWelcomeTitle

        #expect(resource.key == "bootstrap.welcome.title")
    }
}
