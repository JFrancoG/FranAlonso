import SwiftUI

/// Presents exactly one public or protected application root from authoritative authentication state.
@MainActor
struct AuthenticationRootScreen: View {
    let viewModel: AuthenticationRootViewModel
    @State private var signOutRequestID: Int?

    var body: some View {
        NavigationStack {
            switch viewModel.state {
            case .checkingSession:
                ProgressView {
                    Text(.authenticationRootCheckingSession)
                }
            case .signedOut:
                LoginScreen(
                    viewModel: viewModel.loginViewModel,
                    onSignInSucceeded: viewModel.registerRecentSignIn
                )
            case .locked:
                SessionScreen(viewModel: viewModel.sessionViewModel)
            case .authorizingLocalAccess:
                ProgressView {
                    Text(.authenticationRootAuthorizingLocalAccess)
                }
            case let .authenticated(session):
                ContentView(requestSignOut: requestSignOut)
                    .id(session.id)
            case let .localAccessDenied(failure):
                ContentUnavailableView {
                    Label {
                        Text(.authenticationRootAccessDeniedTitle)
                    } icon: {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                    }
                } description: {
                    Text(failure.localizedMessage)
                } actions: {
                    Button(role: .destructive) {
                        requestSignOut()
                    } label: {
                        Label {
                            Text(.authenticationRootSignOut)
                        } icon: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                        }
                    }
                }
            case .signingOut:
                ProgressView {
                    Text(.authenticationRootSigningOut)
                }
            case .observationFailed:
                ContentUnavailableView {
                    Label {
                        Text(.authenticationRootObservationFailedTitle)
                    } icon: {
                        Image(systemName: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90")
                    }
                } description: {
                    Text(.authenticationRootObservationFailedMessage)
                } actions: {
                    Button {
                        viewModel.retryObservation()
                    } label: {
                        Label {
                            Text(.authenticationRootRetry)
                        } icon: {
                            Image(systemName: "arrow.clockwise")
                        }
                    }
                }
            }
        }
        .task(id: viewModel.observationRequestID) {
            await viewModel.sessionViewModel.load()
        }
        .onChange(of: viewModel.sessionViewModel.sessionEventRevision, initial: true) { _, _ in
            viewModel.sessionEventDidChange()
        }
        .task(id: viewModel.accessTrigger) {
            await viewModel.authorizeLocalAccessIfNeeded()
        }
        .task(id: signOutRequestID) {
            guard let requestID = signOutRequestID else {
                return
            }

            await viewModel.signOut()

            guard signOutRequestID == requestID else {
                return
            }
            signOutRequestID = nil
        }
    }

    private func requestSignOut() {
        signOutRequestID = (signOutRequestID ?? 0) + 1
    }
}

extension AuthenticationRootViewModel.Failure {
    /// A localized, provider-neutral reason why local access failed closed.
    var localizedMessage: LocalizedStringResource {
        switch self {
        case .differentPrincipal:
            .authenticationRootErrorDifferentPrincipal
        case .localStoreNotPristine:
            .authenticationRootErrorLocalStoreNotPristine
        case .secureStorageUnavailable:
            .authenticationRootErrorSecureStorage
        case .localStoreUnavailable:
            .authenticationRootErrorLocalStoreUnavailable
        case .unexpected:
            .authenticationRootErrorUnexpected
        }
    }
}

#Preview("Signed out", traits: .modifier(AppPreviewModifier())) {
    AuthenticationRootScreen(
        viewModel: AuthenticationPreviewFixtures.standard.makeSignedOutRootViewModel()
    )
}

#Preview("Local access denied", traits: .modifier(AppPreviewModifier())) {
    AuthenticationRootScreen(
        viewModel: AuthenticationPreviewFixtures.standard.makeLocalAccessDeniedRootViewModel()
    )
}

#Preview("Observation failed", traits: .modifier(AppPreviewModifier())) {
    AuthenticationRootScreen(
        viewModel: AuthenticationPreviewFixtures.standard.makeObservationFailedRootViewModel()
    )
}

#Preview("Authenticated", traits: .modifier(AppPreviewModifier())) {
    AuthenticationRootScreen(
        viewModel: AuthenticationPreviewFixtures.standard.makeAuthenticatedRootViewModel()
    )
}
