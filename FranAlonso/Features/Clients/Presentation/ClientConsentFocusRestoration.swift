/// Consumes one native focus event per presentation, leaving later reader navigation untouched.
struct ClientConsentFocusRestoration {
    private var pendingTarget: ClientConsentScreen.FocusTarget?

    /// Replaces a previous intention; disabled VoiceOver never leaves a deferred correction.
    mutating func prepare(_ target: ClientConsentScreen.FocusTarget, voiceOverEnabled: Bool) {
        pendingTarget = voiceOverEnabled ? target : nil
    }

    /// Unknown elements consume the intention too, so a later visit to Back cannot steal focus.
    mutating func consume(returnControlFocused: Bool) -> ClientConsentScreen.FocusTarget? {
        let target = pendingTarget
        pendingTarget = nil
        return returnControlFocused ? target : nil
    }

    mutating func cancel() {
        pendingTarget = nil
    }
}
