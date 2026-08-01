import Observation

/// Coordinates the authoritative provider session with local biometric locking and sign-out intents.
///
/// Observation revisions and action identities prevent superseded asynchronous work from changing
/// the current principal or its lock state.
@Observable
@MainActor
final class SessionViewModel {
    /// Whether the current device can offer biometric-only unlocking.
    enum BiometricAvailability: Equatable {
        case available
        case unavailable
    }

    /// The authoritative session and local-lock state presented by the application.
    enum State: Equatable {
        case idle
        case loading
        case signedOut
        case locked(AuthenticationSession, BiometricAvailability)
        case unlocked(AuthenticationSession)
        case failed(Failure)
    }

    /// Failures of the long-lived session observation.
    enum Failure: Equatable {
        case observationEnded
    }

    /// The lifecycle of an operation performed against the current principal.
    enum ActionState: Equatable {
        case idle
        case unlocking
        case signingOut
        case failed(ActionFailure)
    }

    /// Provider-neutral failures for biometric and sign-out actions.
    enum ActionFailure: Equatable {
        case biometricDenied
        case biometricCancelled
        case biometricUnavailable
        case temporarilyUnavailable
        case configuration
        case secureStorageUnavailable
        case unexpected
    }

    private enum ActionKind {
        case unlock
        case signOut
    }

    private struct ActionAttempt {
        let revision: Int
        let kind: ActionKind
        let principalID: String
    }

    private(set) var state: State = .idle
    private(set) var actionState: ActionState = .idle

    private let observeSessionUseCase: ObserveSessionUseCase
    private let signOutUseCase: SignOutUseCase
    private let biometricAuthenticator: BiometricAuthenticator

    private var observationRevision = 0
    private var actionRevision = 0
    private var activeAction: ActionAttempt?

    init(
        observeSession: ObserveSessionUseCase,
        signOut: SignOutUseCase,
        biometricAuthenticator: BiometricAuthenticator
    ) {
        observeSessionUseCase = observeSession
        signOutUseCase = signOut
        self.biometricAuthenticator = biometricAuthenticator
    }

    /// Observes the provider session until the caller-owned task is cancelled or the stream ends.
    ///
    /// A replacement call invalidates the earlier observation and any action attached to its
    /// principal. Cancellation restores `idle`; unexpected stream completion reports failure.
    func load() async {
        let revision = beginObservation()
        let stream = await observeSessionUseCase()

        guard isCurrentObservation(revision) else {
            return
        }
        guard !Task.isCancelled else {
            finishObservation(revision, with: .idle)
            return
        }

        for await session in stream {
            guard isCurrentObservation(revision) else {
                return
            }
            guard !Task.isCancelled else {
                finishObservation(revision, with: .idle)
                return
            }

            applyObservedSession(session)
        }

        guard isCurrentObservation(revision) else {
            return
        }

        finishObservation(
            revision,
            with: Task.isCancelled ? .idle : .failed(.observationEnded)
        )
    }

    /// Attempts biometric unlocking for the currently locked principal.
    ///
    /// Duplicate or crossing actions are ignored. A result is applied only while its action
    /// identity and principal still match the authoritative observation.
    ///
    /// - Parameter localizedReason: The localized explanation displayed by the system prompt.
    func unlock(localizedReason: String) async {
        guard actionState.acceptsNewAction else {
            return
        }
        guard case let .locked(session, _) = state else {
            return
        }

        let attempt = beginAction(.unlock, principalID: session.id)
        let availability: BiometricAvailability = biometricAuthenticator.canAuthenticate()
            ? .available
            : .unavailable
        state = .locked(session, availability)

        guard availability == .available else {
            finishAction(attempt, with: .failed(.biometricUnavailable))
            return
        }

        do {
            try await biometricAuthenticator.authenticate(localizedReason: localizedReason)
            guard isCurrentAction(attempt) else {
                return
            }
            guard case let .locked(currentSession, _) = state else {
                return
            }

            activeAction = nil
            actionState = .idle
            state = .unlocked(currentSession)
        } catch is CancellationError {
            finishAction(attempt, with: .idle)
        } catch let error as BiometricAuthenticationError {
            finishAction(attempt, with: .failed(ActionFailure(error)))
        } catch {
            finishAction(attempt, with: .failed(.unexpected))
        }
    }

    /// Requests provider sign-out for the current principal.
    ///
    /// Success remains `signingOut` until session observation publishes authoritative `nil`.
    /// Duplicate or crossing actions are ignored, and stale completions have no effect.
    func signOut() async {
        guard actionState.acceptsNewAction, let session = currentSession else {
            return
        }

        let attempt = beginAction(.signOut, principalID: session.id)

        do {
            try await signOutUseCase()
            guard isCurrentAction(attempt) else {
                return
            }
        } catch is CancellationError {
            finishAction(attempt, with: .idle)
        } catch let error as AuthenticationError {
            finishAction(attempt, with: .failed(ActionFailure(signOutError: error)))
        } catch {
            finishAction(attempt, with: .failed(.unexpected))
        }
    }

    private var currentSession: AuthenticationSession? {
        switch state {
        case let .locked(session, _), let .unlocked(session):
            session
        case .idle, .loading, .signedOut, .failed:
            nil
        }
    }

    private func beginObservation() -> Int {
        observationRevision += 1
        invalidateAction()
        state = .loading
        return observationRevision
    }

    private func isCurrentObservation(_ revision: Int) -> Bool {
        observationRevision == revision
    }

    private func finishObservation(_ revision: Int, with finalState: State) {
        guard isCurrentObservation(revision) else {
            return
        }

        observationRevision += 1
        invalidateAction()
        state = finalState
    }

    private func applyObservedSession(_ session: AuthenticationSession?) {
        guard let session else {
            invalidateAction()
            state = .signedOut
            return
        }

        guard currentSession?.id != session.id else {
            return
        }

        invalidateAction()
        let availability: BiometricAvailability = biometricAuthenticator.canAuthenticate()
            ? .available
            : .unavailable
        state = .locked(session, availability)
    }

    private func beginAction(_ kind: ActionKind, principalID: String) -> ActionAttempt {
        actionRevision += 1
        let attempt = ActionAttempt(
            revision: actionRevision,
            kind: kind,
            principalID: principalID
        )
        activeAction = attempt
        actionState = kind == .unlock ? .unlocking : .signingOut
        return attempt
    }

    private func isCurrentAction(_ attempt: ActionAttempt) -> Bool {
        guard let activeAction else {
            return false
        }

        return activeAction.revision == attempt.revision
            && activeAction.kind == attempt.kind
            && activeAction.principalID == attempt.principalID
            && currentSession?.id == attempt.principalID
    }

    private func finishAction(_ attempt: ActionAttempt, with finalState: ActionState) {
        guard isCurrentAction(attempt) else {
            return
        }

        activeAction = nil
        actionState = finalState
    }

    private func invalidateAction() {
        actionRevision += 1
        activeAction = nil
        actionState = .idle
    }
}

private extension SessionViewModel.ActionState {
    var acceptsNewAction: Bool {
        switch self {
        case .idle, .failed:
            true
        case .unlocking, .signingOut:
            false
        }
    }
}

private extension SessionViewModel.ActionFailure {
    init(_ error: BiometricAuthenticationError) {
        switch error {
        case .denied:
            self = .biometricDenied
        case .cancelled:
            self = .biometricCancelled
        case .unavailable:
            self = .biometricUnavailable
        case .configuration:
            self = .configuration
        case .unexpected:
            self = .unexpected
        }
    }

    init(signOutError error: AuthenticationError) {
        switch error {
        case .temporarilyUnavailable:
            self = .temporarilyUnavailable
        case .configuration:
            self = .configuration
        case .secureStorageUnavailable:
            self = .secureStorageUnavailable
        case .invalidCredentials, .accountDisabled, .unexpected:
            self = .unexpected
        }
    }
}
