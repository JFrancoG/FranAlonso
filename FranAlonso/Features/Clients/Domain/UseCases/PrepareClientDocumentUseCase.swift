import Foundation

/// Freezes resolved legal text and presented client data before capturing ink.
struct PrepareClientDocumentUseCase {
    let catalog: any ClientDocumentCatalog
    let newID: @Sendable () -> UUID

    func callAsFunction(
        clientID: ClientID,
        clientName: String,
        context: ClientDocumentContext,
        version: String,
        language: String
    ) async throws -> ClientDocumentSnapshot {
        let content = try await catalog.content(variant: context.variant, version: version, language: language)
        guard content.fields.version == version else { throw ClientDocumentError.unsupportedVersion }
        guard content.fields.language == language else { throw ClientDocumentError.unsupportedLanguage }
        return try ClientDocumentSnapshot(.init(
            id: newID(),
            clientID: clientID,
            clientName: clientName,
            context: context,
            content: content
        ))
    }
}
