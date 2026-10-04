import MessageUI
import UIKit

/// Contains Apple's editable, manually submitted Mail interface behind the async adapter's SDK boundary.
/// A caller owns the presenter; this driver neither finds a global window nor activates an app journey.
@MainActor
final class MessageUIMailCompositionDriver: NSObject, AppleMailCompositionDriver, MFMailComposeViewControllerDelegate {
    private weak var presenter: UIViewController?
    private var active: ActiveComposition?

    init(presenter: UIViewController) {
        self.presenter = presenter
    }

    var canCompose: Bool {
        guard
            active == nil,
            MFMailComposeViewController.canSendMail(),
            let presenter,
            presenter.isViewLoaded,
            presenter.view.window != nil,
            presenter.presentedViewController == nil,
            !presenter.isBeingPresented,
            !presenter.isBeingDismissed
        else { return false }
        return true
    }

    func start(
        _ draft: EmailDraft,
        completion: @escaping @MainActor (EmailCompositionResult) -> Void
    ) throws {
        guard canCompose, let presenter else { throw BillingEmailError.unavailable }
        let controller = MFMailComposeViewController()
        controller.setToRecipients([draft.recipient])
        controller.setSubject(draft.subject)
        controller.setMessageBody(draft.body, isHTML: false)
        controller.addAttachmentData(draft.pdf, mimeType: draft.mimeType, fileName: draft.fileName)
        controller.mailComposeDelegate = self
        let token = UUID()
        active = ActiveComposition(token: token, controller: controller, completion: completion)
        // The SDK animation retains its owner until pending cancellation can complete dismissal.
        presenter.present(controller, animated: true) { [self, weak controller] in
            guard let controller, owns(token, controller: controller) else { return }
            active?.presented = true
            dismissIfRequested(token, controller: controller)
        }
    }

    func cancel() {
        guard let flow = active else { return }
        requestFinish(.cancellation, token: flow.token, controller: flow.controller)
    }

    func mailComposeController(
        _ controller: MFMailComposeViewController,
        didFinishWith result: MFMailComposeResult,
        error: (any Error)?
    ) {
        guard let flow = active, flow.controller === controller else { return }
        requestFinish(
            .result(Self.outcome(for: result, hasError: error != nil)),
            token: flow.token,
            controller: controller
        )
    }

    /// Maps the SDK outbox outcome without claiming recipient delivery or exposing SDK errors.
    static func outcome(for result: MFMailComposeResult, hasError: Bool) -> EmailCompositionResult {
        guard !hasError else { return .failed }
        switch result {
        case .cancelled: return .cancelled
        case .saved: return .saved
        case .sent: return .queued
        case .failed: return .failed
        @unknown default: return .failed
        }
    }

    private func owns(_ token: UUID, controller: MFMailComposeViewController) -> Bool {
        active?.token == token && active?.controller === controller
    }

    private func requestFinish(_ finish: Finish, token: UUID, controller: MFMailComposeViewController) {
        guard owns(token, controller: controller), active?.finish == nil else { return }
        active?.finish = finish
        dismissIfRequested(token, controller: controller)
    }

    private func dismissIfRequested(_ token: UUID, controller: MFMailComposeViewController) {
        guard
            owns(token, controller: controller),
            let flow = active,
            flow.presented,
            let finish = flow.finish,
            !flow.dismissing
        else { return }
        active?.dismissing = true
        // Retain only through native dismissal; cleanup remains fenced by controller and operation identity.
        controller.dismiss(animated: true) { [self, weak controller] in
            guard let controller, owns(token, controller: controller) else { return }
            let completion = active?.completion
            controller.mailComposeDelegate = nil
            active = nil
            if case .result(let result) = finish {
                completion?(result)
            }
        }
    }

    private enum Finish {
        case result(EmailCompositionResult)
        case cancellation
    }

    private struct ActiveComposition {
        let token: UUID
        let controller: MFMailComposeViewController
        let completion: @MainActor (EmailCompositionResult) -> Void
        var presented = false
        var dismissing = false
        var finish: Finish?
    }
}
