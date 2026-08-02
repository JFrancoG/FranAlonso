/// Coordinates authorization of an observed principal for the current local store.
struct AuthorizeLocalPrincipalUseCase {
    private let localPrincipalAuthorizer: LocalPrincipalAuthorizer

    /// Authorizes the session without exposing persistence or secure-storage details.
    ///
    /// - Parameter session: The principal published by the authoritative provider stream.
    /// - Throws: `CancellationError` or a `LocalPrincipalAuthorizationError` unchanged.
    func callAsFunction(session: AuthenticationSession) async throws {
        try await localPrincipalAuthorizer.authorize(session)
    }
}

extension AuthorizeLocalPrincipalUseCase {
    /// Creates the use case with the feature-owned local authorization capability.
    init(authorizer: LocalPrincipalAuthorizer) {
        localPrincipalAuthorizer = authorizer
    }
}
