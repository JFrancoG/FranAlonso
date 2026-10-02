import Foundation
import Observation

/// Coordinates one caller-owned percentage edit with the retained parent draft's acceptance capability.
/// Validated commands are frozen before suspension; the parent alone owns the sale and calculated totals.
@Observable @MainActor
final class SaleDiscountViewModel {
    enum Target: Equatable {
        case line(serviceName: String)
        case global
    }

    enum State: Equatable {
        case editing
        case requested(UUID, Discount?)
        case applying(UUID, Discount?)
        case invalidInput
        case failed(Discount?)
        case unavailable
        case accepted
        case closed
    }

    let target: Target
    var serviceName: String? {
        switch target {
        case let .line(serviceName): serviceName
        case .global: nil
        }
    }
    var title: LocalizedStringResource {
        target == .global ? "sales.discount.global.title" : "sales.discount.title"
    }
    var instructions: LocalizedStringResource {
        target == .global ? "sales.discount.global.instructions" : "sales.discount.instructions"
    }
    var discountText: String {
        didSet {
            guard discountText != oldValue, !isBusy, state != .closed, !hasAcceptedChange else { return }
            state = .editing
        }
    }
    private(set) var state: State = .editing
    private let initialDiscount: Discount?
    private let input: LocalizedDecimalInput
    private let canApply: @MainActor @Sendable () -> Bool
    private let apply: @MainActor @Sendable (Discount?) async throws -> Void

    /// Retains task identity while applying so `.task(id:)` does not cancel its own accepted write.
    var requestID: UUID? {
        switch state {
        case let .requested(id, _), let .applying(id, _): id
        default: nil
        }
    }

    var isBusy: Bool { requestID != nil }
    var canEdit: Bool { state != .closed && !hasAcceptedChange && !isBusy && canApply() }
    var hasAcceptedChange: Bool { state == .accepted }
    var hasInputError: Bool { state == .invalidInput }
    var hasAcceptanceError: Bool {
        if case .failed = state {
            return true
        }
        return false
    }
    var isUnavailable: Bool { state == .unavailable }
    var canRemove: Bool { initialDiscount != nil && canEdit }

    /// Captures complete localized input as percentage points in `0...100` without rounding.
    /// Empty input is invalid; only the separate removal intention represents absence.
    func requestApply() {
        guard state != .closed, !hasAcceptedChange, !isBusy else { return }
        guard canApply() else {
            state = .unavailable
            return
        }
        guard let percentage = input.parse(discountText), let discount = try? Discount(percentage: percentage) else {
            state = .invalidInput
            return
        }
        state = .requested(UUID(), discount)
    }

    /// Captures explicit absence only when the session began with a discount, including an explicit zero.
    func requestRemoval() {
        guard state != .closed, !hasAcceptedChange, !isBusy, initialDiscount != nil else { return }
        guard canApply() else {
            state = .unavailable
            return
        }
        state = .requested(UUID(), nil)
    }

    /// Starts a new caller-owned task for the same failed command without reparsing input.
    /// Editing text abandons the failed command and requires a new explicit application.
    func retry() {
        guard case let .failed(discount) = state else { return }
        guard canApply() else {
            state = .unavailable
            return
        }
        state = .requested(UUID(), discount)
    }

    /// Delegates acceptance once; durable success remains success after caller cancellation.
    /// Preacceptance cancellation returns to editing; close fences publication without undoing a parent write.
    func submit() async {
        guard case let .requested(requestID, discount) = state else { return }
        state = .applying(requestID, discount)
        do {
            try Task.checkCancellation()
            guard canApply() else {
                state = .unavailable
                return
            }
            try await apply(discount)
            guard self.requestID == requestID else { return }
            state = .accepted
        } catch {
            guard self.requestID == requestID else { return }
            state = error is CancellationError || Task.isCancelled ? .editing : .failed(discount)
        }
    }

    /// Ends only editor publication; the screen cancels its tasks and the retained parent draft remains alive.
    func close() {
        state = .closed
    }

    init(
        target: Target,
        discount: Discount?,
        locale: Locale,
        canEdit: @escaping @MainActor @Sendable () -> Bool,
        apply: @escaping @MainActor @Sendable (Discount?) async throws -> Void
    ) {
        self.target = target
        initialDiscount = discount
        let parser = LocalizedDecimalInput(locale: locale)
        input = parser
        discountText = discount.map { parser.format($0.percentage) } ?? ""
        canApply = canEdit
        self.apply = apply
    }
}
