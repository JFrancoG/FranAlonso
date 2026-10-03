import Foundation

/// Provides an optional private image without granting document issuance or authenticity.
///
/// Absence is represented by `nil`; access, validation and storage failures remain recoverable errors.
/// Imports preserve the previous image when rejected before publication.
protocol BillingBusinessSignatureRepository: Sendable {
    func loadSignature() async throws -> Data?
    func importSignature(_ data: Data) async throws
}
