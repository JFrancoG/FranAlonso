import Foundation

/// Ephemeral interpretation feedback remains separate from manual form persistence.
enum ServiceDraftAssistantState: Equatable {
    case idle
    case generating
    case proposed(ServiceDraftProposal)
    case applied
    case failed(ServiceDraftAssistantError)
    case unavailable(ServiceDraftAvailability)

    /// Shares content-free status copy between visible feedback and accessibility announcements.
    var message: LocalizedStringResource? {
        switch self {
        case .idle: nil
        case .generating: .servicesAssistantGenerating
        case .proposed: .servicesAssistantReview
        case .applied: .servicesAssistantApplied
        case .failed(.clarification): .servicesAssistantErrorClarification
        case .failed(.generationFailed): .servicesAssistantErrorGeneration
        case .failed(.inputTooLong): .servicesAssistantErrorInputLength
        case .unavailable(.available): nil
        case .unavailable(.deviceNotEligible): .servicesAssistantUnavailableDevice
        case .unavailable(.intelligenceDisabled): .servicesAssistantUnavailableDisabled
        case .unavailable(.modelNotReady): .servicesAssistantUnavailableModel
        case .unavailable(.unsupportedLanguage): .servicesAssistantUnavailableLanguage
        case .unavailable(.unavailable): .servicesAssistantUnavailableGeneral
        }
    }
}
