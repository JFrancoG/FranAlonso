import Foundation

/// Loads the exact bytes of a validated, supported billing template.
protocol BillingDocumentTemplateRepository: Sendable {
    func loadTemplate(for kind: BillingDocumentKind) async throws -> Data
}
