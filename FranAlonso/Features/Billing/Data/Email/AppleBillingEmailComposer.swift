import Foundation

/// Prepares one authorized native composition and contains its delegate's single completion.
///
/// Drafts remain in memory; this adapter never persists them, changes a sale or sends autonomously.
/// Native completion is a manual outcome, and queued does not establish recipient delivery.
@MainActor
final class AppleBillingEmailComposer: BillingEmailComposing {
    private let driver: any AppleMailCompositionDriver
    private let access: BillingAssetAccess
    private var operation: Operation?

    init(driver: any AppleMailCompositionDriver, access: BillingAssetAccess) {
        self.driver = driver
        self.access = access
    }

    /// Presents only a structurally readable PDF from the captured principal's final draft.
    ///
    /// Concurrent requests fail with `busy`. Cancellation dismisses only this operation and throws
    /// `CancellationError`; access is checked again before an outcome or neutral error is published.
    func compose(_ draft: EmailDraft) async throws -> EmailCompositionResult {
        try Task.checkCancellation()
        guard operation == nil else { throw BillingEmailError.busy }
        let token = UUID()
        operation = Operation(token: token, continuation: nil, driverStarted: false)
        defer {
            if operation?.token == token {
                operation = nil
            }
        }
        return try await withTaskCancellationHandler {
            do {
                try await validateAccess(for: draft)
                try await validateBillingEmailPDF(draft.pdf)
                try await validateAccess(for: draft)
                guard driver.canCompose else { throw BillingEmailError.unavailable }
                try Task.checkCancellation()
                let result = try await present(draft, token: token)
                try Task.checkCancellation()
                try await validateAccess(for: draft)
                try Task.checkCancellation()
                return result
            } catch is CancellationError {
                cancel(token: token)
                throw CancellationError()
            } catch {
                let failure = error as? BillingEmailError ?? .unavailable
                if Task.isCancelled {
                    cancel(token: token)
                    throw CancellationError()
                }
                do {
                    try await validateAccess(for: draft)
                } catch is CancellationError {
                    cancel(token: token)
                    throw CancellationError()
                } catch {
                    throw BillingEmailError.unauthorized
                }
                if Task.isCancelled {
                    cancel(token: token)
                    throw CancellationError()
                }
                throw failure
            }
        } onCancel: {
            Task { @MainActor [weak self] in
                self?.cancel(token: token)
            }
        }
    }

    private struct Operation {
        let token: UUID
        var continuation: CheckedContinuation<EmailCompositionResult, any Error>?
        var driverStarted: Bool
    }
}

private extension AppleBillingEmailComposer {
    func validateAccess(for draft: EmailDraft) async throws {
        try Task.checkCancellation()
        guard draft.principalID == access.principalID else { throw BillingEmailError.unauthorized }
        do {
            try await access.validate()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw BillingEmailError.unauthorized
        }
    }

    func present(_ draft: EmailDraft, token: UUID) async throws -> EmailCompositionResult {
        try await withCheckedThrowingContinuation { continuation in
            guard operation?.token == token, !Task.isCancelled else {
                continuation.resume(throwing: CancellationError())
                return
            }
            operation?.continuation = continuation
            operation?.driverStarted = true
            do {
                try driver.start(draft) { [weak self] result in
                    self?.finish(token: token, result: .success(result))
                }
            } catch is CancellationError {
                finish(token: token, result: .failure(CancellationError()))
            } catch {
                finish(token: token, result: .failure(BillingEmailError.unavailable))
            }
        }
    }

    func finish(token: UUID, result: Result<EmailCompositionResult, any Error>) {
        guard operation?.token == token, let continuation = operation?.continuation else { return }
        operation?.continuation = nil
        operation?.driverStarted = false
        continuation.resume(with: result)
    }

    func cancel(token: UUID) {
        guard let active = operation, active.token == token else { return }
        operation?.continuation = nil
        operation?.driverStarted = false
        if active.driverStarted {
            driver.cancel()
        }
        active.continuation?.resume(throwing: CancellationError())
    }
}

@concurrent
private func validateBillingEmailPDF(_ data: Data) async throws {
    do {
        try BillingPDFUploadValidator.validate(data)
    } catch is CancellationError {
        throw CancellationError()
    } catch {
        throw BillingEmailError.invalidDraft
    }
}
