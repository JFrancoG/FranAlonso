import SwiftUI

struct ClientDeactivationConfirmationView: View {
    let onConfirm: @MainActor () -> Void
    @State private var contentHeight: CGFloat = 320
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.dismiss) private var dismiss
    @AccessibilityFocusState(for: .voiceOver) private var isTitleFocused: Bool

    var body: some View {
        ViewThatFits(in: .vertical) {
            content
            ScrollView {
                content
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .presentationSizing(.form.fitted(horizontal: false, vertical: true))
        .presentationDetents(dynamicTypeSize.isAccessibilitySize ? [.large] : [.height(contentHeight)])
        .presentationDragIndicator(.visible)
        .background(.surface)
        .presentationBackground(.surface)
        .accessibilityAction(.escape) {
            dismiss()
        }
        .task {
            isTitleFocused = true
        }
    }

    private var content: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.clientsFormDeactivateTitle)
                .font(.title2.bold())
                .multilineTextAlignment(.center)
                .frame(maxWidth: .infinity)
                .accessibilityAddTraits(.isHeader)
                .accessibilityFocused($isTitleFocused)

            Text(.clientsFormDeactivateMessage)
                .font(.body)

            VStack(spacing: 12) {
                Button(role: .cancel) {
                    dismiss()
                } label: {
                    Text(.clientsFormCancel)
                        .font(.headline)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .contentShape(.rect(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.textSecondary, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)

                Button(role: .destructive) {
                    dismiss()
                    onConfirm()
                } label: {
                    Text(.clientsFormDeactivateConfirm)
                        .font(.headline)
                        .foregroundStyle(.errorInk)
                        .frame(maxWidth: .infinity, minHeight: 44)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .contentShape(.rect(cornerRadius: 12))
                        .overlay {
                            RoundedRectangle(cornerRadius: 12)
                                .strokeBorder(.errorInk, lineWidth: 1)
                        }
                }
                .buttonStyle(.plain)
            }
        }
        .foregroundStyle(.textPrimary)
        .fixedSize(horizontal: false, vertical: true)
        .padding(24)
        .onGeometryChange(for: CGFloat.self) { proxy in
            proxy.size.height.rounded(.up)
        } action: { height in
            if contentHeight != height {
                contentHeight = height
            }
        }
    }
}

#Preview("Confirmation", traits: .modifier(AppPreviewModifier())) {
    Color.surface
        .sheet(isPresented: .constant(true)) {
            ClientDeactivationConfirmationView {}
        }
}

#Preview("Confirmation AX 5", traits: .modifier(AppPreviewModifier())) {
    Color.surface
        .sheet(isPresented: .constant(true)) {
            ClientDeactivationConfirmationView {}
                .environment(\.dynamicTypeSize, .accessibility5)
        }
}
