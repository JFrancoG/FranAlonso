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

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @AccessibilityFocusState private var feedbackFocus: FeedbackFocus?

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
                        .foregroundStyle(.orange)
                        .accessibilityFocused($feedbackFocus, equals: .state)
                    }

                    if availability == .available {
                        Button {
                            requestUnlock()
                        } label: {
                            if dynamicTypeSize.isAccessibilitySize {
                                VStack(spacing: 8) {
                                    Image(systemName: "lock.open.fill")
                                        .accessibilityHidden(true)
                                    Text(.authenticationSessionBiometricUnlock)
                                        .multilineTextAlignment(.center)
                                        .lineLimit(nil)
                                        .fixedSize(horizontal: false, vertical: true)
                                }
                                .frame(maxWidth: .infinity)
                            } else {
                                HStack(spacing: 8) {
                                    Image(systemName: "lock.open.fill")
                                        .accessibilityHidden(true)
                                    Text(.authenticationSessionBiometricUnlock)
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .frame(maxWidth: .infinity)
                        .accessibilityLabel(Text(.authenticationSessionBiometricUnlock))
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
                        .foregroundStyle(.red)
                        .accessibilityFocused($feedbackFocus, equals: .action)
                    }

                    Button(role: .destructive) {
                        requestSignOut()
                    } label: {
                        Label {
                            Text(.authenticationSessionEmailFallback)
                                .lineLimit(nil)
                                .fixedSize(horizontal: false, vertical: true)
                        } icon: {
                            Image(systemName: "envelope.fill")
                        }
                    }
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
            updateAccessibilityFocus(state: newState, actionState: actionState)
        }
        .onChange(of: actionState) { _, newActionState in
            updateAccessibilityFocus(state: state, actionState: newActionState)
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
