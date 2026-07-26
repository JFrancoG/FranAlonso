import Foundation
import SwiftData

/// One immutable Products deletion in the durable causal delivery chain.
@Model
final class ProductPendingDeleteModel {
    private(set) var productID: UUID
    @Attribute(.unique) private(set) var operationID: UUID
    private(set) var predecessorOperationID: UUID?
    private(set) var baseVersion: Int
    private(set) var baseData: Data

    init(
        productID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        baseVersion: Int,
        baseData: Data
    ) {
        self.productID = productID
        self.operationID = operationID
        self.predecessorOperationID = predecessorOperationID
        self.baseVersion = baseVersion
        self.baseData = baseData
    }
}

extension ProductPendingDeleteModel {
    /// Creates the first supported durable deletion for one product.
    ///
    /// - Throws: An encoding error when the captured remote base cannot be serialized.
    convenience init(
        productID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        base: ProductRemoteBase
    ) throws {
        self.init(
            productID: productID,
            operationID: operationID,
            predecessorOperationID: predecessorOperationID,
            baseVersion: 1,
            baseData: try JSONEncoder().encode(base)
        )
    }

    /// Decodes the immutable remote base captured by this deletion.
    func decodeBase() throws -> ProductRemoteBase {
        guard baseVersion == 1 else {
            throw ProductPendingDeletePayloadError.unsupportedBaseVersion(
                baseVersion
            )
        }
        return try JSONDecoder().decode(ProductRemoteBase.self, from: baseData)
    }
}

/// Failures that prevent a persisted pending deletion from being interpreted safely.
enum ProductPendingDeletePayloadError: Error, Equatable {
    case unsupportedBaseVersion(Int)
}
