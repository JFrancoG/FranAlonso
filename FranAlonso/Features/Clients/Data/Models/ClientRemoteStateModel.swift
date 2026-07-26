import Foundation
import SwiftData

/// The latest authoritative remote Clients record observed by synchronization.
@Model
final class ClientRemoteStateModel {
    @Attribute(.unique) private(set) var clientID: UUID
    private(set) var recordVersion: Int
    private(set) var recordData: Data

    init(clientID: UUID, recordVersion: Int, recordData: Data) {
        self.clientID = clientID
        self.recordVersion = recordVersion
        self.recordData = recordData
    }
}

extension ClientRemoteStateModel {
    /// Creates the first supported durable remote record snapshot.
    ///
    /// - Parameter record: The complete provider-neutral record to retain.
    /// - Throws: An encoding error when the record cannot be serialized.
    convenience init(record: ClientRemoteRecord) throws {
        self.init(
            clientID: try record.client.stableUUID(),
            recordVersion: 1,
            recordData: try JSONEncoder().encode(record)
        )
    }

    /// Replaces the authoritative snapshot after encoding succeeds.
    ///
    /// - Parameter record: The newer complete provider-neutral record.
    /// - Throws: An encoding error or an identity mismatch.
    func update(record: ClientRemoteRecord) throws {
        guard try record.client.stableUUID() == clientID else {
            throw ClientSyncPersistenceError.entityIdentityMismatch
        }
        let encodedRecord = try JSONEncoder().encode(record)
        recordVersion = 1
        recordData = encodedRecord
    }

    /// Decodes the retained authoritative remote record.
    ///
    /// - Returns: The provider-neutral record last committed locally.
    /// - Throws: A version or native decoding error for invalid persisted data.
    func decodeRecord() throws -> ClientRemoteRecord {
        guard recordVersion == 1 else {
            throw ClientSyncPersistenceError.unsupportedRecordVersion(
                recordVersion
            )
        }
        return try JSONDecoder().decode(
            ClientRemoteRecord.self,
            from: recordData
        )
    }
}
