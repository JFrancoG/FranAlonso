#if FRANALONSO_AUTH_FIXTURE
import SwiftUI

struct DevelopDemoBanner: View {
    let simulatesResponseLoss: Bool
    var includesHistoricalSamples = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(.demoTitle)
                .font(.headline)
            Text(.demoResetMessage)
                .font(.subheadline)
            if includesHistoricalSamples {
                Text("sales.history.demoSamples").font(.subheadline)
            }
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

#Preview("Historical samples", traits: .modifier(SalesHistoryPreviewModifier())) {
    DevelopDemoBanner(simulatesResponseLoss: false, includesHistoricalSamples: true)
}

#Preview("Historical login framing", traits: .modifier(SalesHistoryPreviewModifier())) {
    VStack(spacing: 0) {
        DevelopDemoBanner(simulatesResponseLoss: false, includesHistoricalSamples: true)
        NavigationStack {
            LoginScreen(
                viewModel: LoginViewModel(signIn: AuthenticationPreviewFixtures.standard.makeSignInUseCase()),
                onSignInSucceeded: { _ in }
            )
        }
    }
}

#Preview("Historical shell framing", traits: .modifier(SalesHistoryPreviewModifier())) {
    VStack(spacing: 0) {
        DevelopDemoBanner(simulatesResponseLoss: false, includesHistoricalSamples: true)
        AppShellScreen(requestSignOut: {})
    }
}
#endif
