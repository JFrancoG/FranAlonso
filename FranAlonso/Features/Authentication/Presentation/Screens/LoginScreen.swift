import Accessibility
import Foundation
import SwiftUI

@MainActor
struct LoginScreen: View {
    let viewModel: LoginViewModel
    let onSignInSucceeded: @MainActor (AuthenticationSession) -> Void
    @State private var signInRequestID: UUID?
    @State private var hasPostedScreenChange = false

    var body: some View {
        @Bindable var viewModel = viewModel

        LoginContent(
            email: $viewModel.email,
            password: $viewModel.password,
            state: viewModel.state
        ) {
            signInRequestID = UUID()
        }
        .navigationTitle(Text(.authenticationLoginTitle))
        .onAppear {
            guard !hasPostedScreenChange else { return }
            hasPostedScreenChange = true
            AccessibilityNotification.ScreenChanged().post()
        }
        .task(id: signInRequestID) {
            guard let requestID = signInRequestID else { return }

            await viewModel.signIn()

            guard signInRequestID == requestID else { return }

            if case let .succeeded(session) = viewModel.state {
                onSignInSucceeded(session)
            }

            signInRequestID = nil
        }
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    NavigationStack {
        LoginScreen(
            viewModel: LoginViewModel(
                signIn: AuthenticationPreviewFixtures.standard.makeSignInUseCase()
            ),
            onSignInSucceeded: { _ in }
        )
    }
}
