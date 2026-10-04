import Foundation

/// Reads a retained final document under its captured capability without billing motors or sale writes.
struct PrepareBillingEmailDraftUseCase {
    private let localRepository: any BillingDocumentLocalRepository
    private let contentBuilder: any BillingEmailContentBuilder
    private let access: BillingAssetAccess

    /// Prepares one immutable in-memory draft, rechecking authorization before publication and on read failures.
    func callAsFunction(requestID: BillingDocumentRequestID, recipient: String) async throws -> EmailDraft {
        try await authorize()
        do {
            let delivery = try await localRepository.delivery(id: requestID)
            try await authorize()
            guard let delivery else { throw BillingEmailError.documentNotFound }
            guard delivery.id == requestID, delivery.principalID == access.principalID else {
                throw BillingEmailError.invalidDraft
            }
            guard delivery.isFinal else { throw BillingEmailError.documentNotFinal }
            guard let document = delivery.document else { throw BillingEmailError.invalidDraft }
            let draft = try EmailDraft.prepared(
                delivery: delivery,
                recipient: recipient,
                content: contentBuilder.content(for: document)
            )
            try await authorize()
            return draft
        } catch {
            try await authorize()
            throw normalized(error)
        }
    }
}

private extension PrepareBillingEmailDraftUseCase {
    func authorize() async throws {
        do {
            try await access.validate()
            guard localRepository.principalID == access.principalID else { throw BillingEmailError.unauthorized }
        } catch {
            try Task.checkCancellation()
            if error is CancellationError {
                throw CancellationError()
            }
            throw BillingEmailError.unauthorized
        }
    }

    func normalized(_ error: any Error) -> any Error {
        switch error {
        case is CancellationError:
            CancellationError()
        case let error as BillingEmailError:
            error
        case BillingAssetError.unauthorized, BillingDocumentPersistenceError.unauthorized:
            BillingEmailError.unauthorized
        case BillingDocumentPersistenceError.conflict, BillingDocumentPersistenceError.invalidState:
            BillingEmailError.invalidDraft
        default:
            BillingEmailError.unavailable
        }
    }
}

extension PrepareBillingEmailDraftUseCase {
    init(
        local: any BillingDocumentLocalRepository,
        content: any BillingEmailContentBuilder,
        access: BillingAssetAccess
    ) {
        self.init(localRepository: local, contentBuilder: content, access: access)
    }
}
