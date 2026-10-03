import Foundation
import Testing
@testable import FranAlonso

func billingStorageAccess(principalID: String = "principal-A") -> BillingAssetAccess {
    BillingAssetAccess(principalID: principalID) {}
}

enum BillingStorageBindingMutation: CaseIterable {
    case number, issuedAt, requestID, requestedAt, kind, paidSale, fiscalRecipient, pdf

    func document(_ original: BillingDocument) throws -> BillingDocument {
        let request = original.request
        let alternativeID = try #require(UUID(uuidString: "13900000-0000-0000-0000-000000000001"))
        let kind: BillingDocumentKind = self == .kind ? .ticket : request.kind
        let sale = try self == .paidSale
            ? billingRenderingDocument(name: "Changed synthetic service").request.sale : request.sale
        let recipient = try kind == .ticket ? nil
            : self == .fiscalRecipient ? changedRecipient() : request.fiscalRecipient
        let captured = try BillingDocumentRequest(
            id: self == .requestID ? BillingDocumentRequestID(rawValue: alternativeID) : request.id,
            documentID: request.documentID,
            sale: sale,
            kind: kind,
            requestedAt: self == .requestedAt ? request.requestedAt.addingTimeInterval(1) : request.requestedAt,
            fiscalRecipient: recipient
        )
        return try BillingDocument.numbered(
            request: captured,
            number: BillingDocumentNumber(series: kind.series, value: self == .number ? 92 : original.number.value),
            issuedAt: self == .issuedAt ? original.issuedAt.addingTimeInterval(1) : original.issuedAt
        )
    }

    private func changedRecipient() throws -> BillingFiscalRecipient {
        try BillingFiscalRecipient(BillingFiscalRecipientInput(
            displayName: "Changed synthetic fiscal recipient",
            taxIdentifier: "DEMO-NIF-139",
            streetLine: "Synthetic street 139",
            postalCode: "28000",
            city: "Synthetic city",
            province: "Synthetic province"
        ))
    }
}

enum BillingStorageAcceptedBudget: CaseIterable {
    case pages, bytes

    func preparedPDF() throws -> Data {
        if self == .pages {
            return try billingPDFTemplate(pageCount: 100)
        }
        var data = try billingPDFTemplate()
        data.append(Data(repeating: 32, count: 33_554_432 - data.count))
        return data
    }
}

enum BillingStorageInvalidPDF: CaseIterable {
    case empty, corrupt, truncated, oversized, tooManyPages

    func bytes() throws -> Data {
        switch self {
        case .empty:
            Data()
        case .corrupt:
            Data("%PDF-1.7\nnot a parseable PDF\n%%EOF".utf8)
        case .truncated:
            Data(try billingPDFTemplate().dropLast(20))
        case .oversized:
            Data(repeating: 32, count: 33_554_433)
        case .tooManyPages:
            try billingPDFTemplate(pageCount: 101)
        }
    }
}

actor BillingStoragePermit {
    private var authorized = true

    func validate() throws {
        guard authorized else { throw BillingAssetError.unauthorized }
    }

    func revoke() {
        authorized = false
    }
}

actor BillingStoragePause {
    private var pending: CheckedContinuation<Void, Never>?
    private var arrivals: [CheckedContinuation<Bool, Never>] = []
    private var completed = false

    func wait() async {
        await withCheckedContinuation { continuation in
            pending = continuation
            for arrival in arrivals {
                arrival.resume(returning: true)
            }
            arrivals.removeAll()
        }
    }

    func waitUntilPausedOrCompleted() async -> Bool {
        if pending != nil {
            return true
        }
        if completed {
            return false
        }
        return await withCheckedContinuation { continuation in
            arrivals.append(continuation)
        }
    }

    func release() {
        pending?.resume()
        pending = nil
    }

    func complete() {
        completed = true
        for arrival in arrivals {
            arrival.resume(returning: false)
        }
        arrivals.removeAll()
    }
}

enum BillingStorageReceiptMutation: CaseIterable {
    case document, principal, path
}

enum BillingStorageProviderFailure: Error {
    case detailedProviderFailure
}

actor BillingStorageProbe: BillingDocumentPDFStorageRepository {
    private let alteration: BillingStorageReceiptMutation?
    private let failure: (any Error)?
    private let pause: BillingStoragePause?
    private(set) var uploadCount = 0
    private(set) var receivedDocument: BillingDocument?
    private(set) var receivedPDF: Data?

    init(
        alteration: BillingStorageReceiptMutation? = nil,
        failure: (any Error)? = nil,
        pause: BillingStoragePause? = nil
    ) {
        self.alteration = alteration
        self.failure = failure
        self.pause = pause
    }

    func upload(
        _ document: BillingDocument,
        pdf: Data,
        access: BillingAssetAccess
    ) async throws -> BillingPDFUploadReceipt {
        uploadCount += 1
        receivedDocument = document
        receivedPDF = pdf
        if let pause {
            await pause.wait()
        }
        if let failure {
            throw failure
        }
        let honest = BillingPDFUploadReceipt.accepted(documentID: document.id, principalID: access.principalID)
        return BillingPDFUploadReceipt(
            documentID: alteration == .document
                ? BillingDocumentID(rawValue: try #require(UUID(uuidString: "13900000-0000-0000-0000-000000000002")))
                : honest.documentID,
            principalID: alteration == .principal ? "principal-B" : honest.principalID,
            objectPath: alteration == .path ? "foreign/path.pdf" : honest.objectPath
        )
    }
}
