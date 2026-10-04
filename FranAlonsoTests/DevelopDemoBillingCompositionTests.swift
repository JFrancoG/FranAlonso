import Foundation
import PDFKit
import SwiftData
import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Reusable Develop billing and real local sale closure")
@MainActor
struct DevelopDemoBillingCompositionTests {
    @Test("synthetic reservation replays its complete record and keeps ticket and invoice series independent")
    func replaysSyntheticRecordsWithIndependentSeries() async throws {
        let repository = DevelopDemoBillingReservationRepository()
        let ticket = try billingRenderingDocument().request
        let invoiceSource = try billingRenderingDocument(kind: .invoice).request
        let invoice = try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: UUID()),
            documentID: BillingDocumentID(rawValue: UUID()),
            sale: invoiceSource.sale,
            kind: .invoice,
            requestedAt: invoiceSource.requestedAt,
            fiscalRecipient: invoiceSource.fiscalRecipient
        )
        let first = try await repository.reserve(ticket)
        let replay = try await repository.reserve(ticket)
        let independent = try await repository.reserve(invoice)
        #expect(first == replay)
        #expect(first.number.value == 900_001)
        #expect(independent.number.value == 950_001)
        #expect(first.number.series == .ticket)
        #expect(independent.number.series == .invoice)
        #expect(await repository.documentCount == 2)
    }

    @Test("synthetic authority rejects changed requests and document identity claims without consuming a number")
    func rejectsSyntheticClaimsWithoutConsumingNumber() async throws {
        let repository = DevelopDemoBillingReservationRepository()
        let request = try billingRenderingDocument().request
        let accepted = try await repository.reserve(request)
        let changed = try BillingDocumentRequest(
            id: request.id,
            documentID: request.documentID,
            sale: request.sale,
            kind: request.kind,
            requestedAt: request.requestedAt.addingTimeInterval(1)
        )
        let claiming = try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: UUID()),
            documentID: request.documentID,
            sale: request.sale,
            kind: request.kind,
            requestedAt: request.requestedAt
        )
        await #expect(throws: BillingDocumentReservationError.conflict) {
            try await repository.reserve(changed)
        }
        await #expect(throws: BillingDocumentReservationError.conflict) {
            try await repository.reserve(claiming)
        }
        #expect(try await repository.reserve(request) == accepted)
        #expect(await repository.documentCount == 1)
    }

    @Test(
        "every page of the real multipage PDF is visibly marked as a nonfiscal demonstration",
        arguments: [BillingDocumentKind.ticket, .invoice]
    )
    func marksEveryRealPDFPageAsNonfiscalDemo(_ kind: BillingDocumentKind) async throws {
        let lines = try (1...24).map {
            try billingRenderingLine(name: "Servicio DEMO \($0)", index: $0)
        }
        let document = try billingRenderingDocument(kind: kind, lines: lines)
        let projection = try BillingDocumentProjection(document: document)
        let plan = try await DevelopDemoBillingPDFComposer().compose(
            projection,
            template: BundleBillingDocumentTemplateRepository(bundle: .main).loadTemplate(for: kind),
            signature: nil
        )
        let bytes = try await CoreGraphicsBillingPDFRenderer().render(plan)
        try bytes.write(to: FileManager.default.temporaryDirectory.appendingPathComponent(
            "franalonso-13-12-demo-\(kind.rawValue).pdf"
        ))
        let pdf = try #require(PDFDocument(data: bytes))
        #expect(pdf.pageCount >= 3)
        for index in 0..<pdf.pageCount {
            let text = try #require(pdf.page(at: index)?.string)
            #expect(text.contains("DEMO / MUESTRA"))
            #expect(text.contains("SIN VALIDEZ FISCAL"))
        }
        #expect(plan.signature == nil)
    }

    @Test(
        "the manual demo accepts one closure and moves its observed operation from Workday to read-only History",
        arguments: [BillingDocumentKind.ticket, .invoice]
    )
    func acceptsOneDemoClosureAndMovesObservedWorkdayToHistory(_ kind: BillingDocumentKind) async throws {
        let session = try await DemoTestSession.make(configuration: .workday)
        defer {
            session.observation.cancel()
        }
        let composition = session.composition
        let dependencies = composition.dependencies
        let sale = SalesPreviewFixtures.workday.sales[5]
        let workday = dependencies.makeWorkday()
        let history = dependencies.makeSalesHistory()
        let workdayObservation = Task {
            await workday.load()
        }
        let historyObservation = Task {
            await history.load()
        }
        defer {
            workdayObservation.cancel()
            historyObservation.cancel()
        }
        await waitUntil {
            guard case let .content(board) = workday.state else { return false }
            return board.sales.contains { $0.id == sale.id }
        }
        workday.openSale(sale.id)
        let destination = try #require(workday.destination)
        let draft = dependencies.makeSaleDraft(destination)
        _ = try await draft.load()
        draft.presentBilling()
        let billingDestination = try #require(draft.billingDestination)
        let billing = dependencies.makeBilling(draft, billingDestination)
        #expect(billing.requiresPersistence)
        try await billing.load()
        billing.selectKind(kind)
        if kind == .invoice {
            for field in BillingFiscalField.allCases {
                billing.updateField(field, value: BillingPreviewFixtures.standard.input[field])
            }
        }
        let prepared = try await billing.prepareSelectionDurable()
        let final = try await billing.materialize()
        #expect(final.request == prepared.request)
        #expect(final.isFinal)
        let storedBefore = try ModelContext(composition.modelContainer).fetchCount(
            FetchDescriptor<SalePendingUpsertModel>()
        )
        let closed = try await billing.closeSale(in: composition.modelContainer.mainContext)
        #expect(try await billing.closeSale(in: composition.modelContainer.mainContext) == closed)
        await waitUntil {
            workday.destination == nil && history.visibleSales.contains { $0.id == sale.id }
        }
        guard case let .content(board) = workday.state else {
            Issue.record("The other demonstration operations remain visible")
            return
        }
        #expect(!board.sales.contains { $0.id == sale.id })
        #expect(history.visibleSales.first { $0.id == sale.id } == closed)
        let context = ModelContext(composition.modelContainer)
        #expect(try context.fetchCount(FetchDescriptor<BillingDocumentDeliveryModel>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == storedBefore + 1)
        let detail = dependencies.makeSaleDetail(SaleDetailDestination(id: UUID(), saleID: sale.id))
        let detailObservation = Task {
            await detail.load()
        }
        defer {
            detailObservation.cancel()
        }
        await waitUntil { detail.sale?.id == sale.id }
        #expect(detail.sale == closed)
        #expect(composition.runtime == nil)
    }

    @Test("a demo reopens its retained request and a new launch resets every synthetic document")
    func recoversRetainedDemoRequestAndResetsOnNewLaunch() async throws {
        let session = try await DemoTestSession.make(configuration: .workday)
        defer {
            session.observation.cancel()
        }
        let dependencies = session.composition.dependencies
        let sale = SalesPreviewFixtures.workday.sales[5]
        let draft = dependencies.makeSaleDraft(SaleDraftDestination(id: UUID(), saleID: sale.id, mode: .operate))
        _ = try await draft.load()
        draft.presentBilling()
        let destination = try #require(draft.billingDestination)
        let initial = dependencies.makeBilling(draft, destination)
        try await initial.load()
        let request = try await initial.prepareSelectionDurable().request
        let generated = try await initial.materialize()
        initial.close()
        draft.finishBilling(destination.id)
        draft.presentBilling()
        let reopened = dependencies.makeBilling(draft, try #require(draft.billingDestination))
        try await reopened.load()
        #expect(reopened.request == request)
        #expect(try await reopened.materialize() == generated)
        #expect(try ModelContext(session.composition.modelContainer).fetchCount(
            FetchDescriptor<BillingDocumentDeliveryModel>()
        ) == 1)
        let reset = try DevelopDemoComposition.make(configuration: .workday).applicationComposition
        #expect(try ModelContext(reset.modelContainer).fetchCount(FetchDescriptor<BillingDocumentDeliveryModel>()) == 0)
    }

    private func waitUntil(
        _ condition: @MainActor () -> Bool
    ) async {
        for _ in 0..<10_000 {
            if condition() {
                return
            }
            await Task.yield()
        }
        Issue.record("The accepted local Sales observation did not arrive")
    }
}
#endif
