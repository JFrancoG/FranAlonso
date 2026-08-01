import Foundation
import LocalAuthentication

extension BiometricAuthenticator {
    /// Creates the live biometric-only adapter.
    ///
    /// Each authorization uses a fresh `LAContext`. Device passcode, companion-device authentication
    /// and application-password fallback are deliberately excluded by ADR 0020.
    static func localAuthentication() -> Self {
        localAuthentication(
            canEvaluate: {
                LAContext().canEvaluatePolicy(
                    .deviceOwnerAuthenticationWithBiometrics,
                    error: nil
                )
            },
            makeEvaluation: {
                let context = LocalAuthenticationEvaluationContext()
                return BiometricPolicyEvaluation(
                    evaluate: { localizedReason in
                        try await context.evaluate(localizedReason: localizedReason)
                    },
                    invalidate: {
                        await context.invalidate()
                    }
                )
            }
        )
    }

    /// Creates the LocalAuthentication adapter from deterministic provider operations.
    ///
    /// The evaluation factory represents one prompt attempt. Cancellation invalidates that attempt
    /// before the public operation completes with `CancellationError`.
    static func localAuthentication(
        canEvaluate: @escaping @Sendable () -> Bool,
        makeEvaluation: @escaping @Sendable () -> BiometricPolicyEvaluation
    ) -> Self {
        Self(
            canAuthenticate: canEvaluate,
            authenticate: { localizedReason in
                let evaluation = makeEvaluation()
                let authorized: Bool

                do {
                    authorized = try await withTaskCancellationHandler {
                        let result = try await evaluation.evaluate(localizedReason: localizedReason)
                        try Task.checkCancellation()
                        return result
                    } onCancel: {
                        Task { @concurrent in
                            await evaluation.invalidate()
                        }
                    }
                } catch let error as CancellationError {
                    throw error
                } catch {
                    try Task.checkCancellation()
                    throw Self.authenticationError(from: error)
                }

                try Task.checkCancellation()
                guard authorized else {
                    throw BiometricAuthenticationError.denied
                }
            }
        )
    }
}

/// Concurrency-safe operations owned by one biometric policy evaluation.
struct BiometricPolicyEvaluation {
    private let evaluateOperation: @Sendable (String) async throws -> Bool
    private let invalidateOperation: @Sendable () async -> Void

    /// Evaluates the policy with the localized reason for this attempt.
    func evaluate(localizedReason: String) async throws -> Bool {
        try await evaluateOperation(localizedReason)
    }

    /// Invalidates the provider work associated with this attempt.
    func invalidate() async {
        await invalidateOperation()
    }
}

extension BiometricPolicyEvaluation {
    /// Creates one evaluation from concurrency-safe provider operations.
    init(
        evaluate: @escaping @Sendable (String) async throws -> Bool,
        invalidate: @escaping @Sendable () async -> Void
    ) {
        evaluateOperation = evaluate
        invalidateOperation = invalidate
    }
}

private actor LocalAuthenticationEvaluationContext {
    private let context: LAContext

    init() {
        context = LAContext()
        context.localizedFallbackTitle = ""
    }

    func evaluate(localizedReason: String) async throws -> Bool {
        var evaluationError: NSError?
        guard context.canEvaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            error: &evaluationError
        ) else {
            throw evaluationError ?? BiometricAuthenticationError.unavailable
        }

        return try await context.evaluatePolicy(
            .deviceOwnerAuthenticationWithBiometrics,
            localizedReason: localizedReason
        )
    }

    func invalidate() {
        context.invalidate()
    }
}

private extension BiometricAuthenticator {
    static func authenticationError(from error: any Error) -> BiometricAuthenticationError {
        if let biometricError = error as? BiometricAuthenticationError {
            return biometricError
        }

        let providerError = error as NSError
        guard providerError.domain == LAError.errorDomain else {
            return .unexpected
        }

        return switch providerError.code {
        case LAError.Code.authenticationFailed.rawValue:
            .denied
        case LAError.Code.userCancel.rawValue,
             LAError.Code.userFallback.rawValue,
             LAError.Code.systemCancel.rawValue,
             LAError.Code.appCancel.rawValue:
            .cancelled
        case LAError.Code.passcodeNotSet.rawValue,
             LAError.Code.biometryNotAvailable.rawValue,
             LAError.Code.biometryNotEnrolled.rawValue,
             LAError.Code.biometryLockout.rawValue,
             LAError.Code.notInteractive.rawValue:
            .unavailable
        default:
            .unexpected
        }
    }
}
