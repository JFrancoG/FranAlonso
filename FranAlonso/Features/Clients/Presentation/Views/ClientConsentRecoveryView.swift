import SwiftUI

struct ClientConsentRecoveryView: View {
    let viewModel: ClientFormViewModel
    let onAction: @MainActor (ClientFormViewModel.ConsentAction) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(.clientsConsentChoicesTitle)
                .font(.headline)
                .accessibilityAddTraits(.isHeader)
            ForEach(viewModel.consentDraftChoices) { choice in
                Button {
                    onAction(.selectDraft(choice.id))
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(.clientsConsentDraft)
                            Text(choice.ordinal, format: .number)
                        }
                        .font(.headline)
                        if let snapshot = choice.draft.fields.snapshot {
                            Text(verbatim: snapshot.fields.clientName)
                            Text(verbatim: snapshot.fields.content.fields.version)
                        }
                        if let signedAt = choice.draft.fields.signedAt {
                            Text(signedAt, format: .dateTime.day().month(.wide).year().hour().minute())
                        } else {
                            Text(.clientsConsentUnsigned)
                        }
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                }
            }
            ForEach(viewModel.consentStore?.deliveries ?? []) { delivery in
                Button {
                    onAction(.selectDelivery(delivery.id))
                } label: {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(.clientsConsentDocument).font(.headline)
                        Text(verbatim: delivery.document.fields.binding.snapshot.fields.clientName)
                        Text(verbatim: delivery.document.fields.binding.snapshot.fields.content.fields.version)
                        Text(
                            delivery.document.fields.signedAt,
                            format: .dateTime.day().month(.wide).year().hour().minute()
                        )
                        Text(delivery.state.consentMessage)
                    }
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityElement(children: .combine)
                }
            }
        }
        .buttonStyle(.bordered)
        .tint(.brandPrimaryInk)
        .disabled(viewModel.consentStore?.isBusy == true)
    }
}

#Preview("Recovery choices", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .recovery) { model in
        ScrollView {
            ClientConsentRecoveryView(viewModel: model) { _ in }
                .padding()
        }
    }
}
