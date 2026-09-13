import Foundation

/// Immutable ink in a 3:1 capture area, independent of UI frameworks and persistence.
/// Coordinates run from zero at the physical top/left to one at the bottom/right.
/// Validation proves the presence of nondegenerate ink, not identity or consent.
struct ClientSignature: Codable, Equatable {
    struct Point: Codable, Equatable {
        let x: Double
        let y: Double
    }

    enum ValidationError: Error, Equatable {
        case empty
        case degenerateStroke
        case invalidCoordinates
    }

    private let storedStrokes: [[Point]]
    var strokes: [[Point]] { storedStrokes }

    private enum CodingKeys: String, CodingKey {
        case storedStrokes = "strokes"
    }
}

extension ClientSignature {
    /// Rejects empty captures, nonfinite/out-of-bounds coordinates and strokes without movement.
    init(strokes: [[Point]]) throws(ValidationError) {
        guard !strokes.isEmpty else { throw .empty }
        for stroke in strokes {
            guard stroke.allSatisfy({ point in
                point.x.isFinite && point.y.isFinite && (0...1).contains(point.x) && (0...1).contains(point.y)
            }) else { throw .invalidCoordinates }
            guard let first = stroke.first, stroke.contains(where: { $0 != first }) else { throw .degenerateStroke }
        }
        self.init(storedStrokes: strokes)
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(strokes: container.decode([[Point]].self, forKey: .storedStrokes))
    }
}
