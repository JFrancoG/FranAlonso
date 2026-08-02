import Observation

/// Coordinates provider session authority, local proof and access to the protected application root.
///
/// A sign-in result records only ephemeral credential proof. Protected access additionally requires
/// the session stream to publish the same principal and local-store authorization to complete.
@Observable
@MainActor
final class AuthenticationRootViewModel {
    /// The mutually exclusive roots and secure transitional states visible to the application.
    enum State: Equatable {
        case checkingSession
        case signedOut
        case locked
        case authorizingLocalAccess
        case authenticated(AuthenticationSession)
        case localAccessDenied(Failure)
        case signingOut
        case observationFailed
    }

    /// Stable failures presented when local-store authorization fails closed.
    enum Failure: Equatable {
        case differentPrincipal
        case localStoreNotPristine
        case secureStorageUnavailable
        case localStoreUnavailable
        case unexpected
    }

    struct AccessTrigger: Equatable {
        let sessionState: SessionViewModel.State
        let credentialProofRevision: Int
        let localAccessRevision: Int
    }

    private struct CredentialProof: Equatable {
        let session: AuthenticationSession
        let revision: Int
        let localAccessRevision: Int
    }

    private enum AccessEvidence: Equatable {
        case recentCredentials(CredentialProof)
        case biometrics
    }

    private enum LocalAccessState: Equatable {
        case idle
        case authorizing(String, Int)
        case authorized(AuthenticationSession, Int)
        case denied(String, Int, Failure)
    }

    let loginViewModel: LoginViewModel
    let sessionViewModel: SessionViewModel
    private(set) var observationRequestID = 0
    private(set) var credentialProofRevision = 0

    private let authorizeLocalPrincipalUseCase: AuthorizeLocalPrincipalUseCase
    private var credentialProof: CredentialProof?
    private var localAccessState: LocalAccessState = .idle
    private var authorizationRevision = 0
    private var lastObservedPrincipalID: String?

    /// Maps the authoritative session and local authorization into one application root.
    var state: State {
        if sessionViewModel.actionState == .signingOut {
            return .signingOut
        }

        switch sessionViewModel.state {
        case .idle, .loading:
            return .checkingSession
        case .signedOut:
            return .signedOut
        case let .locked(session, _):
            return protectedState(for: session, allowsBiometricEvidence: false)
        case let .unlocked(session):
            return protectedState(for: session, allowsBiometricEvidence: true)
        case .failed:
            return .observationFailed
        }
    }

    /// Identifies when SwiftUI must reconsider local authorization.
    var accessTrigger: AccessTrigger {
        AccessTrigger(
            sessionState: sessionViewModel.state,
            credentialProofRevision: credentialProofRevision,
            localAccessRevision: sessionViewModel.localAccessRevision
        )
    }

    init(
        signIn: SignInUseCase,
        observeSession: ObserveSessionUseCase,
        signOut: SignOutUseCase,
        biometricAuthenticator: BiometricAuthenticator,
        authorizeLocalPrincipal: AuthorizeLocalPrincipalUseCase
    ) {
        loginViewModel = LoginViewModel(signIn: signIn)
        sessionViewModel = SessionViewModel(
            observeSession: observeSession,
            signOut: signOut,
            biometricAuthenticator: biometricAuthenticator
        )
        authorizeLocalPrincipalUseCase = authorizeLocalPrincipal
    }

    /// Records a successful credential intent without granting protected access.
    ///
    /// The proof remains usable only until an authoritative `nil`, a different principal, a retry,
    /// cancellation or replacement invalidates it.
    func registerRecentSignIn(_ session: AuthenticationSession) {
        authorizationRevision += 1
        localAccessState = .idle
        credentialProofRevision += 1
        credentialProof = CredentialProof(
            session: session,
            revision: credentialProofRevision,
            localAccessRevision: sessionViewModel.localAccessRevision
        )
    }

    /// Reconciles the currently visible provider state for presentation cleanup.
    ///
    /// Security does not depend on SwiftUI delivering every change: `SessionViewModel` records
    /// invalidating stream events synchronously in `localAccessRevision`, which all evidence
    /// captures and verifies before it can grant access.
    func sessionEventDidChange() {
        switch sessionViewModel.state {
        case .signedOut:
            let shouldResetLogin = lastObservedPrincipalID != nil || credentialProof != nil
            lastObservedPrincipalID = nil
            invalidateLocalAccess(resetLogin: shouldResetLogin)
        case let .locked(session, _), let .unlocked(session):
            let principalChanged = lastObservedPrincipalID.map { $0 != session.id } ?? false
            let credentialMismatch = credentialProof.map { $0.session.id != session.id } ?? false
            lastObservedPrincipalID = session.id

            if principalChanged || credentialMismatch {
                invalidateLocalAccess(resetLogin: true)
            }
        case .idle, .loading, .failed:
            break
        }
    }

    /// Applies eligible credential or biometric proof to the observed principal.
    ///
    /// Late results are ignored unless their authorization revision, principal and evidence still
    /// match the current authoritative state.
    func authorizeLocalAccessIfNeeded() async {
        guard let request = authorizationRequest else {
            return
        }
        if case let .authorizing(principalID, localAccessRevision) = localAccessState,
           principalID == request.session.id,
           localAccessRevision == request.localAccessRevision {
            return
        }

        authorizationRevision += 1
        localAccessState = .authorizing(request.session.id, request.localAccessRevision)
        await performAuthorization(request)
    }

    /// Replaces the session observation and clears all local proof before retrying.
    func retryObservation() {
        observationRequestID += 1
        lastObservedPrincipalID = nil
        invalidateLocalAccess(resetLogin: true)
    }

    /// Requests logout while preserving the last authorized shell only if the operation fails.
    ///
    /// `state` becomes `signingOut` immediately and remains protected until the stream publishes
    /// authoritative `nil` or the operation reports a failure.
    func signOut() async {
        await sessionViewModel.signOut()
    }

    private var authorizationRequest: (
        session: AuthenticationSession,
        evidence: AccessEvidence,
        localAccessRevision: Int
    )? {
        let session: AuthenticationSession
        let allowsBiometricEvidence: Bool
        let localAccessRevision = sessionViewModel.localAccessRevision

        switch sessionViewModel.state {
        case let .locked(currentSession, _):
            session = currentSession
            allowsBiometricEvidence = false
        case let .unlocked(currentSession):
            session = currentSession
            allowsBiometricEvidence = true
        case .idle, .loading, .signedOut, .failed:
            return nil
        }

        if case let .authorized(authorizedSession, authorizedRevision) = localAccessState,
           authorizedSession.id == session.id,
           authorizedRevision == localAccessRevision {
            return nil
        }
        if case let .denied(principalID, deniedRevision, _) = localAccessState,
           principalID == session.id,
           deniedRevision == localAccessRevision {
            return nil
        }

        if let credentialProof,
           credentialProof.session.id == session.id,
           credentialProof.localAccessRevision == localAccessRevision {
            return (session, .recentCredentials(credentialProof), localAccessRevision)
        }
        if allowsBiometricEvidence {
            return (session, .biometrics, localAccessRevision)
        }
        return nil
    }

    private func performAuthorization(
        _ request: (
            session: AuthenticationSession,
            evidence: AccessEvidence,
            localAccessRevision: Int
        )
    ) async {
        let revision = authorizationRevision

        do {
            try await authorizeLocalPrincipalUseCase(session: request.session)
            try Task.checkCancellation()
            guard authorizationRevision == revision, evidenceIsCurrent(request) else {
                return
            }

            localAccessState = .authorized(request.session, request.localAccessRevision)
            if case .recentCredentials = request.evidence {
                clearCredentialProof()
            }
        } catch is CancellationError {
            guard authorizationRevision == revision else { return }
            localAccessState = .idle
            if case .recentCredentials = request.evidence {
                clearCredentialProof()
            }
        } catch let error as LocalPrincipalAuthorizationError {
            guard authorizationRevision == revision, evidenceIsCurrent(request) else { return }
            localAccessState = .denied(
                request.session.id,
                request.localAccessRevision,
                Failure(error)
            )
            clearCredentialProof()
        } catch {
            guard authorizationRevision == revision, evidenceIsCurrent(request) else { return }
            localAccessState = .denied(
                request.session.id,
                request.localAccessRevision,
                .unexpected
            )
            clearCredentialProof()
        }
    }

    private func evidenceIsCurrent(
        _ request: (
            session: AuthenticationSession,
            evidence: AccessEvidence,
            localAccessRevision: Int
        )
    ) -> Bool {
        guard sessionViewModel.localAccessRevision == request.localAccessRevision else {
            return false
        }

        switch (sessionViewModel.state, request.evidence) {
        case let (.locked(currentSession, _), .recentCredentials(proof)),
             let (.unlocked(currentSession), .recentCredentials(proof)):
            return currentSession.id == request.session.id && credentialProof == proof
        case let (.unlocked(currentSession), .biometrics):
            return currentSession.id == request.session.id
        case (.idle, _), (.loading, _), (.signedOut, _), (.locked, .biometrics), (.failed, _):
            return false
        }
    }

    private func protectedState(
        for session: AuthenticationSession,
        allowsBiometricEvidence: Bool
    ) -> State {
        let localAccessRevision = sessionViewModel.localAccessRevision

        switch localAccessState {
        case let .authorized(authorizedSession, authorizedRevision)
            where authorizedSession.id == session.id && authorizedRevision == localAccessRevision:
            return .authenticated(authorizedSession)
        case let .denied(principalID, deniedRevision, failure)
            where principalID == session.id && deniedRevision == localAccessRevision:
            return .localAccessDenied(failure)
        case let .authorizing(principalID, authorizingRevision)
            where principalID == session.id && authorizingRevision == localAccessRevision:
            return .authorizingLocalAccess
        case .idle, .authorizing, .authorized, .denied:
            let hasCurrentCredentialProof = credentialProof?.session.id == session.id
                && credentialProof?.localAccessRevision == localAccessRevision
            if hasCurrentCredentialProof || allowsBiometricEvidence {
                return .authorizingLocalAccess
            }
            return .locked
        }
    }

    private func invalidateLocalAccess(resetLogin: Bool) {
        authorizationRevision += 1
        localAccessState = .idle
        clearCredentialProof()
        if resetLogin {
            loginViewModel.resetForAuthoritativeSessionChange()
        }
    }

    private func clearCredentialProof() {
        guard credentialProof != nil else { return }
        credentialProof = nil
        credentialProofRevision += 1
    }
}

private extension AuthenticationRootViewModel.Failure {
    init(_ error: LocalPrincipalAuthorizationError) {
        switch error {
        case .differentPrincipal:
            self = .differentPrincipal
        case .localStoreNotPristine:
            self = .localStoreNotPristine
        case .secureStorageUnavailable:
            self = .secureStorageUnavailable
        case .localStoreUnavailable:
            self = .localStoreUnavailable
        case .unexpected:
            self = .unexpected
        }
    }
}
