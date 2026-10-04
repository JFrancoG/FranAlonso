import Foundation
import SwiftData
import Testing
@testable import FranAlonso

struct SaleClosureTestFixtures {
    static let principalID = "synthetic-principal-13-12"
    static let closedAt = Date(timeIntervalSince1970: 2_000.125)
    static let operationID = UUID(uuid: (0x13, 0x12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
    static let predecessorID = UUID(uuid: (0x13, 0x12, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2))

    static func command(_ document: BillingDocument, at date: Date = closedAt) throws -> SaleClosureRequest {
        try SaleClosureRequest(expected: document.request.sale, requestID: document.request.id, closedAt: date)
    }

    static func delivery(
        _ document: BillingDocument,
        checkpoint: BillingPersistenceCheckpoint = .pdf,
        principalID: String = SaleClosureTestFixtures.principalID
    ) throws -> BillingDocumentDelivery {
        var delivery = try BillingDocumentDelivery(request: document.request, principalID: principalID)
        guard checkpoint != .prepared else { return delivery }
        try delivery.accept(document)
        guard checkpoint != .numbered else { return delivery }
        try delivery.acceptPDF(billingPDFTemplate())
        guard checkpoint != .pdf else { return delivery }
        try delivery.beginUpload()
        guard checkpoint != .attempt else { return delivery }
        try delivery.completeUpload(.accepted(documentID: document.id, principalID: principalID))
        return delivery
    }

    static func closed(_ document: BillingDocument, at date: Date = closedAt) throws -> Sale {
        var sale = document.request.sale
        try sale.close(documentID: document.id, closedAt: date)
        return sale
    }

    static func container(at url: URL? = nil) throws -> ModelContainer {
        let schema = Schema.franAlonso
        guard let url else { return try ModelContainer.inMemory(for: schema) }
        let configuration = ModelConfiguration(schema: schema, url: url, cloudKitDatabase: .none)
        return try ModelContainer(for: schema, configurations: [configuration])
    }

    static func seed(
        _ document: BillingDocument,
        checkpoint: BillingPersistenceCheckpoint = .pdf,
        in context: ModelContext
    ) throws {
        context.autosaveEnabled = false
        try SaleLocalDataSource().upsert(document.request.sale, in: context)
        context.insert(try BillingDocumentDeliveryModel(delivery(document, checkpoint: checkpoint)))
        try context.save()
    }

    static func close(
        _ document: BillingDocument,
        at date: Date = closedAt,
        source: SaleLocalDataSource = SaleLocalDataSource(),
        in context: ModelContext
    ) throws -> Sale {
        try source.closeSale(
            command(document, at: date),
            principalID: principalID,
            operationID: operationID,
            in: context
        )
    }

    static func source(
        save: @escaping @Sendable (ModelContext) throws -> Void
    ) -> SaleLocalDataSource {
        SaleLocalDataSource(
            closureSave: save,
            paymentSave: {
                try $0.save()
            },
            reversalSave: {
                try $0.save()
            }
        )
    }

    static func persistedDeliveries(in context: ModelContext) throws -> [UUID: Data] {
        Dictionary(uniqueKeysWithValues: try context.fetch(FetchDescriptor<BillingDocumentDeliveryModel>()).map {
            ($0.id, $0.payload)
        })
    }

    static func replacingPayment(_ sale: Sale) throws -> Sale {
        let original = try SaleDTO(sale)
        let payment = SalePaymentDTO(
            id: "13120000-0000-0000-0000-000000000003",
            method: .card,
            paidAt: original.createdAt
        )
        return try SaleDTO(
            payloadVersion: original.payloadVersion,
            id: original.id,
            clientID: original.clientID,
            createdAt: original.createdAt,
            lines: original.lines,
            status: .awaitingDocument(payment: payment),
            globalDiscount: original.globalDiscount
        ).toDomain()
    }

    static func replacingID(_ sale: Sale) throws -> Sale {
        let original = try SaleDTO(sale)
        return try SaleDTO(
            payloadVersion: original.payloadVersion,
            id: "13120000-0000-0000-0000-000000000004",
            clientID: original.clientID,
            createdAt: original.createdAt,
            lines: original.lines,
            status: original.status,
            globalDiscount: original.globalDiscount
        ).toDomain()
    }

    static func repository(
        _ container: ModelContainer,
        signal: SaleObservationSignal = SaleObservationSignal()
    ) -> DefaultSaleRepository {
        DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: signal,
            operationID: { operationID }
        )
    }
}

actor SaleClosureControlledRepository: SaleRepository {
    private let base = InMemorySaleRepository()
    private let accepted: Sale
    private let failure: (any Error)?
    private let pause: BillingStoragePause?
    private let local: DefaultSaleRepository?
    private(set) var commands: [SaleClosureRequest] = []
    private(set) var principals: [String] = []
    private(set) var freeSaveCount = 0

    init(
        accepted: Sale,
        failure: (any Error)? = nil,
        pause: BillingStoragePause? = nil,
        local: DefaultSaleRepository? = nil
    ) {
        self.accepted = accepted
        self.failure = failure
        self.pause = pause
        self.local = local
    }

    func closeSale(_ request: SaleClosureRequest, principalID: String) async throws -> Sale {
        commands.append(request)
        principals.append(principalID)
        let result = try await local?.closeSale(request, principalID: principalID) ?? accepted
        if let pause {
            await pause.wait()
        }
        if let failure {
            throw failure
        }
        return result
    }

    func observeSales() async -> AsyncThrowingStream<[Sale], any Error> {
        await base.observeSales()
    }

    func sale(id: SaleID) async throws -> Sale? {
        try await base.sale(id: id)
    }

    func createDraft(_ draft: Sale) async throws {
        try await base.createDraft(draft)
    }

    func discardDraft(_ id: SaleID) async throws {
        try await base.discardDraft(id)
    }

    func saveSale(_ sale: Sale) async throws {
        freeSaveCount += 1
        try await base.saveSale(sale)
    }

    func updateDraft(
        _ expected: Sale,
        clientID: ClientID?,
        lines: [SaleLine],
        globalDiscount: SaleGlobalDiscount?
    ) async throws -> Sale {
        try await base.updateDraft(
            expected,
            clientID: clientID,
            lines: lines,
            globalDiscount: globalDiscount
        )
    }

    func registerPayment(
        _ expected: Sale,
        id paymentID: PaymentID,
        method: PaymentMethod,
        paidAt: Date
    ) async throws -> Sale {
        try await base.registerPayment(
            expected,
            id: paymentID,
            method: method,
            paidAt: paidAt
        )
    }
}

enum SaleClosureCommitFailure: Error {
    case detailedFailure, unexpectedSave
}
