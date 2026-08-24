import SwiftUI

struct UnavailableStateView<Actions: View>: View {
    let title: LocalizedStringResource
    let systemImage: String
    let message: LocalizedStringResource
    let actions: Actions

    var body: some View {
        ScrollView {
            ContentUnavailableView {
                Label {
                    Text(title)
                } icon: {
                    Image(systemName: systemImage)
                }
            } description: {
                Text(message)
                    .foregroundStyle(.textSecondary)
            } actions: {
                actions
            }
        }
        .defaultScrollAnchor(.center, for: .alignment)
        .scrollBounceBehavior(.basedOnSize)
    }
}

extension UnavailableStateView {
    init(
        title: LocalizedStringResource,
        systemImage: String,
        message: LocalizedStringResource,
        @ViewBuilder actions: () -> Actions
    ) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        self.actions = actions()
    }
}

extension UnavailableStateView where Actions == EmptyView {
    init(title: LocalizedStringResource, systemImage: String, message: LocalizedStringResource) {
        self.title = title
        self.systemImage = systemImage
        self.message = message
        actions = EmptyView()
    }
}

#Preview("Without actions", traits: .modifier(AppPreviewModifier())) {
    UnavailableStateView(
        title: .clientsListEmptyTitle,
        systemImage: "person.2",
        message: .clientsListEmptyMessage
    )
}

#Preview("With action", traits: .modifier(AppPreviewModifier())) {
    UnavailableStateView(
        title: .authenticationRootObservationFailedTitle,
        systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
        message: .authenticationRootObservationFailedMessage
    ) {
        Button {} label: {
            Text(.authenticationRootRetry)
        }
    }
}

#Preview("RTL", traits: .modifier(AppPreviewModifier())) {
    UnavailableStateView(
        title: .authenticationRootObservationFailedTitle,
        systemImage: "exclamationmark.arrow.trianglehead.2.clockwise.rotate.90",
        message: .authenticationRootObservationFailedMessage
    ) {
        Button {} label: {
            Text(.authenticationRootRetry)
        }
    }
    .environment(\.layoutDirection, .rightToLeft)
}
