import Foundation
import SwiftUI

@MainActor
struct SessionScreen: View {
    private enum ActionRequest: Equatable {
        case unlock(UUID)
        case signOut(UUID)
    }

    @Environment(\.locale) private var locale
    let viewModel: SessionViewModel
    @State private var actionRequest: ActionRequest?

    var body: some View {
        SessionContent(
            state: viewModel.state,
            actionState: viewModel.actionState
        ) {
            actionRequest = .unlock(UUID())
        } requestSignOut: {
            actionRequest = .signOut(UUID())
        }
        .navigationTitle(Text(.authenticationSessionTitle))
        .task(id: actionRequest) {
            guard let request = actionRequest else {
                return
            }

            switch request {
            case .unlock:
                await viewModel.unlock(localizedReason: biometricReason)
            case .signOut:
                await viewModel.signOut()
            }

            guard actionRequest == request else {
                return
            }

            actionRequest = nil
        }
    }

    private var biometricReason: String {
        var resource = LocalizedStringResource.authenticationSessionBiometricReason
        resource.locale = locale
        return String(localized: resource)
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    let viewModel = AuthenticationPreviewFixtures.standard.makeSessionViewModel()

    NavigationStack {
        SessionScreen(viewModel: viewModel)
    }
}
