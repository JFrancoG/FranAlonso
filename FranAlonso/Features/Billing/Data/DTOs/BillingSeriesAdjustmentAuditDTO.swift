import Foundation

/// Immutable administrative acceptance; nil time is permitted only in an uncommitted write plan.
struct BillingSeriesAdjustmentAuditDTO: Codable, Equatable {
    let payloadVersion: Int
    let request: BillingSeriesAdjustmentRequestDTO
    let principalID: String
    let adjustedAt: SaleTimestampDTO?

    private enum CodingKeys: String, CodingKey, CaseIterable { case payloadVersion, request, principalID, adjustedAt }
}

extension BillingSeriesAdjustmentAuditDTO {
    init(from decoder: any Decoder) throws {
        try requireBillingPayloadKeys(decoder, allowed: CodingKeys.allCases.map(\.rawValue))
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.init(
            payloadVersion: try container.decode(Int.self, forKey: .payloadVersion),
            request: try container.decode(BillingSeriesAdjustmentRequestDTO.self, forKey: .request),
            principalID: try container.decode(String.self, forKey: .principalID),
            adjustedAt: try container.decodeIfPresent(SaleTimestampDTO.self, forKey: .adjustedAt)
        )
    }

    /// Unresolved time and invalid authority can never appear as a confirmed acceptance.
    func toDomain() throws -> BillingSeriesAdjustmentReceipt {
        guard payloadVersion == 1, let adjustedAt else { throw BillingSeriesAdjustmentError.invalidResponse }
        do {
            return try BillingSeriesAdjustmentReceipt(
                request: request.toDomain(),
                principalID: principalID,
                adjustedAt: adjustedAt.date
            )
        } catch {
            throw BillingSeriesAdjustmentError.invalidResponse
        }
    }
}
