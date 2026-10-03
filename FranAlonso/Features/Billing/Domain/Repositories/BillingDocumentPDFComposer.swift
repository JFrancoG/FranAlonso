import Foundation

/// Composes complete positioned pages from an immutable financial projection and captured assets.
///
/// Implementations retain the exact document, template and optional signature in their render request.
/// Every captured sale line and fiscal term must be represented completely or rejected without a partial plan.
protocol BillingDocumentPDFComposer: Sendable {
    func compose(
        _ projection: BillingDocumentProjection,
        template: Data,
        signature: Data?
    ) async throws -> BillingPDFRenderRequest
}
