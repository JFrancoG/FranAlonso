/// Resolves a specific legal version and language without silently substituting another presentation.
protocol ClientDocumentCatalog: Sendable {
    func content(
        variant: ClientDocumentVariant,
        version: String,
        language: String
    ) async throws -> ClientDocumentContent
}
