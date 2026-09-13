import Foundation
import Testing
@testable import FranAlonso

@Suite("Client signature invariants")
struct ClientSignatureTests {
    @Test
    func `empty capture is not a signature`() {
        #expect(throws: ClientSignature.ValidationError.empty) {
            try ClientSignature(strokes: [])
        }
    }

    @Test(arguments: [
        [],
        [ClientSignature.Point(x: 0.5, y: 0.5)],
        [ClientSignature.Point(x: 0.5, y: 0.5), ClientSignature.Point(x: 0.5, y: 0.5)]
    ])
    func `a stroke needs distinct points`(points: [ClientSignature.Point]) {
        #expect(throws: ClientSignature.ValidationError.degenerateStroke) {
            try ClientSignature(strokes: [points])
        }
    }

    @Test(arguments: ["nan", "inf", "-inf", "-0.01", "1.01"])
    func `coordinates must be finite and inside the capture area`(coordinate: String) throws {
        let value = try #require(Double(coordinate))
        #expect(throws: ClientSignature.ValidationError.invalidCoordinates) {
            try ClientSignature(strokes: [[.init(x: 0, y: 0), .init(x: value, y: 1)]])
        }
    }

    @Test
    func `decoding cannot bypass signature validation`() {
        let data = Data(#"{"strokes":[[{"x":0,"y":0},{"x":2,"y":1}]]}"#.utf8)
        #expect(throws: ClientSignature.ValidationError.invalidCoordinates) {
            try JSONDecoder().decode(ClientSignature.self, from: data)
        }
    }
}
