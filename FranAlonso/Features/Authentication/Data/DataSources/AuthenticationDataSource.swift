/// Provider-neutral failures exposed by the Authentication infrastructure boundary.
enum AuthenticationDataSourceError: Error, Equatable {
    /// The supplied credentials were rejected without exposing whether the principal exists.
    case credentialsRejected

    /// The provider reports that the matching account is disabled.
    case accountDisabled

    /// Authentication could not reach the provider.
    case networkUnavailable

    /// The provider rejected the operation because its request limit was reached.
    case rateLimited

    /// Required authentication provider configuration is invalid or unavailable.
    case misconfigured

    /// The provider could not access its secure credential storage.
    case secureStorageUnavailable

    /// The provider failed without a more specific stable infrastructure meaning.
    case unexpected
}

/// Performs provider-backed Authentication operations without exposing SDK types.
protocol AuthenticationDataSource: Sendable {
    /// Authenticates with ephemeral email and password values.
    ///
    /// - Parameters:
    ///   - email: The externally provisioned account email.
    ///   - password: The account password.
    /// - Returns: The provider-neutral identity reported by the provider.
    /// - Throws: `AuthenticationDataSourceError` for a stable infrastructure failure, or
    ///   `CancellationError` when cancellation can be honored.
    func signIn(
        email: String,
        password: String
    ) async throws -> AuthenticationSession

    /// Ends the provider session and clears its secure local authentication state.
    ///
    /// - Throws: `AuthenticationDataSourceError` for a stable infrastructure failure, or
    ///   `CancellationError` when cancellation can be honored.
    func signOut() async throws

    /// Starts observing the provider's current and subsequent authentication states.
    ///
    /// The first element is the current state. The adapter preserves every later transition in
    /// source order without coalescing, and releases provider observation when iteration ends or
    /// is cancelled.
    ///
    /// - Returns: A nonthrowing stream whose `nil` elements represent signed-out state.
    func observeSession() async -> AsyncStream<AuthenticationSession?>
}
