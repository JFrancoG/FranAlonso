/// A provider-neutral failure that retains the request for explicit recovery.
enum BillingDocumentFailure: String, Codable, Equatable {
    case unavailable
    case permissionDenied
    case conflict
}

/// Local allocation progress, kept separate from a confirmed remote document.
///
/// Pending and failed states contain no number. An infrastructure failure may occur
/// after a remote commit, so accepting a recovered result is also valid from failed.
enum BillingDocumentLocalState: Codable, Equatable {
    case pendingNumber(BillingDocumentRequest)
    case failed(BillingDocumentRequest, reason: BillingDocumentFailure)
    case numbered(BillingDocument)

    var request: BillingDocumentRequest {
        switch self {
        case let .pendingNumber(request), let .failed(request, _): request
        case let .numbered(document): document.request
        }
    }

    var document: BillingDocument? {
        switch self {
        case .pendingNumber, .failed: nil
        case let .numbered(document): document
        }
    }

    /// Retains the exact request after allocation fails; cannot demote confirmed allocation.
    /// - Throws: `BillingDocumentError.invalidLocalTransition` if already numbered.
    mutating func failNumbering(reason: BillingDocumentFailure) throws {
        guard document == nil else { throw BillingDocumentError.invalidLocalTransition }
        self = .failed(request, reason: reason)
    }

    /// Restores pending allocation without generating identifiers or refreshing sale terms.
    /// - Throws: `BillingDocumentError.invalidLocalTransition` if already numbered.
    mutating func retryNumbering() throws {
        guard document == nil else { throw BillingDocumentError.invalidLocalTransition }
        self = .pendingNumber(request)
    }

    /// Accepts the exact request's result; replaying an identical result is a no-op.
    /// - Throws: `BillingDocumentError.conflictingRequest` for changed input, or
    ///   `BillingDocumentError.conflictingDocument` for changed allocation after confirmation.
    mutating func accept(_ document: BillingDocument) throws {
        guard document.request == request else { throw BillingDocumentError.conflictingRequest }
        if let confirmed = self.document {
            guard confirmed == document else { throw BillingDocumentError.conflictingDocument }
            return
        }
        self = .numbered(document)
    }
}
