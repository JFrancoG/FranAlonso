import CoreGraphics
import Testing
@testable import FranAlonso

@MainActor
@Suite("Client signature capture")
struct ClientSignatureCaptureViewModelTests {
    @Test
    func `empty confirmation keeps editing and reports the missing signature`() {
        var results: [ClientSignatureCaptureViewModel.Completion] = []
        let model = ClientSignatureCaptureViewModel { results.append($0) }

        model.confirm()

        #expect(results.isEmpty)
        #expect(model.validationError == .empty)
        #expect(!model.isFinished)
    }

    @Test
    func `capture normalizes geometry and emits an immutable result once`() throws {
        var results: [ClientSignatureCaptureViewModel.Completion] = []
        let model = ClientSignatureCaptureViewModel { results.append($0) }
        model.updateStroke(
            from: CGPoint(x: 30, y: 20),
            through: CGPoint(x: 240, y: 80),
            in: CGSize(width: 300, height: 100)
        )
        model.endStroke()
        model.confirm()
        model.cancel()
        model.confirm()
        model.updateStroke(from: .zero, through: CGPoint(x: 1, y: 1), in: CGSize(width: 10, height: 10))

        #expect(results.count == 1)
        let result = try #require(results.first)
        guard case .captured(let signature) = result else {
            Issue.record("A completed stroke must produce a captured signature.")
            return
        }
        #expect(signature.strokes == [[.init(x: 0.1, y: 0.2), .init(x: 0.8, y: 0.8)]])
        #expect(model.strokes.isEmpty)
        #expect(model.currentStroke.isEmpty)
        #expect(model.isFinished)
    }

    @Test
    func `cancellation removes all ink and ignores late input`() {
        var results: [ClientSignatureCaptureViewModel.Completion] = []
        let model = ClientSignatureCaptureViewModel { results.append($0) }
        drawStroke(on: model)
        model.updateStroke(from: .zero, through: CGPoint(x: 60, y: 40), in: CGSize(width: 300, height: 100))

        model.cancel()
        model.endStroke()
        model.confirm()
        model.cancel()

        #expect(results == [.cancelled])
        #expect(model.strokes.isEmpty)
        #expect(model.currentStroke.isEmpty)
        #expect(!model.canConfirm)
    }

    @Test
    func `interrupted stroke preserves earlier completed ink`() throws {
        var results: [ClientSignatureCaptureViewModel.Completion] = []
        let model = ClientSignatureCaptureViewModel { results.append($0) }
        drawStroke(on: model)
        model.updateStroke(from: .zero, through: CGPoint(x: 90, y: 50), in: CGSize(width: 300, height: 100))
        model.cancelCurrentStroke()
        model.confirm()

        guard case .captured(let signature) = try #require(results.first) else {
            Issue.record("Completed ink must survive an interrupted gesture.")
            return
        }
        #expect(signature.strokes == [[.init(x: 0.1, y: 0.2), .init(x: 0.8, y: 0.8)]])
    }

    @Test
    func `undo and clear cannot leave a confirmable empty capture`() {
        let model = ClientSignatureCaptureViewModel { _ in }
        drawStroke(on: model)
        drawStroke(on: model)
        model.undo()
        #expect(model.strokes.count == 1)
        model.clear()
        #expect(!model.canConfirm)
        #expect(model.strokes.isEmpty)
        #expect(model.currentStroke.isEmpty)
    }

    @Test
    func `invalid geometry never creates ink`() {
        let model = ClientSignatureCaptureViewModel { _ in }
        model.updateStroke(from: .zero, through: CGPoint(x: 20, y: 30), in: .zero)
        model.endStroke()

        #expect(!model.canConfirm)
        #expect(model.strokes.isEmpty)
    }

    private func drawStroke(on model: ClientSignatureCaptureViewModel) {
        model.updateStroke(
            from: CGPoint(x: 30, y: 20),
            through: CGPoint(x: 240, y: 80),
            in: CGSize(width: 300, height: 100)
        )
        model.endStroke()
    }
}
