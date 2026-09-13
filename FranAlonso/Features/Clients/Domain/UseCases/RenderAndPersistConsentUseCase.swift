import Foundation

/// Recovers the exact retained presentation and signing date, rendering only until durable acceptance.
/// A revision changed during rendering cannot accept stale output; later retries reuse accepted bytes.
struct RenderAndPersistConsentUseCase {
    let repository: any ClientDocumentRepository
    let renderer: any ClientDocumentRenderer

    func callAsFunction(draftID: UUID) async throws -> ClientDocumentDelivery {
        try Task.checkCancellation()
        guard let draft = try await repository.draft(id: draftID) else {
            throw ClientDocumentPersistenceError.notFound
        }
        guard let snapshot = draft.fields.snapshot,
              let binding = draft.fields.binding,
              let signedAt = draft.fields.signedAt
        else { throw ClientDocumentPersistenceError.invalidDraft }
        if let accepted = try await repository.delivery(id: snapshot.id) {
            guard accepted.document.fields.binding == binding, accepted.document.fields.signedAt == signedAt else {
                throw ClientDocumentPersistenceError.documentConflict
            }
            let retained = try await repository.accept(
                accepted.document,
                draftID: draft.id,
                revision: draft.fields.revision
            )
            try Task.checkCancellation()
            return retained
        }

        let document = try await RenderConsentUseCase(renderer: renderer, now: { signedAt })(
            snapshot: snapshot,
            binding: binding
        )
        let accepted = try await repository.accept(document, draftID: draft.id, revision: draft.fields.revision)
        try Task.checkCancellation()
        return accepted
    }
}
