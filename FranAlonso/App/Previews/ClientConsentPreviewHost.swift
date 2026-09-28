import SwiftUI

/// Resolves an isolated asynchronous fixture before rendering the exact product view under inspection.
struct ClientConsentPreviewHost<Content: View>: View {
    let scenario: ClientConsentPreviewFixtures.Scenario
    @ViewBuilder let content: @MainActor (ClientFormViewModel) -> Content
    @Environment(\.consentPreviewModels) private var models

    var body: some View {
        Group {
            if let viewModel = models[scenario] {
                content(viewModel)
            } else {
                Text(.clientsConsentPreviewError)
            }
        }
    }
}

/// Finishes asynchronous seeding before Xcode snapshots any participating document preview.
struct ClientConsentPreviewModifier: PreviewModifier {
    static func makeSharedContext() async throws -> [ClientConsentPreviewFixtures.Scenario: ClientFormViewModel] {
        var models: [ClientConsentPreviewFixtures.Scenario: ClientFormViewModel] = [:]
        for scenario in ClientConsentPreviewFixtures.Scenario.allCases {
            models[scenario] = try await ClientConsentPreviewFixtures.make(scenario)
        }
        return models
    }

    func body(content: Content, context: [ClientConsentPreviewFixtures.Scenario: ClientFormViewModel]) -> some View {
        content.environment(\.consentPreviewModels, context)
    }
}

private extension EnvironmentValues {
    @Entry var consentPreviewModels: [ClientConsentPreviewFixtures.Scenario: ClientFormViewModel] = [:]
}

#Preview("Native information", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .information) {
        ClientConsentScreen(viewModel: $0)
    }
}
