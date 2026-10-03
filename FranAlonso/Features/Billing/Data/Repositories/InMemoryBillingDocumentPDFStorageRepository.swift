import Foundation

/// An atomic simulated remote, independent of local repository lifetime.
///
/// Sharing RemoteStore recovers accepted values after repository recreation. Its behavior proves
/// this deterministic substitute only, not Firebase Storage authorization or production atomicity.
actor InMemoryBillingDocumentPDFStorageRepository: BillingDocumentPDFStorageRepository {
    enum Failure {
        case permissionDenied, unavailable, responseLost, cancelledBeforeAcceptance, cancelledAfterAcceptance
    }

    /// Owns simulated accepted documents and PDFs independently of any local repository.
    actor RemoteStore {
        private struct Key: Hashable {
            let principalID: String
            let documentID: BillingDocumentID
        }

        private struct Entry {
            let document: BillingDocument
            let pdf: Data
            let receipt: BillingPDFUploadReceipt
        }

        private var entries: [Key: Entry] = [:]
        var documentCount: Int { entries.count }

        func document(documentID: BillingDocumentID, principalID: String) -> BillingDocument? {
            entries[Key(principalID: principalID, documentID: documentID)]?.document
        }

        func pdf(documentID: BillingDocumentID, principalID: String) -> Data? {
            entries[Key(principalID: principalID, documentID: documentID)]?.pdf
        }

        func receipt(documentID: BillingDocumentID, principalID: String) -> BillingPDFUploadReceipt? {
            entries[Key(principalID: principalID, documentID: documentID)]?.receipt
        }

        /// Compares or creates without suspension; a conflicting replay never replaces accepted bytes.
        fileprivate func accept(
            _ document: BillingDocument,
            pdf: Data,
            principalID: String
        ) throws -> BillingPDFUploadReceipt {
            try Task.checkCancellation()
            let key = Key(principalID: principalID, documentID: document.id)
            if let accepted = entries[key] {
                guard accepted.document == document, accepted.pdf == pdf else { throw BillingPDFStorageError.conflict }
                try Task.checkCancellation()
                return accepted.receipt
            }
            let receipt = BillingPDFUploadReceipt.accepted(documentID: document.id, principalID: principalID)
            try Task.checkCancellation()
            entries[key] = Entry(document: document, pdf: pdf, receipt: receipt)
            return receipt
        }
    }

    private let remote: RemoteStore
    private var failures: [Failure]

    init(remote: RemoteStore = RemoteStore(), failures: [Failure] = []) {
        self.remote = remote
        self.failures = failures
    }

    func upload(
        _ document: BillingDocument,
        pdf: Data,
        access: BillingAssetAccess
    ) async throws -> BillingPDFUploadReceipt {
        do {
            try Task.checkCancellation()
            try await validateAccess(access)
            try BillingPDFUploadValidator.validate(pdf)
            let failure = failures.isEmpty ? nil : failures.removeFirst()
            switch failure {
            case .permissionDenied:
                throw BillingPDFStorageError.permissionDenied
            case .unavailable:
                throw BillingPDFStorageError.unavailable
            case .cancelledBeforeAcceptance:
                throw CancellationError()
            case .responseLost, .cancelledAfterAcceptance, nil:
                break
            }
            try await validateAccess(access)
            let receipt = try await remote.accept(document, pdf: pdf, principalID: access.principalID)
            try Task.checkCancellation()
            try await validateAccess(access)
            switch failure {
            case .responseLost:
                throw BillingPDFStorageError.unavailable
            case .cancelledAfterAcceptance:
                throw CancellationError()
            case .permissionDenied, .unavailable, .cancelledBeforeAcceptance, nil:
                return receipt
            }
        } catch {
            try Task.checkCancellation()
            if error is CancellationError {
                throw error
            }
            try await validateAccess(access)
            if let neutral = error as? BillingPDFStorageError {
                throw neutral
            }
            throw BillingPDFStorageError.unavailable
        }
    }
}

private extension InMemoryBillingDocumentPDFStorageRepository {
    func validateAccess(_ access: BillingAssetAccess) async throws {
        do {
            try await access.validate()
        } catch {
            try Task.checkCancellation()
            if error is CancellationError {
                throw error
            }
            throw BillingPDFStorageError.permissionDenied
        }
    }
}
