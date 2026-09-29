import Accessibility
import SwiftUI
import UIKit

struct ClientConsentScreen: View {
    let viewModel: ClientFormViewModel
    @Environment(\.locale) private var locale
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @State private var request: Request?
    @State private var capture: CapturePresentation?
    @State private var completedRequest: Request?
    @State private var captureHasDismissed = true
    @State private var defaultFocus: FocusTarget = .title
    @State private var focusRestoration = ClientConsentFocusRestoration()
    @State private var focusObservation: NotificationCenter.ObservationToken?
    @State private var voiceOverObservation: NotificationCenter.ObservationToken?
    @State private var returnFocusIdentifier = "clients.consent.return.\(UUID().uuidString)"
    @AccessibilityFocusState(for: .voiceOver) private var focusedElement: FocusTarget?

    enum FocusTarget: Hashable {
        case title, capture, accept, retained, upload, feedback
    }

    private struct Request: Equatable {
        let id: UUID
        let action: ClientFormViewModel.ConsentAction
    }

    private struct CapturePresentation: Identifiable {
        let id: UUID
        let viewModel: ClientSignatureCaptureViewModel
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text(.clientsConsentTitle)
                        .font(.title.bold())
                        .accessibilityAddTraits(.isHeader)
                        .accessibilityFocused($focusedElement, equals: .title)
                    if let store = viewModel.consentStore {
                        if store.presentationIsStale {
                            Text(.clientsConsentStale).foregroundStyle(.errorInk)
                        }
                        if store.phase == .choosing {
                            ClientConsentRecoveryView(viewModel: viewModel, onAction: requestAction)
                        } else if store.phase == .profileConflict {
                            Text(.clientsConsentProfileConflictTitle)
                                .font(.headline)
                                .accessibilityAddTraits(.isHeader)
                            Text(.clientsConsentProfileConflictMessage)
                            Button {
                                requestAction(.useCurrentProfile)
                            } label: {
                                Text(.clientsConsentProfileCurrent).frame(minHeight: 44)
                            }
                            .primaryActionStyle()
                            .disabled(request != nil || store.isBusy)
                        } else if let content = store.content {
                            let showsPublicInformation = store.phase == .information
                            ClientConsentDocumentView(
                                content: content,
                                snapshot: showsPublicInformation ? nil : store.snapshot,
                                signedAt: showsPublicInformation ? nil
                                    : store.delivery?.document.fields.signedAt ?? store.draft?.fields.signedAt,
                                signature: showsPublicInformation ? nil : store.signature
                            )
                        }
                        ClientConsentActionsView(
                            viewModel: viewModel,
                            isRequestPending: request != nil,
                            accessibilityFocus: $focusedElement,
                            onAction: requestAction,
                            onCapture: beginCapture
                        )
                    }
                }
                .padding()
                .frame(maxWidth: 760)
                .frame(maxWidth: .infinity)
                .accessibilityDefaultFocus($focusedElement, defaultFocus)
            }
            .background(.canvas)
            .foregroundStyle(.textPrimary)
            .navigationTitle(Text(.clientsConsentTitle))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(action: returnToForm) {
                        if dynamicTypeSize.isAccessibilitySize {
                            Image(systemName: "xmark").frame(minWidth: 44, minHeight: 44)
                        } else {
                            Text(.clientsConsentBack).frame(minHeight: 44)
                        }
                    }
                    .accessibilityLabel(.clientsConsentBack)
                    .accessibilityIdentifier(returnFocusIdentifier)
                }
            }
        }
        .interactiveDismissDisabled()
        .accessibilityAction(.escape, returnToForm)
        .sheet(item: $capture, onDismiss: restoreCaptureFocus) { presentation in
            ClientSignatureCaptureScreen(viewModel: presentation.viewModel)
        }
        .onAppear {
            observeNativeFocus()
            preparePresentationFocus(.title)
        }
        .task(id: request) {
            guard let request else { return }
            await viewModel.performConsent(request.action)
            guard self.request?.id == request.id, !Task.isCancelled else { return }
            completedRequest = request
            self.request = nil
        }
        .onChange(of: completedRequest) { _, _ in
            finishPresentationUpdate()
        }
        .onChange(of: viewModel.consentStore?.operation, initial: true) { _, operation in
            if let operation {
                announce(operation.consentMessage)
            }
        }
        .onDisappear {
            stopObservingNativeFocus()
            request = nil
            viewModel.dismissConsentPresentation()
        }
    }

    private func requestAction(_ action: ClientFormViewModel.ConsentAction) {
        focusRestoration.cancel()
        guard request == nil else { return }
        if action == .upload {
            defaultFocus = .upload
        }
        request = Request(id: UUID(), action: action)
    }

    private func beginCapture() {
        focusRestoration.cancel()
        guard request == nil else { return }
        guard let model = viewModel.makeConsentCapture(onFinish: { result, id in
            capture = nil
            requestAction(.captured(result, id))
        }) else {
            return
        }
        captureHasDismissed = false
        defaultFocus = .capture
        capture = CapturePresentation(id: UUID(), viewModel: model)
    }

    private func restoreCaptureFocus() {
        captureHasDismissed = true
        finishPresentationUpdate()
    }

    /// Consumes feedback once the operation has finished and the capture sheet has actually dismissed.
    private func finishPresentationUpdate() {
        guard request == nil, let completedRequest, let store = viewModel.consentStore else { return }
        if case .captured = completedRequest.action, !captureHasDismissed {
            return
        }
        self.completedRequest = nil
        if let failure = store.failure {
            if case .captured = completedRequest.action {
                preparePresentationFocus(.feedback)
            } else {
                moveFocus(to: .feedback)
            }
            announce(failure.consentMessage, priority: .high)
        } else if case .captured(let result, _) = completedRequest.action {
            if store.canAccept {
                preparePresentationFocus(.accept)
            } else if store.canCapture {
                preparePresentationFocus(.capture)
            }
            if case .captured = result, store.phase == .signatureReview {
                announce(.clientsConsentSignatureSaved, priority: .high)
            }
        } else if completedRequest.action == .accept, store.delivery != nil {
            moveFocus(to: .retained)
            announce(.clientsConsentRetained, priority: .high)
        } else if completedRequest.action == .upload, store.delivery != nil {
            moveFocus(to: .retained)
            if let message = viewModel.consentActivationMessage {
                announce(message, priority: .high)
            }
        } else {
            defaultFocus = .title
        }
    }

    private func moveFocus(to target: FocusTarget) {
        focusRestoration.cancel()
        defaultFocus = target
        focusedElement = target
    }

    private func preparePresentationFocus(_ target: FocusTarget) {
        focusRestoration.prepare(target, voiceOverEnabled: UIAccessibility.isVoiceOverRunning)
        defaultFocus = target
    }

    private func observeNativeFocus() {
        guard focusObservation == nil else { return }
        focusObservation = NotificationCenter.default.addObserver(of: UIAccessibility.self, for: .elementFocused) {
            message in
            guard UIAccessibility.isVoiceOverRunning else {
                focusRestoration.cancel()
                return
            }
            let returnControlFocused = message.element?.accessibilityIdentifier == returnFocusIdentifier
            guard let target = focusRestoration.consume(returnControlFocused: returnControlFocused) else { return }
            moveFocus(to: target)
        }
        voiceOverObservation = NotificationCenter.default.addObserver(
            of: UIAccessibility.self,
            for: .voiceOverStatusDidChange
        ) { _ in
            if !UIAccessibility.isVoiceOverRunning {
                focusRestoration.cancel()
            }
        }
    }

    private func stopObservingNativeFocus() {
        focusRestoration.cancel()
        if let focusObservation {
            NotificationCenter.default.removeObserver(focusObservation)
        }
        if let voiceOverObservation {
            NotificationCenter.default.removeObserver(voiceOverObservation)
        }
        focusObservation = nil
        voiceOverObservation = nil
    }

    private func returnToForm() {
        focusRestoration.cancel()
        request = nil
        completedRequest = nil
        capture = nil
        viewModel.dismissConsentPresentation()
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

#Preview("Review", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .review) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Photo decision", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .photoReview) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Signed", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .signed) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Retained", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .retained) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Recovery", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .recovery) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Activation pending", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .activationPending) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Activated", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .activated) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Activation failed", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .activationFailure) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Error", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .error) {
        ClientConsentScreen(viewModel: $0)
    }
}

#Preview("Narrow RTL", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .review) {
        ClientConsentScreen(viewModel: $0)
    }
    .environment(\.layoutDirection, .rightToLeft)
    .frame(width: 350)
}
