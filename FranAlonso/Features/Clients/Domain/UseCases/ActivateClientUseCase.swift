import Foundation

/// Makes pending activation durable before upload and activates only after the receipt is retained locally.
/// A retry resumes the retained document and never renders, signs or uploads an already completed artifact again.
struct ActivateClientUseCase {
    let repository: any ClientActivationRepository
    let upload: UploadConsentUseCase
    let makeOperationID: @Sendable () -> UUID

    func callAsFunction(clientID: ClientID, documentID: UUID) async throws -> Client {
        try Task.checkCancellation()
        let prepared = try await repository.prepareActivation(
            clientID: clientID,
            documentID: documentID,
            operationID: makeOperationID()
        )
        try Task.checkCancellation()
        if case .active = prepared.status {
            return prepared
        }
        _ = try await upload(documentID: documentID)
        try Task.checkCancellation()
        let activated = try await repository.activate(
            clientID: clientID,
            documentID: documentID,
            operationID: makeOperationID()
        )
        try Task.checkCancellation()
        return activated
    }
}
