/// Content-free failures safe to translate into user-facing recovery guidance.
enum ServiceDraftAssistantError: Error, Equatable {
    case clarification
    case generationFailed
    case inputTooLong
}
