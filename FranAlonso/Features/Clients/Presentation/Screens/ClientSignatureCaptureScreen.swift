import Accessibility
import SwiftUI

struct ClientSignatureCaptureScreen: View {
    @State private var viewModel: ClientSignatureCaptureViewModel
    @State private var hasPostedScreenChange = false
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    private var status: LocalizedStringResource {
        if !viewModel.currentStroke.isEmpty {
            .clientsSignatureStatusDrawing
        } else if viewModel.strokes.isEmpty {
            .clientsSignatureStatusEmpty
        } else {
            .clientsSignatureStatusReady
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    if dynamicTypeSize.isAccessibilitySize {
                        Text(.clientsSignatureTitle)
                            .font(.title.bold())
                            .fixedSize(horizontal: false, vertical: true)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text(.clientsSignatureInstructions)
                        .foregroundStyle(.textSecondary)
                    ClientSignatureCanvas(
                        strokes: viewModel.strokes,
                        currentStroke: viewModel.currentStroke,
                        status: status,
                        onUpdateStroke: viewModel.updateStroke,
                        onEndStroke: endStroke,
                        onCancelStroke: viewModel.cancelCurrentStroke
                    )
                    HStack(spacing: 16) {
                        Spacer()
                        Button(action: undo) {
                            Label {
                                Text(.clientsSignatureUndo)
                            } icon: {
                                Image(systemName: "arrow.uturn.backward")
                            }
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 44, minHeight: 44)
                            .foregroundStyle(.brandPrimaryInk)
                            .background(.surface, in: .capsule)
                            .overlay {
                                Capsule().strokeBorder(.brandPrimaryInk, lineWidth: 1)
                            }
                            .contentShape(.rect)
                        }
                        .accessibilityLabel(.clientsSignatureUndo)
                        .accessibilityShowsLargeContentViewer {
                            Label {
                                Text(.clientsSignatureUndo)
                            } icon: {
                                Image(systemName: "arrow.uturn.backward")
                            }
                        }
                        .disabled(!viewModel.canUndo)
                        Button(role: .destructive, action: clear) {
                            Label {
                                Text(.clientsSignatureClear)
                            } icon: {
                                Image(systemName: "trash")
                            }
                            .labelStyle(.iconOnly)
                            .frame(minWidth: 44, minHeight: 44)
                            .foregroundStyle(.errorInk)
                            .background(.surface, in: .capsule)
                            .overlay {
                                Capsule().strokeBorder(.errorInk, lineWidth: 1)
                            }
                            .contentShape(.rect)
                        }
                        .accessibilityLabel(.clientsSignatureClear)
                        .accessibilityShowsLargeContentViewer {
                            Label {
                                Text(.clientsSignatureClear)
                            } icon: {
                                Image(systemName: "trash")
                            }
                        }
                        .disabled(!viewModel.canClear)
                    }
                    .buttonStyle(.plain)
                    Text(status)
                        .accessibilityHidden(true)
                    if let error = viewModel.validationError {
                        Text(error.signatureMessage)
                            .foregroundStyle(.errorInk)
                    }
                    Button(action: confirm) {
                        Text(.clientsSignatureConfirm)
                            .frame(maxWidth: .infinity)
                    }
                    .primaryActionStyle()
                    .contentShape(.accessibility, .rect)
                    .disabled(!viewModel.canConfirm)
                }
                .padding()
                .frame(maxWidth: 720)
                .frame(maxWidth: .infinity)
            }
            .background(.canvas)
            .buttonStyle(.bordered)
            .tint(.brandPrimaryInk)
            .foregroundStyle(.textPrimary)
            .navigationTitle(Text(.clientsSignatureTitle))
            .navigationBarTitleDisplayMode(dynamicTypeSize.isAccessibilitySize ? .inline : .large)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: viewModel.cancel) {
                        if dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: "xmark")
                                .frame(minWidth: 44, minHeight: 44)
                        } else {
                            Text(.clientsSignatureCancel)
                                .frame(minHeight: 44)
                        }
                    }
                    .accessibilityLabel(.clientsSignatureCancel)
                    .accessibilityShowsLargeContentViewer {
                        Label {
                            Text(.clientsSignatureCancel)
                        } icon: {
                            Image(systemName: "xmark")
                        }
                    }
                }
            }
        }
        .interactiveDismissDisabled()
        .accessibilityAction(.escape) {
            viewModel.cancel()
        }
        .onAppear {
            guard !hasPostedScreenChange else { return }
            hasPostedScreenChange = true
            AccessibilityNotification.ScreenChanged().post()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    private func endStroke() {
        viewModel.endStroke()
        announce(viewModel.validationError?.signatureMessage ?? .clientsSignatureAnnouncementStrokeEnded)
    }

    private func undo() {
        viewModel.undo()
        announce(.clientsSignatureAnnouncementUndo, priority: .high)
    }

    private func clear() {
        viewModel.clear()
        announce(.clientsSignatureAnnouncementClear, priority: .high)
    }

    private func confirm() {
        viewModel.confirm()
        if let error = viewModel.validationError {
            announce(error.signatureMessage)
        }
    }

    private func announce(
        _ resource: LocalizedStringResource,
        priority: AttributeScopes.AccessibilityAttributes.AnnouncementPriorityAttribute.AnnouncementPriority = .default
    ) {
        var resource = resource
        resource.locale = locale
        var announcement = AttributedString(String(localized: resource))
        announcement.accessibilitySpeechAnnouncementPriority = priority
        AccessibilityNotification.Announcement(announcement).post()
    }
}

extension ClientSignatureCaptureScreen {
    /// Opens one ephemeral capture session and delivers exactly one terminal result.
    /// The presenting flow dismisses this screen, restores focus to its origin and announces the accepted result
    /// after dismissal. It also owns the durability of captured ink; capture alone does not announce a saved consent.
    init(onFinish: @escaping @MainActor (ClientSignatureCaptureViewModel.Completion) -> Void) {
        _viewModel = State(initialValue: ClientSignatureCaptureViewModel(onFinish: onFinish))
    }

    fileprivate init(viewModel: ClientSignatureCaptureViewModel) {
        _viewModel = State(initialValue: viewModel)
    }
}

private extension ClientSignature.ValidationError {
    var signatureMessage: LocalizedStringResource {
        switch self {
        case .empty: .clientsSignatureErrorEmpty
        case .degenerateStroke: .clientsSignatureErrorStroke
        case .invalidCoordinates: .clientsSignatureErrorCoordinates
        }
    }
}

#Preview("Empty", traits: .modifier(AppPreviewModifier())) {
    ClientSignatureCaptureScreen { _ in }
}

#Preview("Ink", traits: .modifier(AppPreviewModifier())) {
    ClientSignatureCaptureScreen(viewModel: ClientSignaturePreviewFixtures.standard.inkViewModel)
}

#Preview("Narrow RTL", traits: .modifier(AppPreviewModifier())) {
    ClientSignatureCaptureScreen(viewModel: ClientSignaturePreviewFixtures.standard.inkViewModel)
        .environment(\.layoutDirection, .rightToLeft)
        .frame(width: 350)
}
