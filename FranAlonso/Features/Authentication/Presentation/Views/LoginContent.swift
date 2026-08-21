import Foundation
import SwiftUI

@MainActor
struct LoginContent: View {
    private enum Field: Hashable {
        case email
        case password
    }

    @Binding var email: String
    @Binding var password: String
    let state: LoginViewModel.State
    let requestSignIn: () -> Void

    @FocusState private var focusedField: Field?
    @AccessibilityFocusState private var errorFocused: Bool

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading) {
                    Text(.authenticationLoginEmailLabel)
                        .font(.headline)
                        .accessibilityHidden(true)
                    TextField(
                        .authenticationLoginEmailLabel,
                        text: $email,
                        prompt: Text(.authenticationLoginEmailPrompt)
                            .foregroundStyle(.textSecondary)
                    )
                    .keyboardType(.emailAddress)
                    .textContentType(.username)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .accessibilityInputLabels([Text(.authenticationLoginEmailLabel)])
                    .frame(minHeight: 44)
                    .contentShape(.interaction, Rectangle())
                    .gesture(TapGesture().onEnded { focusedField = .email }, isEnabled: !interactionDisabled)
                    .submitLabel(.next)
                    .focused($focusedField, equals: .email)
                    .onSubmit {
                        focusedField = .password
                    }
                }
            }
            .disabled(interactionDisabled)

            Section {
                VStack(alignment: .leading) {
                    Text(.authenticationLoginPasswordLabel)
                        .font(.headline)
                        .accessibilityHidden(true)
                    SecureField(
                        .authenticationLoginPasswordLabel,
                        text: $password,
                        prompt: Text(.authenticationLoginPasswordPrompt)
                            .foregroundStyle(.textSecondary)
                    )
                    .textContentType(.password)
                    .accessibilityInputLabels([Text(.authenticationLoginPasswordLabel)])
                    .frame(minHeight: 44)
                    .contentShape(.interaction, Rectangle())
                    .gesture(TapGesture().onEnded { focusedField = .password }, isEnabled: !interactionDisabled)
                    .submitLabel(.done)
                    .focused($focusedField, equals: .password)
                    .onSubmit {
                        focusedField = nil
                        requestSignIn()
                    }
                }
            }
            .disabled(interactionDisabled)

            Section {
                Button {
                    focusedField = nil
                    requestSignIn()
                } label: {
                    Label {
                        Text(.authenticationLoginSubmit)
                    } icon: {
                        Image(systemName: "arrow.right.circle.fill")
                    }
                    .foregroundStyle(.onBrandPrimary)
                }
                .buttonStyle(.borderedProminent)
                .tint(.brandPrimary)
                .disabled(interactionDisabled)
            }

            Section {
                switch state {
                case .idle:
                    EmptyView()
                case .loading:
                    ProgressView {
                        Text(.authenticationLoginSigningIn)
                    }
                case .succeeded:
                    Label {
                        Text(.authenticationLoginSucceeded)
                    } icon: {
                        Image(systemName: "checkmark.circle.fill")
                    }
                    .foregroundStyle(.green)
                case let .failed(failure):
                    Label {
                        Text(failure.localizedMessage)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(.red)
                    .accessibilityFocused($errorFocused)
                }
            }
        }
        .onAppear {
            updateAccessibilityFocus(for: state)
        }
        .onChange(of: state) { _, newState in
            updateAccessibilityFocus(for: newState)
        }
    }

    private var interactionDisabled: Bool {
        switch state {
        case .loading, .succeeded:
            true
        case .idle, .failed:
            false
        }
    }

    private func updateAccessibilityFocus(for state: LoginViewModel.State) {
        switch state {
        case .failed:
            errorFocused = true
        case .idle, .loading, .succeeded:
            errorFocused = false
        }
    }
}

extension LoginViewModel.Failure {
    /// A localized explanation that preserves the provider-neutral presentation contract.
    var localizedMessage: LocalizedStringResource {
        switch self {
        case .credentialsRejected:
            .authenticationLoginErrorCredentialsRejected
        case .temporarilyUnavailable:
            .authenticationLoginErrorTemporarilyUnavailable
        case .configuration:
            .authenticationLoginErrorConfiguration
        case .secureStorageUnavailable:
            .authenticationLoginErrorSecureStorage
        case .unexpected:
            .authenticationLoginErrorUnexpected
        }
    }
}

#Preview("Idle", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    LoginContent(
        email: $email,
        password: $password,
        state: .idle
    ) {}
}

#Preview("Loading", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"
    @Previewable @State var password = "ephemeral"

    LoginContent(
        email: $email,
        password: $password,
        state: .loading
    ) {}
}

#Preview("Succeeded", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"
    @Previewable @State var password = ""

    LoginContent(
        email: $email,
        password: $password,
        state: .succeeded(AuthenticationPreviewFixtures.standard.session)
    ) {}
}

#Preview("Credentials rejected", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"
    @Previewable @State var password = "ephemeral"

    LoginContent(
        email: $email,
        password: $password,
        state: .failed(.credentialsRejected)
    ) {}
}

#Preview("Temporarily unavailable", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"
    @Previewable @State var password = "ephemeral"

    LoginContent(
        email: $email,
        password: $password,
        state: .failed(.temporarilyUnavailable)
    ) {}
}

#Preview("Configuration error", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"
    @Previewable @State var password = "ephemeral"

    LoginContent(
        email: $email,
        password: $password,
        state: .failed(.configuration)
    ) {}
}

#Preview("Secure storage unavailable", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"
    @Previewable @State var password = "ephemeral"

    LoginContent(
        email: $email,
        password: $password,
        state: .failed(.secureStorageUnavailable)
    ) {}
}

#Preview("Unexpected error", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"
    @Previewable @State var password = "ephemeral"

    LoginContent(
        email: $email,
        password: $password,
        state: .failed(.unexpected)
    ) {}
}
