import Foundation
import SwiftData

/// Both snapshots required to resolve one Services synchronization conflict explicitly.
@Model
final class ServiceSyncConflictModel {
    @Attribute(.unique) private(set) var serviceID: UUID
    private(set) var operationID: UUID
    private(set) var reasonRawValue: String
    private(set) var payloadVersion: Int
    private(set) var baseData: Data
    private(set) var localServiceData: Data
    private(set) var remoteRecordData: Data?

    init(
        serviceID: UUID,
        operationID: UUID,
        reasonRawValue: String,
        payloadVersion: Int,
        baseData: Data,
        localServiceData: Data,
        remoteRecordData: Data?
    ) {
        self.serviceID = serviceID
        self.operationID = operationID
        self.reasonRawValue = reasonRawValue
        self.payloadVersion = payloadVersion
        self.baseData = baseData
        self.localServiceData = localServiceData
        self.remoteRecordData = remoteRecordData
    }
}

extension ServiceSyncConflictModel {
    /// Creates the first supported durable conflict payload.
    ///
    /// - Parameters:
    ///   - operation: The local operation that could not advance.
    ///   - reason: The deterministic policy reason for the conflict.
    ///   - remoteRecord: The remote state observed by the failed attempt, when present.
    /// - Throws: An encoding error when any snapshot cannot be serialized.
    convenience init(
        operation: ServicePendingUpsert,
        reason: ServiceSyncConflictReason,
        remoteRecord: ServiceRemoteRecord?
    ) throws {
        self.init(
            serviceID: operation.serviceID,
            operationID: operation.operationID,
            reasonRawValue: reason.rawValue,
            payloadVersion: 1,
            baseData: try JSONEncoder().encode(operation.base),
            localServiceData: try JSONEncoder().encode(operation.service),
            remoteRecordData: try remoteRecord.map { record in
                try JSONEncoder().encode(record)
            }
        )
    }

    /// Replaces a conflict after all new snapshots encode successfully.
    func update(
        operation: ServicePendingUpsert,
        reason: ServiceSyncConflictReason,
        remoteRecord: ServiceRemoteRecord?
    ) throws {
        guard operation.serviceID == serviceID else {
            throw ServiceSyncPersistenceError.entityIdentityMismatch
        }
        let encodedBase = try JSONEncoder().encode(operation.base)
        let encodedLocalService = try JSONEncoder().encode(operation.service)
        let encodedRemoteRecord = try remoteRecord.map { record in
            try JSONEncoder().encode(record)
        }

        operationID = operation.operationID
        reasonRawValue = reason.rawValue
        payloadVersion = 1
        baseData = encodedBase
        localServiceData = encodedLocalService
        remoteRecordData = encodedRemoteRecord
    }

    /// Decodes the stable conflict classification retained for resolution.
    func decodeReason() throws -> ServiceSyncConflictReason {
        guard let reason = ServiceSyncConflictReason(rawValue: reasonRawValue) else {
            throw ServiceSyncPersistenceError.invalidConflictReason(
                reasonRawValue
            )
        }
        return reason
    }

    /// Decodes the remote base against which the blocked local operation was created.
    func decodeBase() throws -> ServiceRemoteBase {
        try requireSupportedVersion()
        return try JSONDecoder().decode(ServiceRemoteBase.self, from: baseData)
    }

    /// Decodes the complete local snapshot that could not be applied.
    func decodeLocalService() throws -> ServiceDTO {
        try requireSupportedVersion()
        return try JSONDecoder().decode(ServiceDTO.self, from: localServiceData)
    }

    /// Decodes the complete remote snapshot observed by the conflicting attempt.
    func decodeRemoteRecord() throws -> ServiceRemoteRecord? {
        try requireSupportedVersion()
        return try remoteRecordData.map { data in
            try JSONDecoder().decode(ServiceRemoteRecord.self, from: data)
        }
    }

    private func requireSupportedVersion() throws {
        guard payloadVersion == 1 else {
            throw ServiceSyncPersistenceError.unsupportedConflictVersion(
                payloadVersion
            )
        }
    }
}

/// Failures that prevent persisted Services synchronization state from being trusted.
enum ServiceSyncPersistenceError: Error, Equatable {
    case ambiguousPendingLineage(ServiceID)
    case cyclicPendingLineage(ServiceID)
    case duplicateOperationIdentity(UUID)
    case entityIdentityMismatch
    case invalidCursor
    case invalidConflictReason(String)
    case unsupportedConflictVersion(Int)
    case unsupportedRecordVersion(Int)
}

extension ServiceDTO {
    /// Returns the canonical UUID carried by this transport snapshot.
    ///
    /// - Throws: `ServiceSyncPersistenceError.entityIdentityMismatch` when `id` is invalid.
    func stableUUID() throws -> UUID {
        guard let identifier = UUID(uuidString: id) else {
            throw ServiceSyncPersistenceError.entityIdentityMismatch
        }
        return identifier
    }
}
