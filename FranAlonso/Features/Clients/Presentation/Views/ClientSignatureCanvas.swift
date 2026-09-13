import SwiftUI

struct ClientSignatureCanvas: View {
    let strokes: [[ClientSignature.Point]]
    let currentStroke: [ClientSignature.Point]
    let status: LocalizedStringResource
    let onUpdateStroke: @MainActor (CGPoint, CGPoint, CGSize) -> Void
    let onEndStroke: @MainActor () -> Void
    let onCancelStroke: @MainActor () -> Void
    @GestureState private var isDrawing = false
    @State private var cancelledGesture = false

    var body: some View {
        GeometryReader { geometry in
            Canvas { context, size in
                for stroke in strokes {
                    draw(stroke, in: &context, size: size)
                }
                draw(currentStroke, in: &context, size: size)
            }
            .background(.surface)
            .clipShape(.rect(cornerRadius: 12))
            .overlay {
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(.textPrimary, lineWidth: 1)
            }
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .updating($isDrawing) { _, isDrawing, _ in
                        isDrawing = true
                    }
                    .onChanged { value in
                        guard !cancelledGesture else { return }
                        onUpdateStroke(value.startLocation, value.location, geometry.size)
                    }
                    .onEnded { value in
                        guard !cancelledGesture else { return }
                        onUpdateStroke(value.startLocation, value.location, geometry.size)
                        onEndStroke()
                    }
            )
            .onChange(of: geometry.size) {
                if isDrawing {
                    cancelledGesture = true
                }
                onCancelStroke()
            }
        }
        // Signature geometry stays 3:1 at every text size and never mirrors its physical axes in RTL.
        .aspectRatio(3, contentMode: .fit)
        .environment(\.layoutDirection, .leftToRight)
        .onChange(of: isDrawing) { _, isDrawing in
            if !isDrawing {
                onCancelStroke()
                cancelledGesture = false
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(.clientsSignatureCanvasLabel)
        .accessibilityValue(Text(status))
        .accessibilityAddTraits(.isImage)
    }

    private func draw(_ points: [ClientSignature.Point], in context: inout GraphicsContext, size: CGSize) {
        guard let first = points.first else { return }
        let start = CGPoint(x: first.x * size.width, y: first.y * size.height)
        if points.count == 1 {
            context.fill(
                Path(ellipseIn: CGRect(x: start.x - 1.5, y: start.y - 1.5, width: 3, height: 3)),
                with: .color(.textPrimary)
            )
        } else {
            var path = Path()
            path.move(to: start)
            for point in points.dropFirst() {
                path.addLine(to: CGPoint(x: point.x * size.width, y: point.y * size.height))
            }
            context.stroke(path, with: .color(.textPrimary), style: StrokeStyle(lineWidth: 3, lineCap: .round))
        }
    }
}

#Preview("Ink", traits: .modifier(AppPreviewModifier())) {
    ClientSignatureCanvas(
        strokes: ClientSignaturePreviewFixtures.standard.strokes,
        currentStroke: [],
        status: .clientsSignatureStatusReady,
        onUpdateStroke: { _, _, _ in },
        onEndStroke: {},
        onCancelStroke: {}
    )
    .padding()
}
