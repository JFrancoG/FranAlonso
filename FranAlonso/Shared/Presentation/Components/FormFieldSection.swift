import SwiftUI

struct FormFieldSection<Content: View>: View {
    let label: LocalizedStringResource
    let systemImage: String
    let content: Content

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        Section {
            VStack(alignment: .leading) {
                fieldLabel
                    .font(.headline)
                    .accessibilityHidden(true)
                content
            }
        }
    }

    @ViewBuilder
    private var fieldLabel: some View {
        if dynamicTypeSize.isAccessibilitySize {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: systemImage)
                    .foregroundStyle(.textSecondary)
                Text(label)
            }
        } else {
            Label {
                Text(label)
            } icon: {
                Image(systemName: systemImage)
                    .foregroundStyle(.textSecondary)
            }
        }
    }
}

extension FormFieldSection {
    init(
        _ label: LocalizedStringResource,
        systemImage: String,
        @ViewBuilder content: () -> Content
    ) {
        self.label = label
        self.systemImage = systemImage
        self.content = content()
    }
}

#Preview(traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"

    Form {
        FormFieldSection(
            .authenticationLoginEmailLabel,
            systemImage: "envelope"
        ) {
            TextField(.authenticationLoginEmailLabel, text: $email)
                .textContentType(.username)
        }
    }
}

#Preview("RTL", traits: .modifier(AppPreviewModifier())) {
    @Previewable @State var email = "fran@example.com"

    Form {
        FormFieldSection(
            .authenticationLoginEmailLabel,
            systemImage: "envelope"
        ) {
            TextField(.authenticationLoginEmailLabel, text: $email)
                .textContentType(.username)
        }
    }
    .environment(\.layoutDirection, .rightToLeft)
}
