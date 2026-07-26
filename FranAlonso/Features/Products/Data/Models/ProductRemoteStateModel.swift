import Foundation
import SwiftData

/// The latest authoritative remote Products record observed by synchronization.
@Model
final class ProductRemoteStateModel {
    @Attribute(.unique) private(set) var productID: UUID
    private(set) var recordVersion: Int
    private(set) var recordData: Data

    init(productID: UUID, recordVersion: Int, recordData: Data) {
        self.productID = productID
        self.recordVersion = recordVersion
        self.recordData = recordData
    }
}

extension ProductRemoteStateModel {
    /// Creates the first supported durable remote record snapshot.
    ///
    /// - Parameter record: The complete provider-neutral record to retain.
    /// - Throws: An encoding error when the record cannot be serialized.
    convenience init(record: ProductRemoteRecord) throws {
        self.init(
            productID: try record.stableProductID(),
            recordVersion: 1,
            recordData: try JSONEncoder().encode(record)
        )
    }

    /// Replaces the authoritative snapshot after encoding succeeds.
    ///
    /// - Parameter record: The newer complete provider-neutral record.
    /// - Throws: An encoding error or an identity mismatch.
    func update(record: ProductRemoteRecord) throws {
        guard try record.stableProductID() == productID else {
            throw ProductSyncPersistenceError.entityIdentityMismatch
        }
        let encodedRecord = try JSONEncoder().encode(record)
        recordVersion = 1
        recordData = encodedRecord
    }

    /// Decodes the retained authoritative remote record.
    ///
    /// - Returns: The provider-neutral record last committed locally.
    /// - Throws: A version or native decoding error for invalid persisted data.
    func decodeRecord() throws -> ProductRemoteRecord {
        guard recordVersion == 1 else {
            throw ProductSyncPersistenceError.unsupportedRecordVersion(
                recordVersion
            )
        }
        return try JSONDecoder().decode(
            ProductRemoteRecord.self,
            from: recordData
        )
    }
}
