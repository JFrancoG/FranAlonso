import Foundation

/// Recoverable failures of a complete, positioned PDF render plan.
enum BillingPDFRenderError: Error, Equatable {
    case missingContent
    case invalidLayout
    case limitExceeded
    case invalidDate
    case textDoesNotFit
    case renderingFailed
}

/// Renders a frozen, confirmed plan without reserving numbers or reading mutable resources.
///
/// Implementations publish all planned pages and fields or throw without returning partial bytes.
/// Determinism concerns content, order and geometry on the same toolchain, not Quartz serialization.
/// Financial projection and sale-line pagination belong to the caller.
protocol BillingPDFRenderer: Sendable {
    func render(_ request: BillingPDFRenderRequest) async throws -> Data
}
