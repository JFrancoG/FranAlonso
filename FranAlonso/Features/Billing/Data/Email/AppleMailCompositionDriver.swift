import Foundation

/// Contains the native presentation/delegate lifetime behind the asynchronous email boundary.
///
/// Completion reports the person's native choice after dismissal; queued is not delivery confirmation.
/// Implementations reject unavailable presentation and never initiate sending themselves.
@MainActor
protocol AppleMailCompositionDriver: AnyObject {
    var canCompose: Bool { get }

    func start(
        _ draft: EmailDraft,
        completion: @escaping @MainActor (EmailCompositionResult) -> Void
    ) throws

    /// Requests dismissal of the driver's current composition without retracting a queued message.
    func cancel()
}
