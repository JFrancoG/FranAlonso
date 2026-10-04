import Foundation

/// A recoverable local checkpoint; only a retained PDF and correlated durable receipt make it final.
struct BillingDocumentDelivery: Identifiable, Codable, Equatable {
    private var contents: Contents

    var id: BillingDocumentRequestID { allocation.request.id }
    var principalID: String { contents.principalID }
    var allocation: BillingDocumentLocalState { contents.allocation }
    var request: BillingDocumentRequest { allocation.request }
    var document: BillingDocument? { allocation.document }
    var pdf: Data? { contents.pdf }
    var uploadAttempts: Int { contents.uploadAttempts }
    var receipt: BillingPDFUploadReceipt? { contents.receipt }
    var failure: BillingDocumentDeliveryFailure? { contents.failure }
    var isFinal: Bool { receipt != nil }
    var phase: BillingDocumentDeliveryPhase {
        if document == nil {
            return .numbering
        }
        return pdf == nil ? .rendering : .upload
    }

    /// Confirms the full captured request once; changed numbered replay is a conflict.
    mutating func accept(_ document: BillingDocument) throws {
        do {
            let alreadyNumbered = self.document != nil
            try contents.allocation.accept(document)
            if !alreadyNumbered {
                contents.failure = nil
            }
        } catch {
            throw BillingDocumentPersistenceError.conflict
        }
    }

    /// Retains bounded nonempty bytes once; Data additionally validates their PDF structure before saving.
    mutating func acceptPDF(_ pdf: Data) throws {
        if let accepted = contents.pdf {
            guard accepted == pdf else { throw BillingDocumentPersistenceError.conflict }
            return
        }
        guard document != nil, !pdf.isEmpty, pdf.count <= 33_554_432 else {
            throw BillingDocumentPersistenceError.invalidState
        }
        contents.pdf = pdf
        contents.failure = nil
    }

    /// Advances one durable attempt before Storage contact; a final replay does not increment it.
    mutating func beginUpload() throws {
        guard !isFinal else { return }
        guard document != nil, pdf != nil, uploadAttempts < Int.max else {
            throw BillingDocumentPersistenceError.invalidState
        }
        contents.uploadAttempts += 1
        contents.failure = nil
    }

    /// Makes a confirmed document and its PDF final only with the principal's canonical correlated receipt.
    mutating func completeUpload(_ receipt: BillingPDFUploadReceipt) throws {
        guard let document, pdf != nil, uploadAttempts > 0 else { throw BillingDocumentPersistenceError.invalidState }
        guard receipt.matches(documentID: document.id, principalID: principalID) else {
            throw BillingDocumentPersistenceError.conflict
        }
        if let accepted = contents.receipt {
            guard receipt == accepted else { throw BillingDocumentPersistenceError.conflict }
            return
        }
        contents.receipt = receipt
        contents.failure = nil
    }

    /// Retains a current-stage failure without demoting a later phase, attempt or final acceptance.
    mutating func recordFailure(
        phase: BillingDocumentDeliveryPhase,
        reason: BillingDocumentFailure,
        attempt: Int?
    ) throws {
        guard !isFinal, phase == self.phase else { return }
        if phase == .upload {
            guard let attempt, attempt > 0, attempt <= uploadAttempts else {
                throw BillingDocumentPersistenceError.invalidState
            }
            guard attempt == uploadAttempts else { return }
        } else {
            guard attempt == nil else { throw BillingDocumentPersistenceError.invalidState }
        }
        if phase == .numbering {
            try contents.allocation.failNumbering(reason: reason)
        }
        contents.failure = BillingDocumentDeliveryFailure(phase: phase, reason: reason)
    }

    private struct Contents: Codable, Equatable {
        let principalID: String
        var allocation: BillingDocumentLocalState
        var pdf: Data?
        var uploadAttempts: Int
        var receipt: BillingPDFUploadReceipt?
        var failure: BillingDocumentDeliveryFailure?
    }
}

extension BillingDocumentDelivery {
    init(request: BillingDocumentRequest, principalID: String) throws {
        guard !principalID.isEmpty else { throw BillingDocumentPersistenceError.unauthorized }
        self.init(contents: Contents(
            principalID: principalID,
            allocation: .pendingNumber(request),
            pdf: nil,
            uploadAttempts: 0,
            receipt: nil,
            failure: nil
        ))
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let contents = try container.decode(Contents.self, forKey: .contents)
        self.init(contents: contents)
        try validate()
    }
}

private extension BillingDocumentDelivery {
    enum CodingKeys: String, CodingKey {
        case contents
    }

    func validate() throws {
        guard !principalID.isEmpty, uploadAttempts >= 0 else { throw BillingDocumentPersistenceError.invalidState }
        if let pdf {
            guard document != nil, !pdf.isEmpty, pdf.count <= 33_554_432 else {
                throw BillingDocumentPersistenceError.invalidState
            }
        } else {
            guard uploadAttempts == 0, receipt == nil else { throw BillingDocumentPersistenceError.invalidState }
        }
        if let receipt {
            guard let document, pdf != nil, uploadAttempts > 0, failure == nil,
                  receipt.matches(documentID: document.id, principalID: principalID) else {
                throw BillingDocumentPersistenceError.invalidState
            }
        }
        if let failure {
            guard failure.phase == phase, !isFinal else { throw BillingDocumentPersistenceError.invalidState }
            if phase == .upload {
                guard uploadAttempts > 0 else { throw BillingDocumentPersistenceError.invalidState }
            }
        }
        switch allocation {
        case .pendingNumber:
            guard failure == nil else { throw BillingDocumentPersistenceError.invalidState }
        case let .failed(_, reason):
            guard failure == BillingDocumentDeliveryFailure(phase: .numbering, reason: reason) else {
                throw BillingDocumentPersistenceError.invalidState
            }
        case .numbered:
            break
        }
    }
}

/// The last durable phase whose explicit retry can advance the same sealed request.
enum BillingDocumentDeliveryPhase: String, Codable, Equatable {
    case numbering, rendering, upload
}

/// A neutral failure cannot replace the captured artifact or remote acceptance.
struct BillingDocumentDeliveryFailure: Codable, Equatable {
    let phase: BillingDocumentDeliveryPhase
    let reason: BillingDocumentFailure
}

/// Provider-neutral local failures never expose persisted payloads or principal data.
enum BillingDocumentPersistenceError: Error, Equatable {
    case notFound, conflict, invalidState, unauthorized, persistenceUnavailable, ambiguousSelection
}
