import Foundation
import SwiftData
import Testing
@testable import FranAlonso

struct BillingEmailDraftFixtures {
    static let recipient = "synthetic-recipient@example.invalid"
    static let content = BillingEmailContent(subject: "Synthetic document", body: "Synthetic attachment for review.")
    static let principalID = BillingMaterializationPersistenceFixtures.principalID

    static func finalDelivery(kind: BillingDocumentKind = .ticket) async throws -> BillingDocumentDelivery {
        let container = try BillingMaterializationPersistenceFixtures.container()
        return try await BillingMaterializationPersistenceFixtures.advance(
            BillingMaterializationPersistenceFixtures.repository(container),
            to: .final,
            document: billingRenderingDocument(kind: kind),
            pdf: billingPDFTemplate()
        )
    }

    static func preparer(
        local: any BillingDocumentLocalRepository,
        language: String = "es",
        access: BillingAssetAccess? = nil
    ) -> PrepareBillingEmailDraftUseCase {
        PrepareBillingEmailDraftUseCase(
            local: local,
            content: LocalizedBillingEmailContentBuilder(bundle: .main, locale: Locale(identifier: language)),
            access: access ?? billingStorageAccess(principalID: principalID)
        )
    }

    @MainActor
    static func writeAndRelease(
        at url: URL,
        document: BillingDocument,
        pdf: Data,
        probe: BillingEmailDraftDiskOwnerProbe
    ) async throws -> BillingDocumentDelivery {
        let container = try BillingMaterializationPersistenceFixtures.container(at: url)
        probe.container = container
        return try await BillingMaterializationPersistenceFixtures.advance(
            BillingMaterializationPersistenceFixtures.repository(container),
            to: .final,
            document: document,
            pdf: pdf
        )
    }
}

@MainActor
final class BillingEmailDraftDiskOwnerProbe {
    weak var container: ModelContainer?
}

enum BillingEmailDraftReadFailure: Error {
    case providerDetails
}

actor BillingEmailDraftReadRepository: BillingDocumentLocalRepository {
    let principalID: String
    private let base: DefaultBillingDocumentLocalRepository?
    private let supplied: BillingDocumentDelivery?
    private let pause: BillingStoragePause?
    private let fails: Bool
    private(set) var readCount = 0
    private(set) var writeCount = 0

    init(
        principalID: String = BillingEmailDraftFixtures.principalID,
        base: DefaultBillingDocumentLocalRepository? = nil,
        supplied: BillingDocumentDelivery? = nil,
        pause: BillingStoragePause? = nil,
        fails: Bool = false
    ) {
        self.principalID = principalID
        self.base = base
        self.supplied = supplied
        self.pause = pause
        self.fails = fails
    }

    func delivery(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery? {
        readCount += 1
        let result = try await base?.delivery(id: id) ?? supplied
        if let pause {
            await pause.wait()
        }
        if fails {
            throw BillingEmailDraftReadFailure.providerDetails
        }
        return result
    }

    func deliveries(saleID: SaleID) async throws -> [BillingDocumentDelivery] {
        throw BillingEmailDraftReadFailure.providerDetails
    }

    func prepare(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery {
        writeCount += 1
        throw BillingEmailDraftReadFailure.providerDetails
    }

    func accept(_ document: BillingDocument) async throws -> BillingDocumentDelivery {
        writeCount += 1
        throw BillingEmailDraftReadFailure.providerDetails
    }

    func acceptPDF(id: BillingDocumentRequestID, pdf: Data) async throws -> BillingDocumentDelivery {
        writeCount += 1
        throw BillingEmailDraftReadFailure.providerDetails
    }

    func beginUpload(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery {
        writeCount += 1
        throw BillingEmailDraftReadFailure.providerDetails
    }

    func completeUpload(
        id: BillingDocumentRequestID,
        receipt: BillingPDFUploadReceipt
    ) async throws -> BillingDocumentDelivery {
        writeCount += 1
        throw BillingEmailDraftReadFailure.providerDetails
    }

    func recordFailure(
        id: BillingDocumentRequestID,
        phase: BillingDocumentDeliveryPhase,
        reason: BillingDocumentFailure,
        attempt: Int?
    ) async throws {
        writeCount += 1
        throw BillingEmailDraftReadFailure.providerDetails
    }
}

struct BillingEmailDraftPayload: Codable {
    var contents: Contents

    struct Contents: Codable {
        var document: BillingDocument
        var principalID: String
        var receipt: BillingPDFUploadReceipt
        var pdf: Data
        var recipient: String
        var content: BillingEmailContent
    }

    static func final(_ delivery: BillingDocumentDelivery) throws -> BillingEmailDraftPayload {
        BillingEmailDraftPayload(contents: Contents(
            document: try #require(delivery.document),
            principalID: delivery.principalID,
            receipt: try #require(delivery.receipt),
            pdf: try #require(delivery.pdf),
            recipient: BillingEmailDraftFixtures.recipient,
            content: BillingEmailDraftFixtures.content
        ))
    }
}

enum BillingEmailDraftPayloadDamage: CaseIterable {
    case principal, receiptDocument, receiptPath, emptyPDF, oversizedPDF, recipient, subject, body

    func apply(to payload: inout BillingEmailDraftPayload) throws {
        switch self {
        case .principal:
            payload.contents.principalID = "another-synthetic-principal"
        case .receiptDocument:
            let foreignID = try #require(UUID(uuidString: "13110000-0000-0000-0000-000000000999"))
            payload.contents.receipt = .accepted(
                documentID: BillingDocumentID(rawValue: foreignID),
                principalID: payload.contents.principalID
            )
        case .receiptPath:
            payload.contents.receipt = BillingPDFUploadReceipt(
                documentID: payload.contents.document.id,
                principalID: payload.contents.principalID,
                objectPath: "unrelated/attachment.pdf"
            )
        case .emptyPDF:
            payload.contents.pdf = Data()
        case .oversizedPDF:
            payload.contents.pdf = Data(repeating: 32, count: 33_554_433)
        case .recipient:
            payload.contents.recipient = "synthetic@example.invalid\r\nBcc: other@example.invalid"
        case .subject:
            payload.contents.content = BillingEmailContent(subject: "Document\nBcc: other", body: "Synthetic body.")
        case .body:
            payload.contents.content = BillingEmailContent(subject: "Document", body: " ")
        }
    }

    var expectedError: BillingEmailError {
        switch self {
        case .recipient: .invalidRecipient
        case .subject, .body: .invalidContent
        default: .invalidDraft
        }
    }
}
