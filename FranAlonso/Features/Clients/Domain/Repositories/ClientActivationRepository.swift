import Foundation

/// Transitions a client using its durable initial document, preserving the current profile and causal work.
/// Repeating an applied transition is a no-op; a different initial reference cannot replace an active one.
protocol ClientActivationRepository: Sendable {
    func prepareActivation(clientID: ClientID, documentID: UUID, operationID: UUID) async throws -> Client
    func activate(clientID: ClientID, documentID: UUID, operationID: UUID) async throws -> Client
}

/// Activation-specific failures; document, authorization and persistence errors retain their original contracts.
enum ClientActivationError: Error, Equatable {
    case invalidDocument
    case uploadRequired
    case differentInitialDocument
}
