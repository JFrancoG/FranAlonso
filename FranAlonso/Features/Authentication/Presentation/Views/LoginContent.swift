import Foundation
import SwiftUI

@MainActor
struct LoginContent: View {
    private enum Field: Hashable {
        case email
        case passwordHidden
        case passwordVisible
    }

    @Binding var email: String
    @Binding var password: String
    let state: LoginViewModel.State
    let requestSignIn: () -> Void

    @State private var isPasswordVisible = false
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.locale) private var locale
    @FocusState private var focusedField: Field?
    @AccessibilityFocusState private var errorFocused: Bool

    var body: some View {
        Form {
            FormFieldSection(
                .authenticationLoginEmailLabel,
                systemImage: "envelope"
            ) {
                TextField(
                    .authenticationLoginEmailLabel,
                    text: $email,
                    prompt: Text(localizedEmailPrompt)
                        .foregroundStyle(.textSecondary)
                )
                .keyboardType(.emailAddress)
                .textContentType(.username)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .accessibilityInputLabels([Text(.authenticationLoginEmailLabel)])
                .accessibilityLabel(Text(.authenticationLoginEmailLabel))
                .frame(minHeight: 44)
                .contentShape(.interaction, Rectangle())
                .gesture(TapGesture().onEnded { focusedField = .email }, isEnabled: !interactionDisabled)
                .submitLabel(.next)
                .focused($focusedField, equals: .email)
                .onSubmit {
                    focusedField = activePasswordField
                }
            }
            .disabled(interactionDisabled)

            FormFieldSection(
                .authenticationLoginPasswordLabel,
                systemImage: "lock"
            ) {
                if dynamicTypeSize.isAccessibilitySize {
                    VStack(alignment: .trailing, spacing: 8) {
                        passwordEntry
                        passwordVisibilityButton
                    }
                    .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    HStack(spacing: 8) {
                        passwordEntry
                        passwordVisibilityButton
                    }
                }
            }
            .disabled(interactionDisabled)

            Section {
                Button {
                    focusedField = nil
                    requestSignIn()
                } label: {
                    Text(.authenticationLoginSubmit)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity)
                }
                .primaryActionStyle()
                .disabled(interactionDisabled)
                .listRowBackground(Color.clear)
                .listRowInsets(
                    EdgeInsets(
                        top: 32,
                        leading: 16,
                        bottom: 8,
                        trailing: 16
                    )
                )
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
                    .foregroundStyle(.successInk)
                case let .failed(failure):
                    Label {
                        Text(failure.localizedMessage)
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                    }
                    .foregroundStyle(.errorInk)
                    .accessibilityFocused($errorFocused)
                }
            }
        }
        .scrollContentBackground(.hidden)
        .background(.canvas)
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

    private var localizedEmailPrompt: String {
        var resource = LocalizedStringResource.authenticationLoginEmailPrompt
        resource.locale = locale
        return String(localized: resource)
    }

    private var passwordVisibilityLabel: LocalizedStringResource {
        isPasswordVisible
            ? .authenticationLoginPasswordHide
            : .authenticationLoginPasswordShow
    }

    private var activePasswordField: Field {
        isPasswordVisible ? .passwordVisible : .passwordHidden
    }

    private var passwordFieldIsFocused: Bool {
        focusedField == .passwordHidden || focusedField == .passwordVisible
    }

    private var passwordEntry: some View {
        Group {
            if isPasswordVisible {
                passwordField(
                    TextField(
                        .authenticationLoginPasswordLabel,
                        text: $password,
                        prompt: Text(.authenticationLoginPasswordPrompt)
                            .foregroundStyle(.textSecondary)
                    )
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled(),
                    focusedAs: .passwordVisible
                )
            } else {
                passwordField(
                    SecureField(
                        .authenticationLoginPasswordLabel,
                        text: $password,
                        prompt: Text(.authenticationLoginPasswordPrompt)
                            .foregroundStyle(.textSecondary)
                    ),
                    focusedAs: .passwordHidden
                )
            }
        }
        .layoutPriority(1)
    }

    private func passwordField<Content: View>(_ content: Content, focusedAs field: Field) -> some View {
        content
            .textContentType(.password)
            .accessibilityInputLabels([Text(.authenticationLoginPasswordLabel)])
            .accessibilityLabel(Text(.authenticationLoginPasswordLabel))
            .frame(minHeight: 44)
            .contentShape(.interaction, Rectangle())
            .gesture(TapGesture().onEnded { focusedField = field }, isEnabled: !interactionDisabled)
            .submitLabel(.done)
            .focused($focusedField, equals: field)
            .onSubmit {
                focusedField = nil
                requestSignIn()
            }
    }

    private var passwordVisibilityButton: some View {
        Button {
            togglePasswordVisibility()
        } label: {
            Label {
                Text(passwordVisibilityLabel)
            } icon: {
                Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
            }
            .labelStyle(.iconOnly)
            .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
        }
        .buttonStyle(.plain)
        .foregroundStyle(.brandPrimaryInk)
        .frame(minWidth: 44, minHeight: 44)
        .contentShape(.interaction, Rectangle())
    }

    private func togglePasswordVisibility() {
        let shouldPreserveFocus = passwordFieldIsFocused
        isPasswordVisible.toggle()
        guard shouldPreserveFocus else { return }
        focusedField = activePasswordField
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

#Preview("Idle RTL", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = ""
    @Previewable @State var password = ""

    LoginContent(
        email: $email,
        password: $password,
        state: .idle
    ) {}
    .environment(\.layoutDirection, .rightToLeft)
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
