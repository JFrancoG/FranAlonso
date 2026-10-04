import Foundation

/// Versioned administrative intent; canonical identity prevents ambiguous audit ownership.
struct BillingSeriesAdjustmentRequestDTO: Codable, Equatable {
    let payloadVersion: Int
    let id: String
    let series: BillingDocumentSeries
    let expectedLastNumber: Int64
    let targetLastNumber: Int64
    let reason: BillingSeriesAdjustmentReason

    private enum CodingKeys: String, CodingKey, CaseIterable {
        case payloadVersion, id, series, expectedLastNumber, targetLastNumber, reason
    }
}

extension BillingSeriesAdjustmentRequestDTO {
    init(_ request: BillingSeriesAdjustmentRequest) {
        self.init(
            payloadVersion: 1,
            id: request.id.uuidString,
            series: request.series,
            expectedLastNumber: request.expectedLastNumber,
            targetLastNumber: request.targetLastNumber,
            reason: request.reason
        )
    }

    init(from decoder: any Decoder) throws {
        try requireBillingPayloadKeys(decoder, allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decode(Int.self, forKey: .payloadVersion),
            id: try container.decode(String.self, forKey: .id),
            series: try container.decode(BillingDocumentSeries.self, forKey: .series),
            expectedLastNumber: try container.decode(Int64.self, forKey: .expectedLastNumber),
            targetLastNumber: try container.decode(Int64.self, forKey: .targetLastNumber),
            reason: try container.decode(BillingSeriesAdjustmentReason.self, forKey: .reason)
        )
    }

    /// Reconstructs a valid forward-only intent from exact, supported transport.
    func toDomain() throws -> BillingSeriesAdjustmentRequest {
        guard payloadVersion == 1, let operationID = UUID(uuidString: id), operationID.uuidString == id else {
            throw BillingSeriesAdjustmentError.invalidResponse
        }
        do {
            return try BillingSeriesAdjustmentRequest(
                operationID: operationID,
                series: series,
                expectedLastNumber: expectedLastNumber,
                targetLastNumber: targetLastNumber,
                reason: reason
            )
        } catch {
            throw BillingSeriesAdjustmentError.invalidResponse
        }
    }
}
