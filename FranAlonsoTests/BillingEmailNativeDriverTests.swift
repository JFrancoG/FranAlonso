import MessageUI
import Testing
import UIKit
@testable import FranAlonso

@Suite("Manual Mail SDK boundary")
@MainActor
struct BillingEmailNativeDriverTests {
    @Test(arguments: [
        (MFMailComposeResult.cancelled, EmailCompositionResult.cancelled),
        (.saved, .saved),
        (.sent, .queued),
        (.failed, .failed)
    ])
    func `native outcomes preserve manual outbox semantics`(
        _ native: MFMailComposeResult,
        _ expected: EmailCompositionResult
    ) {
        #expect(MessageUIMailCompositionDriver.outcome(for: native, hasError: false) == expected)
        #expect(MessageUIMailCompositionDriver.outcome(for: native, hasError: true) == .failed)
    }

    @Test
    func `an unattached presenter cannot expose a composition interface`() {
        let presenter = UIViewController()
        let driver = MessageUIMailCompositionDriver(presenter: presenter)
        #expect(!driver.canCompose)
        #expect(!presenter.isViewLoaded)
        #expect(presenter.presentedViewController == nil)
    }

    @Test
    func `Simulator without configured Mail rejects start without initializing presentation`() throws {
        try #require(!MFMailComposeViewController.canSendMail(), "This guard is validated on unconfigured Simulator.")
        let presenter = UIViewController()
        let driver = MessageUIMailCompositionDriver(presenter: presenter)
        let draft = try BillingEmailComposerFixtures.draft()
        #expect(throws: BillingEmailError.unavailable) {
            try driver.start(draft) { _ in
                Issue.record("Unavailable Mail must not report a manual composition outcome.")
            }
        }
        #expect(!presenter.isViewLoaded)
        #expect(presenter.presentedViewController == nil)
    }
}
