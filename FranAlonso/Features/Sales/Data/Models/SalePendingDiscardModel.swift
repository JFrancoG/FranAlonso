import Foundation
import SwiftData

/// One immutable Sales draft discard in the durable causal delivery chain.
@Model
final class SalePendingDiscardModel {
    private(set) var saleID: UUID
    @Attribute(.unique) private(set) var operationID: UUID
    private(set) var predecessorOperationID: UUID?
    private(set) var baseVersion: Int
    private(set) var baseData: Data

    init(
        saleID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        baseVersion: Int,
        baseData: Data
    ) {
        self.saleID = saleID
        self.operationID = operationID
        self.predecessorOperationID = predecessorOperationID
        self.baseVersion = baseVersion
        self.baseData = baseData
    }
}

extension SalePendingDiscardModel {
    /// Creates the first supported durable draft discard for one sale.
    ///
    /// - Throws: An encoding error when the captured remote base cannot be serialized.
    convenience init(
        saleID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        base: SaleRemoteBase
    ) throws {
        self.init(
            saleID: saleID,
            operationID: operationID,
            predecessorOperationID: predecessorOperationID,
            baseVersion: 1,
            baseData: try JSONEncoder().encode(base)
        )
    }

    /// Decodes the immutable remote base captured by this discard.
    func decodeBase() throws -> SaleRemoteBase {
        guard baseVersion == 1 else {
            throw SalePendingDiscardPayloadError.unsupportedBaseVersion(
                baseVersion
            )
        }
        return try JSONDecoder().decode(SaleRemoteBase.self, from: baseData)
    }
}

/// Failures that prevent a persisted pending discard from being interpreted safely.
enum SalePendingDiscardPayloadError: Error, Equatable {
    case unsupportedBaseVersion(Int)
}
