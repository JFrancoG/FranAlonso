import SwiftUI

@MainActor
struct ClientRow: View {
    let client: Client

    var body: some View {
        Text(client.displayName)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    ClientRow(client: AppPreviewFixtures.standard.primaryClient)
        .padding()
}
