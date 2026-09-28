import SwiftUI

struct ClientConsentSignatureView: View {
    let signature: ClientSignature
    @ScaledMetric(relativeTo: .body) private var height = 120

    var body: some View {
        Canvas { context, size in
            for stroke in signature.strokes {
                var path = Path()
                for (index, point) in stroke.enumerated() {
                    let position = CGPoint(x: point.x * size.width, y: point.y * size.height)
                    if index == 0 {
                        path.move(to: position)
                    } else {
                        path.addLine(to: position)
                    }
                }
                context.stroke(path, with: .color(.textPrimary), lineWidth: 2)
            }
        }
        .frame(height: height)
        .background(.surface, in: .rect(cornerRadius: 12))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(.clientsConsentSignature)
        .accessibilityValue(.clientsConsentSignatureDescription)
    }
}

#Preview("Retained ink", traits: .modifier(ClientConsentPreviewModifier())) {
    ClientConsentPreviewHost(scenario: .signed) { model in
        if let signature = model.consentStore?.signature {
            ClientConsentSignatureView(signature: signature).padding()
        }
    }
}
