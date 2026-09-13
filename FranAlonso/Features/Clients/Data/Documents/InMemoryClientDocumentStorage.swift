import Foundation

/// A deterministic remote substitute. Sharing its remote store preserves accepted values across
/// repository recreation; it supplies no evidence of Firebase authorization or atomicity.
actor InMemoryClientDocumentStorage: ClientDocumentStorage {
    enum Failure {
        case permissionDenied
        case unavailable
        case responseLost
        case cancelledBeforeAcceptance
        case cancelledAfterAcceptance
    }

    /// Owns simulated remote state independently of any local persistence or repository lifetime.
    actor RemoteStore {
        private struct Key: Hashable {
            let principalID: String
            let documentID: UUID
        }

        private struct Entry {
            let document: ClientSignedDocument
            let receipt: ClientDocumentUploadReceipt
        }

        private var entries: [Key: Entry] = [:]
        var documentCount: Int { entries.count }

        func document(documentID: UUID, principalID: String) -> ClientSignedDocument? {
            entries[Key(principalID: principalID, documentID: documentID)]?.document
        }

        func receipt(documentID: UUID, principalID: String) -> ClientDocumentUploadReceipt? {
            entries[Key(principalID: principalID, documentID: documentID)]?.receipt
        }

        /// Comparison and creation have no suspension point, including when two repositories race.
        fileprivate func accept(
            _ document: ClientSignedDocument,
            principalID: String
        ) throws -> ClientDocumentUploadReceipt {
            try Task.checkCancellation()
            let key = Key(principalID: principalID, documentID: document.id)
            if let accepted = entries[key] {
                guard accepted.document == document else { throw ClientDocumentStorageError.conflict }
                return accepted.receipt
            }
            let reference = try ClientConsentReference(
                rawValue: "in-memory-document:\(principalID.utf8.count):\(principalID):\(document.id.uuidString)"
            )
            let receipt = ClientDocumentUploadReceipt(
                documentID: document.id,
                principalID: principalID,
                reference: reference
            )
            entries[key] = Entry(document: document, receipt: receipt)
            return receipt
        }
    }

    private let remote: RemoteStore
    private var failures: [Failure]

    init(remote: RemoteStore = RemoteStore(), failures: [Failure] = []) {
        self.remote = remote
        self.failures = failures
    }

    func upload(_ document: ClientSignedDocument, principalID: String) async throws -> ClientDocumentUploadReceipt {
        try Task.checkCancellation()
        let failure = failures.isEmpty ? nil : failures.removeFirst()
        switch failure {
        case .permissionDenied:
            throw ClientDocumentStorageError.permissionDenied
        case .unavailable:
            throw ClientDocumentStorageError.unavailable
        case .cancelledBeforeAcceptance:
            throw CancellationError()
        case .responseLost, .cancelledAfterAcceptance, nil:
            break
        }

        let receipt = try await remote.accept(document, principalID: principalID)
        try Task.checkCancellation()
        switch failure {
        case .responseLost:
            throw ClientDocumentStorageError.unavailable
        case .cancelledAfterAcceptance:
            throw CancellationError()
        case .permissionDenied, .unavailable, .cancelledBeforeAcceptance, nil:
            return receipt
        }
    }
}
