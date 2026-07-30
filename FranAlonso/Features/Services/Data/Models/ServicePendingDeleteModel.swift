import Foundation
import SwiftData

/// One immutable Services deletion in the durable causal delivery chain.
@Model
final class ServicePendingDeleteModel {
    private(set) var serviceID: UUID
    @Attribute(.unique) private(set) var operationID: UUID
    private(set) var predecessorOperationID: UUID?
    private(set) var baseVersion: Int
    private(set) var baseData: Data

    init(
        serviceID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        baseVersion: Int,
        baseData: Data
    ) {
        self.serviceID = serviceID
        self.operationID = operationID
        self.predecessorOperationID = predecessorOperationID
        self.baseVersion = baseVersion
        self.baseData = baseData
    }
}

extension ServicePendingDeleteModel {
    /// Creates the first supported durable deletion for one service.
    ///
    /// - Throws: An encoding error when the captured remote base cannot be serialized.
    convenience init(
        serviceID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        base: ServiceRemoteBase
    ) throws {
        self.init(
            serviceID: serviceID,
            operationID: operationID,
            predecessorOperationID: predecessorOperationID,
            baseVersion: 1,
            baseData: try JSONEncoder().encode(base)
        )
    }

    /// Decodes the immutable remote base captured by this deletion.
    func decodeBase() throws -> ServiceRemoteBase {
        guard baseVersion == 1 else {
            throw ServicePendingDeletePayloadError.unsupportedBaseVersion(
                baseVersion
            )
        }
        return try JSONDecoder().decode(ServiceRemoteBase.self, from: baseData)
    }
}

/// Failures that prevent a persisted pending deletion from being interpreted safely.
enum ServicePendingDeletePayloadError: Error, Equatable {
    case unsupportedBaseVersion(Int)
}
