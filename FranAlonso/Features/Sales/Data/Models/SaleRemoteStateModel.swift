import Foundation
import SwiftData

/// The latest authoritative remote Sales record observed by synchronization.
@Model
final class SaleRemoteStateModel {
    @Attribute(.unique) private(set) var saleID: UUID
    private(set) var recordVersion: Int
    private(set) var recordData: Data

    init(saleID: UUID, recordVersion: Int, recordData: Data) {
        self.saleID = saleID
        self.recordVersion = recordVersion
        self.recordData = recordData
    }
}

extension SaleRemoteStateModel {
    /// Creates the first supported durable remote record snapshot.
    ///
    /// - Parameter record: The complete provider-neutral record to retain.
    /// - Throws: An encoding error when the record cannot be serialized.
    convenience init(record: SaleRemoteRecord) throws {
        self.init(
            saleID: try record.stableSaleID(),
            recordVersion: 1,
            recordData: try JSONEncoder().encode(record)
        )
    }

    /// Replaces the authoritative snapshot after encoding succeeds.
    ///
    /// - Parameter record: The newer complete provider-neutral record.
    /// - Throws: An encoding error or an identity mismatch.
    func update(record: SaleRemoteRecord) throws {
        guard try record.stableSaleID() == saleID else {
            throw SaleSyncPersistenceError.entityIdentityMismatch
        }
        let encodedRecord = try JSONEncoder().encode(record)
        recordVersion = 1
        recordData = encodedRecord
    }

    /// Decodes the retained authoritative remote record.
    ///
    /// - Returns: The provider-neutral record last committed locally.
    /// - Throws: A version or native decoding error for invalid persisted data.
    func decodeRecord() throws -> SaleRemoteRecord {
        guard recordVersion == 1 else {
            throw SaleSyncPersistenceError.unsupportedRecordVersion(
                recordVersion
            )
        }
        return try JSONDecoder().decode(
            SaleRemoteRecord.self,
            from: recordData
        )
    }
}
