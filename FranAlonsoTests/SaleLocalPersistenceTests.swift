import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale local persistence")
struct SaleLocalPersistenceTests {
    @Test("The flat model preserves a terminal snapshot and every exact timestamp")
    func flatModelPreservesTerminalSnapshotAndExactTimestamps() throws {
        let sale = try persistentSale(status: .voided)

        let model = try SaleModel(sale)
        let reconstructed = try model.toDomain()

        #expect(reconstructed == sale)
        #expect(
            reconstructed.createdAt.timeIntervalSinceReferenceDate.bitPattern
                == sale.createdAt.timeIntervalSinceReferenceDate.bitPattern
        )
        #expect(model.statusKindRawValue == "voided")
        #expect(model.paymentID != nil)
        #expect(model.documentID != nil)
        #expect(model.reversalID != nil)
        #expect(model.linesPayloadVersion == 1)
        #expect(try JSONDecoder().decode([SaleLineDTO].self, from: model.linesData).count == 2)
    }

    @Test("An unsupported lines payload version fails before Domain reconstruction")
    func unsupportedLinesPayloadVersionFailsClosed() throws {
        let model = try SaleModel(persistentSale(status: .draft))
        model.linesPayloadVersion = 2

        #expect(throws: SaleModelPayloadError.unsupportedLinesVersion(2)) {
            _ = try model.toDomain()
        }
    }

    @Test("The queryable creation date must match its exact canonical value")
    func queryableCreationDateMustMatchCanonicalValue() throws {
        let model = try SaleModel(persistentSale(status: .draft))
        model.createdAt = Date(timeIntervalSinceReferenceDate: 2)

        #expect(throws: SaleModelPayloadError.invalidLifecycleMetadata) {
            _ = try model.toDomain()
        }
    }

    @Test("Negative-zero creation dates persist in their canonical positive form")
    func negativeZeroCreationDatePersistsCanonically() throws {
        let sale = try persistentSale(
            status: .draft,
            createdAt: Date(timeIntervalSinceReferenceDate: -0.0)
        )
        let model = try SaleModel(sale)

        #expect(
            model.createdAt.timeIntervalSinceReferenceDate.bitPattern
                == 0.0.bitPattern
        )
        #expect(model.createdAtCanonical == "0000000000000000")
        #expect(try model.toDomain() == sale)

        let container = try salePersistenceContainer()
        let context = ModelContext(container)
        let source = SaleLocalDataSource()
        try source.persistPendingUpsert(
            sale,
            operationID: salePersistenceUUID(
                "10000000-0000-0000-0000-000000000005"
            ),
            in: context
        )

        let persisted = try #require(
            context.fetch(FetchDescriptor<SaleModel>()).first
        )
        #expect(
            persisted.createdAt.timeIntervalSinceReferenceDate.bitPattern
                == 0.0.bitPattern
        )
        #expect(try source.fetchAll(in: context) == [sale])
    }

    @Test("Every pending upsert base requires its explicit v1 envelope")
    func pendingUpsertBaseRequiresExplicitV1Envelope() throws {
        let sale = try persistentSale(status: .draft)
        let payload = try JSONEncoder().encode(SaleDTO(sale))
        let encodedAbsent = try JSONEncoder().encode(SaleRemoteBase.absent)
        let complete = try SalePendingUpsertModel(
            saleID: sale.id.rawValue,
            operationID: salePersistenceUUID(
                "10000000-0000-0000-0000-000000000006"
            ),
            base: .absent,
            payload: SaleDTO(sale)
        )
        let missing = SalePendingUpsertModel(
            saleID: sale.id.rawValue,
            operationID: salePersistenceUUID(
                "10000000-0000-0000-0000-000000000007"
            ),
            predecessorOperationID: nil,
            baseVersion: nil,
            baseData: nil,
            payloadVersion: 1,
            payloadData: payload
        )
        let partial = SalePendingUpsertModel(
            saleID: sale.id.rawValue,
            operationID: salePersistenceUUID(
                "10000000-0000-0000-0000-000000000008"
            ),
            predecessorOperationID: nil,
            baseVersion: 1,
            baseData: nil,
            payloadVersion: 1,
            payloadData: payload
        )
        let unsupported = SalePendingUpsertModel(
            saleID: sale.id.rawValue,
            operationID: salePersistenceUUID(
                "10000000-0000-0000-0000-000000000009"
            ),
            predecessorOperationID: nil,
            baseVersion: 2,
            baseData: encodedAbsent,
            payloadVersion: 1,
            payloadData: payload
        )

        #expect(complete.baseVersion == 1)
        #expect(complete.baseData != nil)
        #expect(try complete.decodeBase() == .absent)
        #expect(throws: SalePendingUpsertPayloadError.incompleteBaseMetadata) {
            _ = try missing.decodeBase()
        }
        #expect(throws: SalePendingUpsertPayloadError.incompleteBaseMetadata) {
            _ = try partial.decodeBase()
        }
        #expect(throws: SalePendingUpsertPayloadError.unsupportedBaseVersion(2)) {
            _ = try unsupported.decodeBase()
        }

        let container = try salePersistenceContainer()
        let context = ModelContext(container)
        context.insert(missing)
        try context.save()
        #expect(throws: SalePendingUpsertPayloadError.incompleteBaseMetadata) {
            _ = try SaleLocalDataSource().pendingOperations(in: context)
        }
    }

    @Test("Local edits form a causal chain and only a draft can be discarded")
    func localEditsFormCausalChainAndOnlyDraftCanBeDiscarded() throws {
        let container = try salePersistenceContainer()
        let source = SaleLocalDataSource()
        let first = try persistentSale(status: .draft, serviceName: "Original")
        let second = try persistentSale(status: .draft, serviceName: "Edited")
        let firstOperationID = salePersistenceUUID("10000000-0000-0000-0000-000000000001")
        let secondOperationID = salePersistenceUUID("10000000-0000-0000-0000-000000000002")
        let discardOperationID = salePersistenceUUID("10000000-0000-0000-0000-000000000003")

        try source.persistPendingUpsert(
            first,
            operationID: firstOperationID,
            in: ModelContext(container)
        )
        try source.persistPendingUpsert(
            second,
            operationID: secondOperationID,
            in: ModelContext(container)
        )

        let operations = try source.pendingOperations(in: ModelContext(container))
        #expect(operations.map(\.operationID) == [firstOperationID, secondOperationID])
        #expect(operations[1].predecessorOperationID == firstOperationID)

        try source.persistPendingDiscard(
            second.id,
            operationID: discardOperationID,
            in: ModelContext(container)
        )
        let discarded = try source.pendingOperations(in: ModelContext(container))
        #expect(discarded.map(\.operationID) == [
            firstOperationID,
            secondOperationID,
            discardOperationID
        ])
        #expect(try source.fetchAll(in: ModelContext(container)).isEmpty)

        let progressedContainer = try salePersistenceContainer()
        let progressed = try persistentSale(status: .inProgress)
        try source.upsert(progressed, in: ModelContext(progressedContainer))
        #expect(throws: SaleLocalDataSourceError.discardRequiresDraft(progressed.id)) {
            try source.persistPendingDiscard(
                progressed.id,
                operationID: salePersistenceUUID(
                    "10000000-0000-0000-0000-000000000004"
                ),
                in: ModelContext(progressedContainer)
            )
        }
        #expect(try source.fetchAll(in: ModelContext(progressedContainer)) == [progressed])
    }

    @Test("The application schema owns all seven Sale tables")
    func applicationSchemaOwnsAllSevenSaleTables() throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let context = ModelContext(container)

        #expect(try context.fetchCount(FetchDescriptor<SaleModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SalePendingDiscardModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleRemoteStateModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleSyncConflictModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleSyncCursorModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SaleSyncRetryModel>()) == 0)
    }

    @Test("Equal creation dates use stable Sale identity as their tie-breaker")
    func equalCreationDatesUseStableIdentityOrder() throws {
        let container = try salePersistenceContainer()
        let context = ModelContext(container)
        let source = SaleLocalDataSource()
        let sharedDate = Date(timeIntervalSinceReferenceDate: 50)
        let firstID = salePersistenceUUID(
            "20000000-0000-0000-0000-000000000101"
        )
        let secondID = salePersistenceUUID(
            "20000000-0000-0000-0000-000000000102"
        )
        let second = try persistentSale(
            status: .draft,
            serviceName: "Second",
            id: secondID,
            createdAt: sharedDate
        )
        let first = try persistentSale(
            status: .draft,
            serviceName: "First",
            id: firstID,
            createdAt: sharedDate
        )

        try source.upsert(second, in: context)
        try source.upsert(first, in: context)

        #expect(try source.fetchAll(in: context).map(\.id.rawValue) == [firstID, secondID])
    }

    @Test("A blocked draft discard retains the operation and progressed remote state")
    func blockedDraftDiscardRetainsBothSides() throws {
        let container = try salePersistenceContainer()
        let context = ModelContext(container)
        let source = SaleLocalDataSource()
        let draft = try persistentSale(status: .draft)
        let operationID = salePersistenceUUID("10000000-0000-0000-0000-000000000050")
        let remoteOperationID = salePersistenceUUID(
            "10000000-0000-0000-0000-000000000051"
        )

        try source.upsert(draft, in: context)
        try source.persistPendingDiscard(
            draft.id,
            operationID: operationID,
            in: context
        )
        let operation = try #require(source.pendingOperations(in: context).last)
        let remoteRecord = SaleRemoteRecord(
            sale: try SaleDTO(persistentSale(status: .inProgress)),
            version: .versioned(revision: 2, lastOperationID: remoteOperationID),
            changeSequence: 4
        )

        try source.recordConflict(
            operation: operation,
            reason: .discardRequiresDraft,
            remoteRecord: remoteRecord,
            in: context
        )

        let conflict = try #require(
            context.fetch(FetchDescriptor<SaleSyncConflictModel>()).first
        )
        #expect(try conflict.decodeOperation() == operation)
        #expect(try conflict.decodeLocalSale() == nil)
        #expect(try conflict.decodeRemoteRecord() == remoteRecord)
        #expect(try source.deliverablePendingOperations(in: context).isEmpty)
    }

    @MainActor
    @Test("The contextual adapter matches repository persistence and observation")
    func contextualAdapterMatchesRepositoryPersistence() async throws {
        let container = try salePersistenceContainer()
        let signal = SaleObservationSignal()
        let repository = DefaultSaleRepository(
            persistenceActor: SalePersistenceActor(modelContainer: container),
            observationSignal: signal
        )
        let adapter = SaleContextualPersistenceAdapter(
            observationSignal: signal,
            operationID: {
                salePersistenceUUID("10000000-0000-0000-0000-000000000099")
            }
        )
        let sale = try persistentSale(status: .draft)
        let stream = await repository.observeSales()
        var observation = stream.makeAsyncIterator()
        #expect(try await observation.next() == [])

        try await adapter.save(sale, in: container.mainContext)

        #expect(try await observation.next() == [sale])
        #expect(
            try ModelContext(container).fetchCount(
                FetchDescriptor<SalePendingUpsertModel>()
            ) == 1
        )
    }
}

private enum PersistentSaleStatus: Equatable {
    case draft
    case inProgress
    case voided
}

private func persistentSale(
    status: PersistentSaleStatus,
    serviceName: String = "Snapshot",
    id: UUID = salePersistenceUUID("20000000-0000-0000-0000-000000000006"),
    createdAt: Date = Date(timeIntervalSinceReferenceDate: 0.000_000_123_456_789)
) throws -> Sale {
    let firstLine = try SaleLine.upcoming(
        id: SaleLineID(rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000001")),
        serviceID: ServiceID(rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000002")),
        serviceName: serviceName,
        quantity: 1,
        unitPrice: Money(amount: 29.95, currency: .eur),
        taxRate: TaxRate(percentage: 21),
        discount: Discount(percentage: 10),
        linkedProductID: nil
    )
    let secondLine = try SaleLine.upcoming(
        id: SaleLineID(rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000003")),
        serviceID: ServiceID(rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000004")),
        serviceName: "Second",
        quantity: 2,
        unitPrice: Money(amount: 10, currency: .usd),
        taxRate: TaxRate(percentage: 8.5),
        discount: nil,
        linkedProductID: ProductID(
            rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000005")
        )
    )
    var sale = try Sale.draft(
        id: SaleID(rawValue: id),
        clientID: ClientID(rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000007")),
        createdAt: createdAt,
        lines: [firstLine, secondLine]
    )
    guard status != .draft else { return sale }

    try sale.start()
    try sale.startLine(id: firstLine.id)
    guard status != .inProgress else { return sale }

    try sale.completeLine(id: firstLine.id)
    try sale.startLine(id: secondLine.id)
    try sale.completeLine(id: secondLine.id)
    try sale.registerPayment(
        id: PaymentID(rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000008")),
        method: .card,
        paidAt: Date(timeIntervalSinceReferenceDate: 0.000_000_223_456_789)
    )
    try sale.close(
        documentID: BillingDocumentID(
            rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000009")
        ),
        closedAt: Date(timeIntervalSinceReferenceDate: 0.000_000_323_456_789)
    )
    try sale.void(
        reversalID: SaleReversalID(
            rawValue: salePersistenceUUID("20000000-0000-0000-0000-000000000010")
        ),
        voidedAt: Date(timeIntervalSinceReferenceDate: 0.000_000_423_456_789)
    )
    return sale
}

private func salePersistenceContainer() throws -> ModelContainer {
    try ModelContainer.inMemory(
        for: Schema([
            SaleModel.self,
            SalePendingUpsertModel.self,
            SalePendingDiscardModel.self,
            SaleRemoteStateModel.self,
            SaleSyncConflictModel.self,
            SaleSyncCursorModel.self,
            SaleSyncRetryModel.self
        ])
    )
}

private func salePersistenceUUID(_ value: String) -> UUID {
    UUID(uuidString: value)!
}
