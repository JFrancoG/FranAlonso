import Foundation
import SwiftData

/// One immutable Clients deletion in the durable causal delivery chain.
@Model
final class ClientPendingDeleteModel {
    private(set) var clientID: UUID
    @Attribute(.unique) private(set) var operationID: UUID
    private(set) var predecessorOperationID: UUID?
    private(set) var baseVersion: Int
    private(set) var baseData: Data

    init(
        clientID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        baseVersion: Int,
        baseData: Data
    ) {
        self.clientID = clientID
        self.operationID = operationID
        self.predecessorOperationID = predecessorOperationID
        self.baseVersion = baseVersion
        self.baseData = baseData
    }
}

extension ClientPendingDeleteModel {
    /// Creates the first supported durable deletion for one client.
    ///
    /// - Throws: An encoding error when the captured remote base cannot be serialized.
    convenience init(
        clientID: UUID,
        operationID: UUID,
        predecessorOperationID: UUID?,
        base: ClientRemoteBase
    ) throws {
        self.init(
            clientID: clientID,
            operationID: operationID,
            predecessorOperationID: predecessorOperationID,
            baseVersion: 1,
            baseData: try JSONEncoder().encode(base)
        )
    }

    /// Decodes the immutable remote base captured by this deletion.
    func decodeBase() throws -> ClientRemoteBase {
        guard baseVersion == 1 else {
            throw ClientPendingDeletePayloadError.unsupportedBaseVersion(
                baseVersion
            )
        }
        return try JSONDecoder().decode(ClientRemoteBase.self, from: baseData)
    }
}

/// Failures that prevent a persisted pending deletion from being interpreted safely.
enum ClientPendingDeletePayloadError: Error, Equatable {
    case unsupportedBaseVersion(Int)
}
