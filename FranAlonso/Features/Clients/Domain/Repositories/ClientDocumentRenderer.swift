import Foundation

/// Produces PDF bytes exclusively from the supplied signed presentation, without consulting a live catalog.
protocol ClientDocumentRenderer: Sendable {
    func render(binding: ClientDocumentSignature, signedAt: Date) async throws -> Data
}
