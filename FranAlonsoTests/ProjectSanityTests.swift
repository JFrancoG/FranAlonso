//
//  FranAlonsoTests.swift
//  FranAlonsoTests
//
//  Created by Jesús Franco on 11.06.2026.
//

import Testing
@testable import FranAlonso

@Suite("Project sanity")
@MainActor
struct ProjectSanityTests {
    @Test("Composition root can be created")
    func compositionRootCanBeCreated() {
        _ = AppRoot()
    }
}
