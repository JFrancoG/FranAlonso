import Foundation
import SwiftData
import Testing
@testable import FranAlonso

struct BillingMaterializationPersistenceFixtures {
    static let principalID = "synthetic-principal-13-10"

    static func document(kind: BillingDocumentKind = .invoice) throws -> BillingDocument {
        try billingRenderingDocument(kind: kind)
    }

    static func receipt(_ document: BillingDocument) -> BillingPDFUploadReceipt {
        .accepted(documentID: document.id, principalID: principalID)
    }

    static func container(at url: URL? = nil) throws -> ModelContainer {
        let schema = Schema([BillingDocumentDeliveryModel.self])
        guard let url else { return try ModelContainer.inMemory(for: schema) }
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func repository(
        _ container: ModelContainer,
        access: BillingAssetAccess? = nil
    ) -> DefaultBillingDocumentLocalRepository {
        DefaultBillingDocumentLocalRepository(
            persistence: BillingDocumentPersistenceActor(modelContainer: container),
            access: access ?? billingStorageAccess(principalID: principalID)
        )
    }

    static func temporaryDirectory() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory
    }

    @MainActor
    static func persisted(_ container: ModelContainer) throws -> [BillingDocumentDelivery] {
        try ModelContext(container).fetch(FetchDescriptor<BillingDocumentDeliveryModel>()).map {
            try $0.toDomain()
        }
    }

    static func advance(
        _ repository: some BillingDocumentLocalRepository,
        to checkpoint: BillingPersistenceCheckpoint,
        document: BillingDocument,
        pdf: Data
    ) async throws -> BillingDocumentDelivery {
        var delivery = try await repository.prepare(document.request)
        guard checkpoint != .prepared else { return delivery }
        delivery = try await repository.accept(document)
        guard checkpoint != .numbered else { return delivery }
        delivery = try await repository.acceptPDF(id: document.request.id, pdf: pdf)
        guard checkpoint != .pdf else { return delivery }
        delivery = try await repository.beginUpload(id: document.request.id)
        guard checkpoint != .attempt else { return delivery }
        return try await repository.completeUpload(id: document.request.id, receipt: receipt(document))
    }

    static func write(
        at url: URL,
        checkpoint: BillingPersistenceCheckpoint,
        document: BillingDocument,
        pdf: Data
    ) async throws -> BillingDocumentDelivery {
        try await advance(
            repository(container(at: url)),
            to: checkpoint,
            document: document,
            pdf: pdf
        )
    }
}

enum BillingPersistenceCheckpoint: CaseIterable {
    case prepared, numbered, pdf, attempt, final
}

enum BillingPersistenceSaveStep: CaseIterable {
    case prepare, number, pdf, attempt, receipt, failure

    var priorCheckpoint: BillingPersistenceCheckpoint? {
        switch self {
        case .prepare: nil
        case .number, .failure: .prepared
        case .pdf: .numbered
        case .attempt: .pdf
        case .receipt: .attempt
        }
    }

    func apply(to repository: some BillingDocumentLocalRepository, document: BillingDocument, pdf: Data) async throws {
        switch self {
        case .prepare:
            _ = try await repository.prepare(document.request)
        case .number:
            _ = try await repository.accept(document)
        case .pdf:
            _ = try await repository.acceptPDF(id: document.request.id, pdf: pdf)
        case .attempt:
            _ = try await repository.beginUpload(id: document.request.id)
        case .receipt:
            _ = try await repository.completeUpload(
                id: document.request.id,
                receipt: BillingMaterializationPersistenceFixtures.receipt(document)
            )
        case .failure:
            try await repository.recordFailure(
                id: document.request.id,
                phase: .numbering,
                reason: .unavailable,
                attempt: nil
            )
        }
    }
}

enum BillingPersistenceEnvelopeDamage: CaseIterable {
    case version, payload, requestID, documentID, saleID, kind, principal

    func apply(to model: BillingDocumentDeliveryModel) {
        switch self {
        case .version: model.payloadVersion = 42
        case .payload: model.payload = Data("invalid persisted envelope".utf8)
        case .requestID: model.id = UUID()
        case .documentID: model.documentID = UUID()
        case .saleID: model.saleID = UUID()
        case .kind: model.kind = "invalid-kind"
        case .principal: model.principalID = "mismatched-principal"
        }
    }
}

enum BillingPersistenceRequestMutation: CaseIterable {
    case requestID, documentID, requestedAt, paidSale, fiscalRecipient

    func request(_ document: BillingDocument) throws -> BillingDocumentRequest {
        let original = document.request
        let sale = try self == .paidSale
            ? billingRenderingDocument(name: "Changed sealed service").request.sale : original.sale
        return try BillingDocumentRequest(
            id: self == .requestID ? BillingDocumentRequestID(rawValue: UUID()) : original.id,
            documentID: self == .documentID ? BillingDocumentID(rawValue: UUID()) : original.documentID,
            sale: sale,
            kind: original.kind,
            requestedAt: self == .requestedAt ? original.requestedAt.addingTimeInterval(1) : original.requestedAt,
            fiscalRecipient: self == .fiscalRecipient ? BillingFiscalRecipient(BillingFiscalRecipientInput(
                displayName: "Changed synthetic recipient",
                taxIdentifier: "DEMO-NIF-1310",
                streetLine: "Synthetic street 10",
                postalCode: "28010",
                city: "Synthetic city",
                province: "Synthetic province"
            )) : original.fiscalRecipient
        )
    }
}

actor BillingPersistencePermit {
    private var checkCount = 0
    private var isAuthorized = true
    private let revokeOnCheck: Int?

    init(revokeOnCheck: Int? = nil) {
        self.revokeOnCheck = revokeOnCheck
    }

    func validate() throws {
        checkCount += 1
        if checkCount == revokeOnCheck {
            isAuthorized = false
        }
        guard isAuthorized else { throw BillingAssetError.unauthorized }
    }

    func revoke() {
        isAuthorized = false
    }
}
