/// Combines the existing durable principal authorizer with the caller's current session revision.
///
/// The session validator must reject logout, principal replacement and any changed access revision,
/// including a logout followed by a login of the same principal. It is checked around authorization
/// because a suspended binding lookup must not revive an obsolete editing or delivery session.
struct ClientDocumentAccess {
    let principalID: String
    private let session: AuthenticationSession
    private let authorizer: LocalPrincipalAuthorizer
    private let validateSession: @Sendable () async throws -> Void

    func validate() async throws {
        try Task.checkCancellation()
        try await validateSession()
        try Task.checkCancellation()
        try await authorizer.authorize(session)
        try Task.checkCancellation()
        try await validateSession()
        try Task.checkCancellation()
    }
}

extension ClientDocumentAccess {
    init(
        session: AuthenticationSession,
        authorizer: LocalPrincipalAuthorizer,
        validateSession: @escaping @Sendable () async throws -> Void
    ) {
        self.init(
            principalID: session.id,
            session: session,
            authorizer: authorizer,
            validateSession: validateSession
        )
    }
}

enum ClientDocumentAccessError: Error {
    case sessionExpired
}
