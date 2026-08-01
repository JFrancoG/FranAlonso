import Foundation
import SwiftUI

@MainActor
struct LoginScreen: View {
    @State private var viewModel: LoginViewModel
    @State private var signInRequestID: UUID?

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
        .task(id: signInRequestID) {
            guard let requestID = signInRequestID else {
                return
            }

            await viewModel.signIn()

            guard signInRequestID == requestID else {
                return
            }

            signInRequestID = nil
        }
    }
}

extension LoginScreen {
    init(signIn: SignInUseCase) {
        _viewModel = State(initialValue: LoginViewModel(signIn: signIn))
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    NavigationStack {
        LoginScreen(
            signIn: AuthenticationPreviewFixtures.standard.makeSignInUseCase()
        )
    }
}
