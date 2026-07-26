import Foundation
import SwiftData

/// Both snapshots required to resolve one Clients synchronization conflict explicitly.
@Model
final class ClientSyncConflictModel {
    @Attribute(.unique) private(set) var clientID: UUID
    private(set) var operationID: UUID
    private(set) var reasonRawValue: String
    private(set) var payloadVersion: Int
    private(set) var baseData: Data
    private(set) var localClientData: Data
    private(set) var remoteRecordData: Data?

    init(
        clientID: UUID,
        operationID: UUID,
        reasonRawValue: String,
        payloadVersion: Int,
        baseData: Data,
        localClientData: Data,
        remoteRecordData: Data?
    ) {
        self.clientID = clientID
        self.operationID = operationID
        self.reasonRawValue = reasonRawValue
        self.payloadVersion = payloadVersion
        self.baseData = baseData
        self.localClientData = localClientData
        self.remoteRecordData = remoteRecordData
    }
}

extension ClientSyncConflictModel {
    /// Creates the first supported durable conflict payload.
    ///
    /// - Parameters:
    ///   - operation: The local operation that could not advance.
    ///   - reason: The deterministic policy reason for the conflict.
    ///   - remoteRecord: The remote state observed by the failed attempt, when present.
    /// - Throws: An encoding error when any snapshot cannot be serialized.
    convenience init(
        operation: ClientPendingUpsert,
        reason: ClientSyncConflictReason,
        remoteRecord: ClientRemoteRecord?
    ) throws {
        self.init(
            clientID: operation.clientID,
            operationID: operation.operationID,
            reasonRawValue: reason.rawValue,
            payloadVersion: 1,
            baseData: try JSONEncoder().encode(operation.base),
            localClientData: try JSONEncoder().encode(operation.client),
            remoteRecordData: try remoteRecord.map { record in
                try JSONEncoder().encode(record)
            }
        )
    }

    /// Replaces a conflict after all new snapshots encode successfully.
    func update(
        operation: ClientPendingUpsert,
        reason: ClientSyncConflictReason,
        remoteRecord: ClientRemoteRecord?
    ) throws {
        guard operation.clientID == clientID else {
            throw ClientSyncPersistenceError.entityIdentityMismatch
        }
        let encodedBase = try JSONEncoder().encode(operation.base)
        let encodedLocalClient = try JSONEncoder().encode(operation.client)
        let encodedRemoteRecord = try remoteRecord.map { record in
            try JSONEncoder().encode(record)
        }

        operationID = operation.operationID
        reasonRawValue = reason.rawValue
        payloadVersion = 1
        baseData = encodedBase
        localClientData = encodedLocalClient
        remoteRecordData = encodedRemoteRecord
    }

    /// Decodes the stable conflict classification retained for resolution.
    func decodeReason() throws -> ClientSyncConflictReason {
        guard let reason = ClientSyncConflictReason(rawValue: reasonRawValue) else {
            throw ClientSyncPersistenceError.invalidConflictReason(
                reasonRawValue
            )
        }
        return reason
    }

    /// Decodes the remote base against which the blocked local operation was created.
    func decodeBase() throws -> ClientRemoteBase {
        try requireSupportedVersion()
        return try JSONDecoder().decode(ClientRemoteBase.self, from: baseData)
    }

    /// Decodes the complete local snapshot that could not be applied.
    func decodeLocalClient() throws -> ClientDTO {
        try requireSupportedVersion()
        return try JSONDecoder().decode(ClientDTO.self, from: localClientData)
    }

    /// Decodes the complete remote snapshot observed by the conflicting attempt.
    func decodeRemoteRecord() throws -> ClientRemoteRecord? {
        try requireSupportedVersion()
        return try remoteRecordData.map { data in
            try JSONDecoder().decode(ClientRemoteRecord.self, from: data)
        }
    }

    private func requireSupportedVersion() throws {
        guard payloadVersion == 1 else {
            throw ClientSyncPersistenceError.unsupportedConflictVersion(
                payloadVersion
            )
        }
    }
}

/// Failures that prevent persisted Clients synchronization state from being trusted.
enum ClientSyncPersistenceError: Error, Equatable {
    case ambiguousPendingLineage(ClientID)
    case cyclicPendingLineage(ClientID)
    case duplicateOperationIdentity(UUID)
    case entityIdentityMismatch
    case invalidCursor
    case invalidConflictReason(String)
    case unsupportedConflictVersion(Int)
    case unsupportedRecordVersion(Int)
}

extension ClientDTO {
    /// Returns the canonical UUID carried by this transport snapshot.
    ///
    /// - Throws: `ClientSyncPersistenceError.entityIdentityMismatch` when `id` is invalid.
    func stableUUID() throws -> UUID {
        guard let identifier = UUID(uuidString: id) else {
            throw ClientSyncPersistenceError.entityIdentityMismatch
        }
        return identifier
    }
}
