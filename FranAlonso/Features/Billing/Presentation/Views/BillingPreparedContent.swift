import SwiftUI

struct BillingPreparedContent: View {
    let request: BillingDocumentRequest

    var body: some View {
        Section {
            Text(request.kind.localizedTitle)
                .font(.headline)
            Text("billing.prepared.message")
                .fixedSize(horizontal: false, vertical: true)
        } header: {
            Text("billing.prepared.title")
                .textCase(nil)
                .accessibilityAddTraits(.isHeader)
        }
        if let recipient = request.fiscalRecipient {
            Section {
                ForEach(BillingFiscalField.allCases, id: \.self) { field in
                    VStack(alignment: .leading, spacing: 8) {
                        Text(field.localizedTitle)
                            .font(.headline)
                        Text(recipient.input[field])
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .accessibilityElement(children: .combine)
                }
            } header: {
                Text("billing.fiscal.title")
                    .textCase(nil)
                    .accessibilityAddTraits(.isHeader)
            }
        }
    }
}

#Preview("Prepared recipient", traits: .modifier(BillingPreviewModifier())) {
    if let request = BillingPreviewFixtures.model(kind: .invoice, prepared: true).request {
        Form { BillingPreparedContent(request: request) }
    }
}
