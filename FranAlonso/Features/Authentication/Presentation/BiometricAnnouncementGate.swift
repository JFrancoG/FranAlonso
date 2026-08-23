/// Joins biometric results and scene lifecycle events into one presentation-only announcement effect.
///
/// Call ``beginAttempt()`` synchronously before starting LocalAuthentication. The gate then joins the failure with the
/// current scene state and absorbs late or reordered callbacks until a new attempt begins, preventing duplicate speech.
struct BiometricAnnouncementGate: Equatable {
    enum Effect: Equatable {
        case none
        case announce(SessionViewModel.ActionFailure)
        case presentFailureNormally
    }

    private enum State: Equatable {
        case idle
        case awaitingSceneDeparture
        case awaitingReturn(SessionViewModel.ActionFailure?)
        case awaitingFailureAfterReturn
        case delivered
    }

    private var state = State.idle

    /// Whether biometric feedback still belongs to an explicitly armed VoiceOver attempt.
    var isCoordinatingAttempt: Bool {
        state != .idle
    }

    /// Arms a fresh biometric attempt before LocalAuthentication can change scene or action state.
    mutating func beginAttempt() {
        state = .awaitingSceneDeparture
    }

    /// Records that LocalAuthentication covered the app, preserving any effect already delivered.
    mutating func sceneBecameInactive() {
        switch state {
        case .awaitingSceneDeparture, .awaitingFailureAfterReturn:
            state = .awaitingReturn(nil)
        case .idle, .awaitingReturn, .delivered:
            break
        }
    }

    /// Completes the scene side of the join and emits a stored failure exactly once when available.
    mutating func sceneBecameActive() -> Effect {
        guard case let .awaitingReturn(failure) = state else { return .none }

        guard let failure else {
            state = .awaitingFailureAfterReturn
            return .none
        }

        state = .delivered
        return .announce(failure)
    }

    /// Records an action failure and announces it once the app is active.
    ///
    /// `sceneIsActive` also covers biometric failures that occur before LocalAuthentication presents system UI and a
    /// return whose SwiftUI `scenePhase` change has not reached this reducer yet.
    mutating func receiveFailure(
        _ failure: SessionViewModel.ActionFailure,
        sceneIsActive: Bool
    ) -> Effect {
        switch state {
        case .idle:
            return .presentFailureNormally
        case .awaitingSceneDeparture:
            return deliverOrAwaitReturn(failure, sceneIsActive: sceneIsActive)
        case .awaitingFailureAfterReturn:
            return deliverOrAwaitReturn(failure, sceneIsActive: sceneIsActive)
        case .awaitingReturn:
            return deliverOrAwaitReturn(failure, sceneIsActive: sceneIsActive)
        case .delivered:
            return .none
        }
    }

    /// Discards presentation coordination after success, sign-out, state replacement, or VoiceOver deactivation.
    mutating func reset() {
        state = .idle
    }

    private mutating func deliverOrAwaitReturn(
        _ failure: SessionViewModel.ActionFailure,
        sceneIsActive: Bool
    ) -> Effect {
        guard sceneIsActive else {
            state = .awaitingReturn(failure)
            return .none
        }

        state = .delivered
        return .announce(failure)
    }
}
