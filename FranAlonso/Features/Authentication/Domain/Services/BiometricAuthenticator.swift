/// Authorizes local access to an already valid application session through device biometrics.
///
/// The capability neither creates nor validates a provider session and never handles credentials.
/// Availability is evaluated on every query because device biometric state can change at runtime.
struct BiometricAuthenticator {
    private let canAuthenticateOperation: @Sendable () -> Bool
    private let authenticateOperation: @Sendable (String) async throws -> Void

    /// Returns whether biometric authentication can be evaluated at the time of the call.
    func canAuthenticate() -> Bool {
        canAuthenticateOperation()
    }

    /// Authorizes access using a localized explanation of the protected action.
    ///
    /// - Parameter localizedReason: A nonempty reason displayed by the biometric prompt.
    /// - Throws: `CancellationError` when the task is cancelled, or a
    ///   `BiometricAuthenticationError` for a rejected request.
    func authenticate(localizedReason: String) async throws {
        try Task.checkCancellation()
        guard !localizedReason.isEmpty else { throw BiometricAuthenticationError.configuration }

        try await authenticateOperation(localizedReason)
        try Task.checkCancellation()
    }
}

extension BiometricAuthenticator {
    /// Creates a biometric capability from concurrency-safe operations.
    init(
        canAuthenticate: @escaping @Sendable () -> Bool,
        authenticate: @escaping @Sendable (String) async throws -> Void
    ) {
        canAuthenticateOperation = canAuthenticate
        authenticateOperation = authenticate
    }
}

/// Stable failures exposed by local biometric authorization.
enum BiometricAuthenticationError: Error, Equatable {
    /// Biometrics were evaluated but did not authorize access.
    case denied
    /// The person or the operating system cancelled the prompt while the Swift task remained active.
    case cancelled
    /// The device cannot currently evaluate the required biometric-only policy.
    case unavailable
    /// The caller supplied an invalid prompt configuration.
    case configuration
    /// LocalAuthentication failed outside the supported error contract.
    case unexpected
}
