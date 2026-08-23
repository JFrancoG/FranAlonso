import Accessibility
import Foundation
import SwiftUI

@MainActor
struct SessionContent: View {
    private enum FeedbackFocus: Hashable {
        case state
        case action
    }

    let state: SessionViewModel.State
    let actionState: SessionViewModel.ActionState
    let requestUnlock: () -> Void
    let requestSignOut: () -> Void

    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @Environment(\.locale) private var locale
    @Environment(\.scenePhase) private var scenePhase
    @State private var biometricAnnouncementGate = BiometricAnnouncementGate()
    @AccessibilityFocusState(for: .voiceOver) private var feedbackFocus: FeedbackFocus?

    var body: some View {
        Form {
            switch state {
            case .idle, .loading:
                Section {
                    ProgressView {
                        Text(.authenticationSessionChecking)
                    }
                }
            case .signedOut:
                Section {
                    ContentUnavailableView {
                        Label {
                            Text(.authenticationSessionSignedOutTitle)
                        } icon: {
                            Image(systemName: "person.crop.circle.badge.xmark")
                        }
                    } description: {
                        Text(.authenticationSessionSignedOutMessage)
                    }
                }
            case let .locked(_, availability):
                Section {
                    ContentUnavailableView {
                        Label {
                            Text(.authenticationSessionLockedTitle)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "lock.fill")
                        }
                    } description: {
                        Text(.authenticationSessionLockedMessage)
                            .lineLimit(nil)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }

                Section {
                    if availability == .unavailable {
                        Label {
                            Text(.authenticationSessionBiometricUnavailable)
                        } icon: {
                            Image(systemName: "exclamationmark.shield.fill")
                        }
                        .foregroundStyle(.warningInk)
                        .accessibilityFocused($feedbackFocus, equals: .state)
                    }

                    if availability == .available {
                        Button {
                            if voiceOverEnabled {
                                biometricAnnouncementGate.beginAttempt()
                            }
                            requestUnlock()
                        } label: {
                            Text(.authenticationSessionBiometricUnlockShort)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity)
                        }
                        .primaryActionStyle()
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(Text(.authenticationSessionBiometricUnlock))
                        .accessibilityInputLabels([
                            Text(.authenticationSessionBiometricUnlockShort),
                            Text(.authenticationSessionBiometricUnlock)
                        ])
                        .disabled(actionInFlight)
                    }

                    switch actionState {
                    case .idle:
                        EmptyView()
                    case .unlocking:
                        ProgressView {
                            Text(.authenticationSessionUnlocking)
                        }
                    case .signingOut:
                        ProgressView {
                            Text(.authenticationSessionSigningOut)
                        }
                    case let .failed(failure):
                        Label {
                            Text(failure.localizedMessage)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        .foregroundStyle(.errorInk)
                        .accessibilityFocused($feedbackFocus, equals: .action)
                    }

                    Button(role: .destructive) {
                        biometricAnnouncementGate.reset()
                        requestSignOut()
                    } label: {
                        ViewThatFits(in: .horizontal) {
                            Text(.authenticationSessionEmailFallback)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                            Text(.authenticationSessionEmailFallbackShort)
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundStyle(.errorInk)
                    }
                    .accessibilityLabel(Text(.authenticationSessionEmailFallback))
                    .accessibilityInputLabels([
                        Text(.authenticationSessionEmailFallback),
                        Text(.authenticationSessionEmailFallbackShort)
                    ])
                    .disabled(actionInFlight)
                }
            case .unlocked:
                Section {
                    ContentUnavailableView {
                        Label {
                            Text(.authenticationSessionUnlockedTitle)
                        } icon: {
                            Image(systemName: "lock.open.fill")
                        }
                    } description: {
                        Text(.authenticationSessionUnlockedMessage)
                    }
                }
            case let .failed(failure):
                Section {
                    VStack(alignment: .leading) {
                        Label {
                            Text(LocalizedStringResource.authenticationSessionObservationErrorTitle)
                                .font(.headline)
                        } icon: {
                            Image(systemName: "exclamationmark.triangle.fill")
                        }
                        Text(failure.localizedMessage)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityElement(children: .combine)
                    .accessibilityFocused($feedbackFocus, equals: .state)
                }
            }
        }
        .onAppear {
            updateAccessibilityFocus(state: state, actionState: actionState)
        }
        .onChange(of: state) { _, newState in
            if case .locked = newState {
                // Keep an attempted biometric return even if its fresh availability check failed.
                guard !biometricAnnouncementGate.isCoordinatingAttempt else { return }
            } else {
                biometricAnnouncementGate.reset()
            }
            updateAccessibilityFocus(state: newState, actionState: actionState)
        }
        .onChange(of: actionState) { _, newActionState in
            handleActionStateChange(newActionState)
        }
        .onChange(of: scenePhase) { oldPhase, newPhase in
            handleScenePhaseChange(from: oldPhase, to: newPhase)
        }
        .onChange(of: voiceOverEnabled) { _, isEnabled in
            if !isEnabled {
                biometricAnnouncementGate.reset()
            }
        }
    }

    private var actionInFlight: Bool {
        switch actionState {
        case .unlocking, .signingOut:
            true
        case .idle, .failed:
            false
        }
    }

    private func handleActionStateChange(_ newActionState: SessionViewModel.ActionState) {
        switch newActionState {
        case let .failed(failure):
            handleBiometricAnnouncementEffect(
                biometricAnnouncementGate.receiveFailure(
                    failure,
                    sceneIsActive: scenePhase == .active
                ),
                actionState: newActionState
            )
            return
        case .unlocking:
            return
        case .idle, .signingOut:
            biometricAnnouncementGate.reset()
        }

        updateAccessibilityFocus(state: state, actionState: newActionState)
    }

    private func handleScenePhaseChange(from oldPhase: ScenePhase, to newPhase: ScenePhase) {
        guard voiceOverEnabled else {
            biometricAnnouncementGate.reset()
            return
        }

        if oldPhase == .active, newPhase != .active {
            biometricAnnouncementGate.sceneBecameInactive()
            return
        }

        guard newPhase == .active else { return }
        handleBiometricAnnouncementEffect(biometricAnnouncementGate.sceneBecameActive(), actionState: actionState)
    }

    private func handleBiometricAnnouncementEffect(
        _ effect: BiometricAnnouncementGate.Effect,
        actionState: SessionViewModel.ActionState
    ) {
        switch effect {
        case .none:
            break
        case let .announce(failure):
            announceBiometricFailure(failure)
        case .presentFailureNormally:
            updateAccessibilityFocus(state: state, actionState: actionState)
        }
    }

    private func updateAccessibilityFocus(state: SessionViewModel.State, actionState: SessionViewModel.ActionState) {
        if case .failed = actionState {
            feedbackFocus = .action
            return
        }

        switch state {
        case .locked(_, .unavailable), .failed:
            feedbackFocus = .state
        case .idle, .loading, .signedOut, .locked(_, .available), .unlocked:
            feedbackFocus = nil
        }
    }

    private func announceBiometricFailure(_ failure: SessionViewModel.ActionFailure) {
        guard voiceOverEnabled else { return }

        var resource = failure.localizedMessage
        resource.locale = locale
        var announcement = AttributedString(String(localized: resource))
        announcement.accessibilitySpeechAnnouncementPriority = .high
        AccessibilityNotification.Announcement(announcement).post()
    }
}

extension SessionViewModel.Failure {
    /// A localized explanation for an observation that ended without an authoritative replacement.
    var localizedMessage: LocalizedStringResource {
        switch self {
        case .observationEnded:
            .authenticationSessionErrorObservationEnded
        }
    }
}

extension SessionViewModel.ActionFailure {
    /// A localized explanation that does not expose provider or LocalAuthentication errors.
    var localizedMessage: LocalizedStringResource {
        switch self {
        case .biometricDenied:
            .authenticationSessionErrorBiometricDenied
        case .biometricCancelled:
            .authenticationSessionErrorBiometricCancelled
        case .biometricUnavailable:
            .authenticationSessionErrorBiometricUnavailable
        case .temporarilyUnavailable:
            .authenticationSessionErrorTemporarilyUnavailable
        case .configuration:
            .authenticationSessionErrorConfiguration
        case .secureStorageUnavailable:
            .authenticationSessionErrorSecureStorage
        case .unexpected:
            .authenticationSessionErrorUnexpected
        }
    }
}

#Preview("Idle", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .idle,
        actionState: .idle
    ) {} requestSignOut: {}
}

#Preview("Loading", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .loading,
        actionState: .idle
    ) {} requestSignOut: {}
}

#Preview("Signed out", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .signedOut,
        actionState: .idle
    ) {} requestSignOut: {}
}

#Preview("Locked with biometrics", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .idle
    ) {} requestSignOut: {}
}

#Preview("Locked with biometrics RTL", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .idle
    ) {} requestSignOut: {}
        .environment(\.layoutDirection, .rightToLeft)
}

#Preview("Locked without biometrics", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .unavailable),
        actionState: .idle
    ) {} requestSignOut: {}
}

#Preview("Unlocking", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .unlocking
    ) {} requestSignOut: {}
}

#Preview("Signing out", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .signingOut
    ) {} requestSignOut: {}
}

#Preview("Biometric denied", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .failed(.biometricDenied)
    ) {} requestSignOut: {}
}

#Preview("Biometric cancelled", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .failed(.biometricCancelled)
    ) {} requestSignOut: {}
}

#Preview("Biometric unavailable", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .unavailable),
        actionState: .failed(.biometricUnavailable)
    ) {} requestSignOut: {}
}

#Preview("Session temporarily unavailable", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .failed(.temporarilyUnavailable)
    ) {} requestSignOut: {}
}

#Preview("Session configuration error", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .failed(.configuration)
    ) {} requestSignOut: {}
}

#Preview("Session secure storage unavailable", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .failed(.secureStorageUnavailable)
    ) {} requestSignOut: {}
}

#Preview("Unexpected session action error", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .locked(AuthenticationPreviewFixtures.standard.session, .available),
        actionState: .failed(.unexpected)
    ) {} requestSignOut: {}
}

#Preview("Unlocked", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .unlocked(AuthenticationPreviewFixtures.standard.session),
        actionState: .idle
    ) {} requestSignOut: {}
}

#Preview("Observation failed", traits: .modifier(AppPreviewModifier())) {
    SessionContent(
        state: .failed(.observationEnded),
        actionState: .idle
    ) {} requestSignOut: {}
}
