import SwiftUI

struct LoadingStateView: View {
    let label: LocalizedStringResource

    var body: some View {
        ProgressView {
            Text(label)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    LoadingStateView(label: .clientsListLoading)
}

#Preview("RTL", traits: .modifier(AppPreviewModifier())) {
    LoadingStateView(label: .clientsListLoading)
        .environment(\.layoutDirection, .rightToLeft)
}
