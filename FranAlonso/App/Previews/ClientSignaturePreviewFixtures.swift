import CoreGraphics

/// Supplies synthetic vector ink and ephemeral capture sessions without persistence or captured personal data.
struct ClientSignaturePreviewFixtures {
    let strokes: [[ClientSignature.Point]]

    static let standard = ClientSignaturePreviewFixtures(strokes: [
        [.init(x: 0.12, y: 0.7), .init(x: 0.25, y: 0.22), .init(x: 0.24, y: 0.75), .init(x: 0.4, y: 0.35),
         .init(x: 0.5, y: 0.65), .init(x: 0.61, y: 0.45), .init(x: 0.82, y: 0.6)],
        [.init(x: 0.2, y: 0.84), .init(x: 0.87, y: 0.74)]
    ])

    @MainActor var inkViewModel: ClientSignatureCaptureViewModel {
        let viewModel = ClientSignatureCaptureViewModel { _ in }
        let size = CGSize(width: 300, height: 100)
        for stroke in strokes {
            guard let first = stroke.first else { continue }
            let start = CGPoint(x: first.x * size.width, y: first.y * size.height)
            for point in stroke {
                viewModel.updateStroke(
                    from: start,
                    through: CGPoint(x: point.x * size.width, y: point.y * size.height),
                    in: size
                )
            }
            viewModel.endStroke()
        }
        return viewModel
    }
}
