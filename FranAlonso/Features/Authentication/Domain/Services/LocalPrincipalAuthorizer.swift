/// Stable failures while authorizing an authenticated principal for the local store.
enum LocalPrincipalAuthorizationError: Error, Equatable {
    /// The store is already bound to another principal.
    case differentPrincipal

    /// Local rows exist but no trustworthy binding identifies their owner.
    case localStoreNotPristine

    /// The secure binding cannot be read or written reliably.
    case secureStorageUnavailable

    /// SwiftData cannot determine whether the local store is safe to claim.
    case localStoreUnavailable

    /// Local authorization failed outside the supported contract.
    case unexpected
}

/// Authorizes a provider principal to access the current local store.
///
/// The capability handles only the opaque principal identifier. It never receives credentials,
/// tokens, Firebase values or live SwiftData models.
struct LocalPrincipalAuthorizer {
    private let authorizeOperation: @Sendable (AuthenticationSession) async throws -> Void

    /// Authorizes the observed principal against the durable local binding.
    ///
    /// Cancellation is checked before and after the replaceable operation so a cancelled or
    /// superseded task cannot grant access from a late completion.
    ///
    /// - Parameter session: The principal currently published by the authoritative session stream.
    /// - Throws: `CancellationError` or a `LocalPrincipalAuthorizationError`.
    func authorize(_ session: AuthenticationSession) async throws {
        try Task.checkCancellation()
        guard !session.id.isEmpty else { throw LocalPrincipalAuthorizationError.unexpected }

        try await authorizeOperation(session)
        try Task.checkCancellation()
    }
}

extension LocalPrincipalAuthorizer {
    /// Creates the capability from a concurrency-safe authorization operation.
    init(
        authorize: @escaping @Sendable (AuthenticationSession) async throws -> Void
    ) {
        authorizeOperation = authorize
    }
}
