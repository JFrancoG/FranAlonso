import Foundation

/// Refuses stale ink before rendering and returns one immutable document/artefact association.
struct RenderConsentUseCase {
    let renderer: any ClientDocumentRenderer
    let now: @Sendable () -> Date

    func callAsFunction(
        snapshot: ClientDocumentSnapshot,
        binding: ClientDocumentSignature
    ) async throws -> ClientSignedDocument {
        try Task.checkCancellation()
        guard snapshot == binding.snapshot else { throw ClientDocumentError.staleSignature }
        let signedAt = now()
        guard signedAt.timeIntervalSince1970.isFinite,
              (-62_135_596_800...253_402_300_799).contains(signedAt.timeIntervalSince1970)
        else { throw ClientDocumentError.invalidDate }
        let pdf: Data
        do {
            pdf = try await renderer.render(binding: binding, signedAt: signedAt)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as ClientDocumentError {
            throw error
        } catch {
            throw ClientDocumentError.renderingFailed
        }
        try Task.checkCancellation()
        return try ClientSignedDocument(.init(binding: binding, signedAt: signedAt, pdf: pdf))
    }
}
