/// Stable authentication failures exposed outside the provider adapter.
enum AuthenticationError: Error, Equatable {
    /// The supplied credentials cannot authenticate a principal.
    case invalidCredentials

    /// The provider has disabled the matching account.
    ///
    /// Presentation must use the same login message as `invalidCredentials` to avoid revealing
    /// whether an account exists.
    case accountDisabled

    /// Authentication cannot complete now because of a transient provider condition.
    case temporarilyUnavailable

    /// Authentication is unavailable because required provider configuration is invalid.
    case configuration

    /// The provider cannot read or update its secure credential storage.
    case secureStorageUnavailable

    /// Authentication failed for a reason that has no stable domain classification.
    case unexpected
}

/// Provides provider-neutral access to authentication and session state.
protocol AuthenticationRepository: Sendable {
    /// Authenticates with the MVP email and password mechanism.
    ///
    /// The credentials are ephemeral operation parameters and must not be persisted, logged or
    /// sent to telemetry.
    ///
    /// - Parameters:
    ///   - email: The externally provisioned account email.
    ///   - password: The account password.
    /// - Returns: The principal reported by the authentication provider.
    /// - Throws: `AuthenticationError` for a stable failure or `CancellationError` when the
    ///   repository can honor cancellation.
    func signIn(
        email: String,
        password: String
    ) async throws -> AuthenticationSession

    /// Ends the provider session and clears its secure local authentication state.
    ///
    /// - Throws: `AuthenticationError` for a stable failure or `CancellationError` when the
    ///   repository can honor cancellation.
    func signOut() async throws

    /// Starts observing the identity currently known by the provider.
    ///
    /// The first element is the current state. A `nil` element means signed out; later elements
    /// report session changes. A present session is not proof of a freshly validated token.
    ///
    /// - Returns: A nonthrowing stream of current and subsequent session states.
    func observeSession() async -> AsyncStream<AuthenticationSession?>
}
