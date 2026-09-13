import CoreGraphics
import Observation

/// Owns one ephemeral capture session. The consumer receives one terminal result and owns its durability.
/// Closing or cancelling discards ink; no persistence, upload or client activation occurs here.
@Observable @MainActor
final class ClientSignatureCaptureViewModel {
    enum Completion: Equatable {
        case captured(ClientSignature)
        case cancelled
    }

    private(set) var strokes: [[ClientSignature.Point]] = []
    private(set) var currentStroke: [ClientSignature.Point] = []
    private(set) var validationError: ClientSignature.ValidationError?
    private(set) var isFinished = false
    private var onFinish: (@MainActor (Completion) -> Void)?

    var canConfirm: Bool { !isFinished && !strokes.isEmpty && currentStroke.isEmpty }
    var canUndo: Bool { !isFinished && (!strokes.isEmpty || !currentStroke.isEmpty) }
    var canClear: Bool { canUndo }

    init(onFinish: @escaping @MainActor (Completion) -> Void) {
        self.onFinish = onFinish
    }

    /// Samples a freehand gesture, preserving its first point and ignoring invalid geometry.
    func updateStroke(from start: CGPoint, through location: CGPoint, in size: CGSize) {
        guard !isFinished,
              let first = normalized(start, in: size), let next = normalized(location, in: size) else { return }
        if currentStroke.isEmpty {
            currentStroke.append(first)
        }
        appendPoint(next)
    }

    /// Commits only a completed, nondegenerate stroke. A dot remains an editable validation error.
    func endStroke() {
        guard !isFinished, !currentStroke.isEmpty else { return }
        do {
            let signature = try ClientSignature(strokes: [currentStroke])
            strokes.append(contentsOf: signature.strokes)
            currentStroke.removeAll()
            validationError = nil
        } catch {
            currentStroke.removeAll()
            validationError = error
        }
    }

    /// A cancelled gesture or resized canvas must not commit partial ink or erase completed strokes.
    func cancelCurrentStroke() {
        guard !isFinished else { return }
        currentStroke.removeAll()
    }

    /// Only explicitly ended strokes can be accepted; an unfinished gesture cannot be silently included.
    func confirm() {
        guard !isFinished else { return }
        guard currentStroke.isEmpty else {
            validationError = .degenerateStroke
            return
        }
        do {
            finish(.captured(try ClientSignature(strokes: strokes)))
        } catch {
            validationError = error
        }
    }

    func cancel() {
        finish(.cancelled)
    }

    /// Reverts the unfinished stroke first, then one completed stroke per invocation.
    func undo() {
        guard !isFinished else { return }
        if !currentStroke.isEmpty {
            currentStroke.removeAll()
        } else if !strokes.isEmpty {
            strokes.removeLast()
        }
        validationError = nil
    }

    func clear() {
        guard !isFinished else { return }
        strokes.removeAll()
        currentStroke.removeAll()
        validationError = nil
    }

    private func appendPoint(_ point: ClientSignature.Point) {
        if currentStroke.last != point {
            currentStroke.append(point)
        }
        validationError = nil
    }

    private func normalized(_ point: CGPoint, in size: CGSize) -> ClientSignature.Point? {
        guard size.width.isFinite, size.height.isFinite, size.width > 0, size.height > 0,
              point.x.isFinite, point.y.isFinite else { return nil }
        return .init(
            x: Double(min(max(point.x, 0), size.width) / size.width),
            y: Double(min(max(point.y, 0), size.height) / size.height)
        )
    }

    private func finish(_ completion: Completion) {
        guard !isFinished else { return }
        isFinished = true
        strokes.removeAll()
        currentStroke.removeAll()
        validationError = nil
        let callback = onFinish
        onFinish = nil
        callback?(completion)
    }
}
