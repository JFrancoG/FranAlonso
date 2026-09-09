import SwiftUI

struct ClientRow: View {
    let client: Client
    let onSelect: @MainActor () -> Void

    var body: some View {
        Button(action: onSelect) {
            Text(client.displayName)
                .foregroundStyle(.textPrimary)
                .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .accessibilityHint(Text(.clientsListEditHint))
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    ClientRow(client: AppPreviewFixtures.standard.primaryClient) {}
        .padding()
}

#Preview("Long name", traits: .modifier(AppPreviewModifier())) {
    ClientRow(client: AppPreviewFixtures.clientListLongName) {}
        .padding()
}
