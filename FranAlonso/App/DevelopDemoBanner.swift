#if FRANALONSO_AUTH_FIXTURE
import SwiftUI

struct DevelopDemoBanner: View {
    let simulatesResponseLoss: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(.demoTitle)
                .font(.headline)
            Text(.demoResetMessage)
                .font(.subheadline)
            if simulatesResponseLoss {
                Text(.demoResponseLostMessage)
                    .font(.subheadline)
            }
        }
        .foregroundStyle(.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.surface)
        .accessibilityElement(children: .combine)
    }
}

#Preview("Demo", traits: .modifier(AppPreviewModifier())) {
    DevelopDemoBanner(simulatesResponseLoss: false)
}

#Preview("Response lost", traits: .modifier(AppPreviewModifier())) {
    DevelopDemoBanner(simulatesResponseLoss: true)
}

#Preview("Login framing", traits: .modifier(AppPreviewModifier())) {
    VStack(spacing: 0) {
        DevelopDemoBanner(simulatesResponseLoss: true)
        NavigationStack {
            LoginScreen(
                viewModel: LoginViewModel(signIn: AuthenticationPreviewFixtures.standard.makeSignInUseCase()),
                onSignInSucceeded: { _ in }
            )
        }
    }
}

#Preview("Shell framing", traits: .modifier(AppPreviewModifier())) {
    VStack(spacing: 0) {
        DevelopDemoBanner(simulatesResponseLoss: false)
        AppShellScreen(requestSignOut: {})
    }
}
#endif
