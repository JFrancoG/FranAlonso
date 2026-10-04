import Foundation
import Testing
@testable import FranAlonso

@Suite("Manual billing email operation lifetime")
@MainActor
struct BillingEmailComposerCancellationTests {
    @Test
    func `a second operation is rejected while authorization for the first is suspended`() async throws {
        let pause = BillingStoragePause()
        let permit = BillingEmailComposerPermit(pause: pause)
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver, permit: permit)
        let draft = try BillingEmailComposerFixtures.draft()
        let first = Task {
            defer { driver.operationFinished() }
            do {
                let result = try await composer.compose(draft)
                await pause.complete()
                return result
            } catch {
                await pause.complete()
                throw error
            }
        }
        defer { first.cancel() }
        try #require(await pause.waitUntilPausedOrCompleted())

        await #expect(throws: BillingEmailError.busy) {
            try await composer.compose(draft)
        }
        #expect(driver.drafts.isEmpty)
        await pause.release()
        try #require(await driver.waitUntilStartedOrCompleted())
        driver.complete(operation: 0, with: .saved)

        #expect(try await first.value == .saved)
        #expect(driver.drafts.count == 1)
    }

    @Test
    func `cancellation before the task starts never opens Mail`() async throws {
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver)
        let operation = BillingEmailComposerFixtures.operation(
            composer: composer,
            driver: driver,
            draft: try BillingEmailComposerFixtures.draft()
        )
        operation.cancel()

        await #expect(throws: CancellationError.self) {
            try await operation.value
        }

        #expect(driver.drafts.isEmpty)
        #expect(driver.cancellationCount == 0)
    }

    @Test
    func `cancellation during authorization does not dismiss another native interface`() async throws {
        let pause = BillingStoragePause()
        let permit = BillingEmailComposerPermit(pause: pause)
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver, permit: permit)
        let draft = try BillingEmailComposerFixtures.draft()
        let operation = Task {
            do {
                let result = try await composer.compose(draft)
                await pause.complete()
                return result
            } catch {
                await pause.complete()
                throw error
            }
        }
        defer { operation.cancel() }
        try #require(await pause.waitUntilPausedOrCompleted())
        operation.cancel()
        await pause.release()

        await #expect(throws: CancellationError.self) {
            try await operation.value
        }

        #expect(driver.drafts.isEmpty)
        #expect(driver.cancellationCount == 0)
    }

    @Test
    func `Mail becoming unavailable during authorization prevents presentation`() async throws {
        let pause = BillingStoragePause()
        let permit = BillingEmailComposerPermit(pause: pause)
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver, permit: permit)
        let draft = try BillingEmailComposerFixtures.draft()
        let operation = Task {
            do {
                let result = try await composer.compose(draft)
                await pause.complete()
                return result
            } catch {
                await pause.complete()
                throw error
            }
        }
        defer { operation.cancel() }
        try #require(await pause.waitUntilPausedOrCompleted())
        driver.canCompose = false
        await pause.release()

        await #expect(throws: BillingEmailError.unavailable) {
            try await operation.value
        }

        #expect(driver.drafts.isEmpty)
        #expect(driver.cancellationCount == 0)
    }

    @Test
    func `cancellation dismisses once even if dismissal completes inline`() async throws {
        let driver = BillingEmailComposerDriver()
        driver.inlineCancellationResult = .cancelled
        let composer = BillingEmailComposerFixtures.composer(driver: driver)
        let operation = BillingEmailComposerFixtures.operation(
            composer: composer,
            driver: driver,
            draft: try BillingEmailComposerFixtures.draft()
        )
        defer { operation.cancel() }
        try #require(await driver.waitUntilStartedOrCompleted())
        operation.cancel()

        await #expect(throws: CancellationError.self) {
            try await operation.value
        }

        #expect(driver.cancellationCount == 1)
    }

    @Test
    func `cancelled operation callbacks cannot complete or dismiss a subsequent composition`() async throws {
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver)
        let draft = try BillingEmailComposerFixtures.draft()
        let first = BillingEmailComposerFixtures.operation(composer: composer, driver: driver, draft: draft)
        defer { first.cancel() }
        try #require(await driver.waitUntilStartedOrCompleted())
        first.cancel()
        await #expect(throws: CancellationError.self) {
            try await first.value
        }
        #expect(driver.cancellationCount == 1)
        let second = BillingEmailComposerFixtures.operation(composer: composer, driver: driver, draft: draft)
        defer { second.cancel() }
        try #require(await driver.waitUntilStartedOrCompleted(startBaseline: 1, completionBaseline: 1))

        driver.complete(operation: 0, with: .queued)
        first.cancel()
        driver.complete(operation: 1, with: .saved)

        #expect(try await second.value == .saved)
        #expect(driver.drafts.count == 2)
        #expect(driver.cancellationCount == 1)
    }

    @Test
    func `a cancellation after native completion wins before publication`() async throws {
        let driver = BillingEmailComposerDriver()
        let composer = BillingEmailComposerFixtures.composer(driver: driver)
        let operation = BillingEmailComposerFixtures.operation(
            composer: composer,
            driver: driver,
            draft: try BillingEmailComposerFixtures.draft()
        )
        defer { operation.cancel() }
        try #require(await driver.waitUntilStartedOrCompleted())

        driver.complete(operation: 0, with: .queued)
        operation.cancel()

        await #expect(throws: CancellationError.self) {
            try await operation.value
        }

        #expect(driver.drafts.count == 1)
    }
}
