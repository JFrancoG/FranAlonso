import Foundation

/// An immutable advance of one future billing sequence under a stable operation identity.
///
/// Expected and target values are last-issued sequence heads, not document numbers.
/// The target advances the expected head while retaining room for the next allocation.
/// The caller retains this complete command for explicit recovery after uncertain acceptance.
struct BillingSeriesAdjustmentRequest: Identifiable, Codable, Equatable {
    private let storedOperationID: UUID
    private let storedSeries: BillingDocumentSeries
    private let storedExpectedLastNumber: Int64
    private let storedTargetLastNumber: Int64
    private let storedReason: BillingSeriesAdjustmentReason

    var id: UUID { storedOperationID }
    var series: BillingDocumentSeries { storedSeries }
    var expectedLastNumber: Int64 { storedExpectedLastNumber }
    var targetLastNumber: Int64 { storedTargetLastNumber }
    var reason: BillingSeriesAdjustmentReason { storedReason }

    private enum CodingKeys: String, CodingKey {
        case operationID, series, expectedLastNumber, targetLastNumber, reason
    }
}

extension BillingSeriesAdjustmentRequest {
    /// Captures an explicit advance without allocating an identity, number, timestamp or authority.
    /// - Throws: `BillingSeriesAdjustmentError.invalidRequest` for a negative expected head,
    ///   a target that does not advance it, or a target without room for the next allocation.
    init(
        operationID: UUID,
        series: BillingDocumentSeries,
        expectedLastNumber: Int64,
        targetLastNumber: Int64,
        reason: BillingSeriesAdjustmentReason = .seriesAlignment
    ) throws {
        guard
            expectedLastNumber >= 0,
            targetLastNumber > expectedLastNumber,
            targetLastNumber < Int64.max
        else {
            throw BillingSeriesAdjustmentError.invalidRequest
        }
        self.init(
            storedOperationID: operationID,
            storedSeries: series,
            storedExpectedLastNumber: expectedLastNumber,
            storedTargetLastNumber: targetLastNumber,
            storedReason: reason
        )
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        try self.init(
            operationID: container.decode(UUID.self, forKey: .operationID),
            series: container.decode(BillingDocumentSeries.self, forKey: .series),
            expectedLastNumber: container.decode(Int64.self, forKey: .expectedLastNumber),
            targetLastNumber: container.decode(Int64.self, forKey: .targetLastNumber),
            reason: container.decode(BillingSeriesAdjustmentReason.self, forKey: .reason)
        )
    }

    func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .operationID)
        try container.encode(series, forKey: .series)
        try container.encode(expectedLastNumber, forKey: .expectedLastNumber)
        try container.encode(targetLastNumber, forKey: .targetLastNumber)
        try container.encode(reason, forKey: .reason)
    }
}
