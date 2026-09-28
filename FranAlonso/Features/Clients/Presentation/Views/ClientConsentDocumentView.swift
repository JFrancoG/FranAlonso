import SwiftUI

struct ClientConsentDocumentView: View {
    let content: ClientDocumentContent
    let snapshot: ClientDocumentSnapshot?
    let signedAt: Date?
    let signature: ClientSignature?

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text(content.readerText(content.fields.title))
                .font(.title2.bold())
                .accessibilityAddTraits(.isHeader)
            Text(content.readerText(content.fields.reviewNotice))
                .font(.callout)
                .foregroundStyle(.textSecondary)
            if let snapshot {
                VStack(alignment: .leading, spacing: 4) {
                    Text(content.readerText(content.fields.labels.clientName))
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                    Text(content.readerText(snapshot.fields.clientName))
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(content.readerText(content.fields.labels.version))
                    .font(.caption)
                    .foregroundStyle(.textSecondary)
                Text(verbatim: content.fields.version)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibilityElement(children: .combine)
            ForEach(content.fields.sections.indices, id: \.self) { index in
                VStack(alignment: .leading, spacing: 8) {
                    if !content.fields.sections[index].heading.isEmpty {
                        Text(content.readerText(content.fields.sections[index].heading))
                            .font(.headline)
                            .accessibilityAddTraits(.isHeader)
                    }
                    Text(content.readerText(content.fields.sections[index].body))
                }
            }
            if let authorization = content.fields.photoAuthorization {
                Text(content.readerText(authorization))
            }
            Text(content.readerText(content.fields.signatureNotice))
            if let signature {
                Text(.clientsConsentSignature)
                    .font(.headline)
                    .accessibilityAddTraits(.isHeader)
                ClientConsentSignatureView(signature: signature)
            }
            if let signedAt {
                VStack(alignment: .leading, spacing: 4) {
                    Text(.clientsConsentSignatureDate)
                        .font(.caption)
                        .foregroundStyle(.textSecondary)
                    Text(signedAt, format: .dateTime.day().month(.wide).year().hour().minute())
                        .fixedSize(horizontal: false, vertical: true)
                }
                .accessibilityElement(children: .combine)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .textSelection(.enabled)
        .environment(\.locale, Locale(identifier: content.fields.language))
    }
}

#Preview("Signed document", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .signed) { model in
        if let store = model.consentStore, let content = store.content {
            ScrollView {
                ClientConsentDocumentView(
                    content: content,
                    snapshot: store.snapshot,
                    signedAt: store.draft?.fields.signedAt,
                    signature: store.signature
                )
                .padding()
            }
        }
    }
}
