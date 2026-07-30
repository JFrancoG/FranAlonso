import Foundation
import SwiftData

/// The latest authoritative remote Services record observed by synchronization.
@Model
final class ServiceRemoteStateModel {
    @Attribute(.unique) private(set) var serviceID: UUID
    private(set) var recordVersion: Int
    private(set) var recordData: Data

    init(serviceID: UUID, recordVersion: Int, recordData: Data) {
        self.serviceID = serviceID
        self.recordVersion = recordVersion
        self.recordData = recordData
    }
}

extension ServiceRemoteStateModel {
    /// Creates the first supported durable remote record snapshot.
    ///
    /// - Parameter record: The complete provider-neutral record to retain.
    /// - Throws: An encoding error when the record cannot be serialized.
    convenience init(record: ServiceRemoteRecord) throws {
        self.init(
            serviceID: try record.stableServiceID(),
            recordVersion: 1,
            recordData: try JSONEncoder().encode(record)
        )
    }

    /// Replaces the authoritative snapshot after encoding succeeds.
    ///
    /// - Parameter record: The newer complete provider-neutral record.
    /// - Throws: An encoding error or an identity mismatch.
    func update(record: ServiceRemoteRecord) throws {
        guard try record.stableServiceID() == serviceID else {
            throw ServiceSyncPersistenceError.entityIdentityMismatch
        }
        let encodedRecord = try JSONEncoder().encode(record)
        recordVersion = 1
        recordData = encodedRecord
    }

    /// Decodes the retained authoritative remote record.
    ///
    /// - Returns: The provider-neutral record last committed locally.
    /// - Throws: A version or native decoding error for invalid persisted data.
    func decodeRecord() throws -> ServiceRemoteRecord {
        guard recordVersion == 1 else {
            throw ServiceSyncPersistenceError.unsupportedRecordVersion(
                recordVersion
            )
        }
        return try JSONDecoder().decode(
            ServiceRemoteRecord.self,
            from: recordData
        )
    }
}
