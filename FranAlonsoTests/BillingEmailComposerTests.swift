import Foundation
import Testing
@testable import FranAlonso

@Suite("Authorized manual billing email composition")
@MainActor
struct BillingEmailComposerTests {
    @Test(arguments: [EmailCompositionResult.cancelled, .saved, .queued, .failed])
    func `the native person's outcome returns through one manual presentation`(
        _ result: EmailCompositionResult
    ) async throws {
        let pdf = try billingPDFTemplate()
        let draft = try BillingEmailComposerFixtures.draft(pdf: pdf)
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver)
        let operation = BillingEmailComposerFixtures.operation(composer: composer, driver: driver, draft: draft)
        defer { operation.cancel() }
        try #require(await driver.waitUntilStartedOrCompleted())

        driver.complete(operation: 0, with: result)

        #expect(try await operation.value == result)
        #expect(driver.drafts.count == 1)
        #expect(driver.drafts.first?.recipient == "recipient@example.invalid")
        #expect(driver.drafts.first?.subject == "Synthetic ticket 41")
        #expect(driver.drafts.first?.body == "Please find the synthetic document attached.")
        #expect(driver.drafts.first?.pdf == pdf)
        #expect(driver.cancellationCount == 0)
    }

    @Test
    func `unavailable Mail preserves the draft for an explicit later retry`() async throws {
        let draft = try BillingEmailComposerFixtures.draft()
        let driver = BillingEmailComposerDriver()
        driver.canCompose = false
        let composer = BillingEmailComposerFixtures.composer(driver: driver)

        await #expect(throws: BillingEmailError.unavailable) {
            try await composer.compose(draft)
        }
        #expect(driver.drafts.isEmpty)
        driver.canCompose = true
        driver.immediateResult = .saved

        #expect(try await composer.compose(draft) == .saved)
        #expect(driver.drafts.count == 1)
        #expect(driver.cancellationCount == 0)
    }

    @Test
    func `a draft from another principal cannot reach the native interface`() async throws {
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver)

        await #expect(throws: BillingEmailError.unauthorized) {
            try await composer.compose(BillingEmailComposerFixtures.draft(principalID: "another-principal"))
        }

        #expect(driver.drafts.isEmpty)
        #expect(driver.cancellationCount == 0)
    }

    @Test
    func `revoked shell capability blocks presentation even with the same principal`() async throws {
        let driver = BillingEmailComposerDriver()
        let permit = BillingEmailComposerPermit()
        let composer = BillingEmailComposerFixtures.composer(driver: driver, permit: permit)
        let draft = try BillingEmailComposerFixtures.draft()
        await permit.revoke()

        await #expect(throws: BillingEmailError.unauthorized) {
            try await composer.compose(draft)
        }

        #expect(driver.drafts.isEmpty)
    }

    @Test
    func `revocation during manual composition denies publishing the native outcome`() async throws {
        let driver = BillingEmailComposerDriver()
        let permit = BillingEmailComposerPermit()
        let composer = BillingEmailComposerFixtures.composer(driver: driver, permit: permit)
        let operation = BillingEmailComposerFixtures.operation(
            composer: composer,
            driver: driver,
            draft: try BillingEmailComposerFixtures.draft()
        )
        defer { operation.cancel() }
        try #require(await driver.waitUntilStartedOrCompleted())
        await permit.revoke()
        driver.complete(operation: 0, with: .queued)

        await #expect(throws: BillingEmailError.unauthorized) {
            try await operation.value
        }

        #expect(driver.drafts.count == 1)
    }

    @Test(arguments: BillingEmailComposerInvalidPDF.allCases)
    func `unreadable retained PDFs fail before native presentation`(
        _ scenario: BillingEmailComposerInvalidPDF
    ) async throws {
        let draft = try BillingEmailComposerFixtures.draft(pdf: scenario.bytes())
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver)

        await #expect(throws: BillingEmailError.invalidDraft) {
            try await composer.compose(draft)
        }

        #expect(driver.drafts.isEmpty)
    }

    @Test
    func `an inline native completion does not require a second callback`() async throws {
        let driver = BillingEmailComposerDriver()
        driver.immediateResult = .queued
        let composer = BillingEmailComposerFixtures.composer(driver: driver)

        #expect(try await composer.compose(BillingEmailComposerFixtures.draft()) == .queued)
        #expect(driver.drafts.count == 1)
        #expect(driver.cancellationCount == 0)
    }

    @Test
    func `a duplicate native callback keeps the first terminal outcome`() async throws {
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver)
        let operation = BillingEmailComposerFixtures.operation(
            composer: composer,
            driver: driver,
            draft: try BillingEmailComposerFixtures.draft()
        )
        defer { operation.cancel() }
        try #require(await driver.waitUntilStartedOrCompleted())

        driver.complete(operation: 0, with: .saved)
        driver.complete(operation: 0, with: .queued)

        #expect(try await operation.value == .saved)
        #expect(driver.drafts.count == 1)
    }

    @Test
    func `SDK failure is neutral and its late callback cannot finish a later retry`() async throws {
        let driver = BillingEmailComposerDriver()
        driver.startFailure = .privateProviderDetails
        let composer = BillingEmailComposerFixtures.composer(driver: driver)
        let draft = try BillingEmailComposerFixtures.draft()

        await #expect(throws: BillingEmailError.unavailable) {
            try await composer.compose(draft)
        }
        driver.startFailure = nil
        let retry = BillingEmailComposerFixtures.operation(composer: composer, driver: driver, draft: draft)
        defer { retry.cancel() }
        try #require(await driver.waitUntilStartedOrCompleted(startBaseline: 1))
        driver.complete(operation: 0, with: .queued)
        driver.complete(operation: 1, with: .saved)

        #expect(try await retry.value == .saved)
        #expect(driver.drafts.count == 2)
    }

    @Test
    func `SDK failure does not hide revocation observed after presentation was requested`() async throws {
        let driver = BillingEmailComposerDriver()
        driver.startFailure = .privateProviderDetails
        let composer = AppleBillingEmailComposer(
            driver: driver,
            access: BillingAssetAccess(principalID: BillingEmailComposerFixtures.principalID) {
                guard await driver.drafts.isEmpty else { throw BillingAssetError.unauthorized }
            }
        )

        await #expect(throws: BillingEmailError.unauthorized) {
            try await composer.compose(BillingEmailComposerFixtures.draft())
        }

        #expect(driver.drafts.count == 1)
    }
}
