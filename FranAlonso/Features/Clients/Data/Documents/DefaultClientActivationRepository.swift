import Foundation

/// Authorizes activation against the current session and principal before and after the durable transition.
struct DefaultClientActivationRepository: ClientActivationRepository {
    let persistence: ClientDocumentPersistenceActor
    let access: ClientDocumentAccess
    let observationSignal: any ClientChangeSignaling

    func prepareActivation(clientID: ClientID, documentID: UUID, operationID: UUID) async throws -> Client {
        try await authorized {
            try await persistence.prepareActivation(
                clientID: clientID,
                documentID: documentID,
                operationID: operationID,
                principalID: access.principalID
            )
        }
    }

    func activate(clientID: ClientID, documentID: UUID, operationID: UUID) async throws -> Client {
        try await authorized {
            try await persistence.activate(
                clientID: clientID,
                documentID: documentID,
                operationID: operationID,
                principalID: access.principalID
            )
        }
    }

    private func authorized(_ operation: @Sendable () async throws -> Client) async throws -> Client {
        try await access.validate()
        let result = try await operation()
        try await access.validate()
        await observationSignal.publishChange()
        try await access.validate()
        return result
    }
}
