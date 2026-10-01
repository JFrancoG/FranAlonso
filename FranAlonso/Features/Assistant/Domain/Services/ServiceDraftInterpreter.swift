import Foundation

/// Interprets one ephemeral description without reading or mutating persisted business data.
///
/// A proposal only prepares optional fields for human review. Cancellation must prevent publication;
/// callers remain responsible for discarding results after the form or its draft changes.
protocol ServiceDraftInterpreter: Sendable {
    func availability(locale: Locale) async -> ServiceDraftAvailability
    func interpret(_ description: String, locale: Locale) async throws -> ServiceDraftProposal
}

/// Recoverable conditions that leave the manual service form available.
enum ServiceDraftAvailability: Equatable {
    case available
    case deviceNotEligible
    case intelligenceDisabled
    case modelNotReady
    case unsupportedLanguage
    case unavailable
}
