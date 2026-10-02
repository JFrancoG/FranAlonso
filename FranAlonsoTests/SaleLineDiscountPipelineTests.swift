import Foundation
import Testing
@testable import FranAlonso

@Suite("Sale line discount acceptance pipeline", .timeLimit(.minutes(1)))
@MainActor
struct SaleLineDiscountPipelineTests {
    @Test(arguments: [("es_ES", "12,5"), ("en_US", "12.5")])
    func `manual percentage preserves captured terms and publishes recalculated local totals`(
        locale: String,
        text: String
    ) async throws {
        let original = try saleDiscountOriginal()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let editor = saleDiscountCoordinator(draft: draft, line: original.lines[0], locale: locale)
        editor.discountText = text
        editor.requestApply()
        _ = try #require(editor.requestID)
        await editor.submit()

        let accepted = try #require(try await sales.sale(id: original.id))
        let line = try #require(accepted.lines.first)
        #expect(await sales.updateAttempts.count == 1)
        #expect(line.discount?.percentage == (try viewModelDecimal("12.5")))
        #expect(line.id == original.lines[0].id)
        #expect(line.serviceID == original.lines[0].serviceID)
        #expect(line.serviceName == "Kit original")
        #expect(line.unitPrice.amount == (try viewModelDecimal("43.27")))
        #expect(line.taxRate.percentage == (try viewModelDecimal("7.5")))
        #expect(line.linkedProductID == ProductID(rawValue: viewModelUUID(7_802)))
        #expect(draft.sale == accepted)
        #expect(draft.calculation?.discountAmount.amount == (try viewModelDecimal("5.41")))
        #expect(draft.calculation?.total.amount == (try viewModelDecimal("37.86")))
        #expect(draft.calculation?.taxableBase.amount == (try viewModelDecimal("35.22")))
        #expect(draft.calculation?.taxAmount.amount == (try viewModelDecimal("2.64")))
        #expect(editor.hasAcceptedChange)
        #expect(!draft.isClosed)
        let reopened = saleSelectionDraft(repository: sales)
        _ = try await reopened.load()
        #expect(reopened.sale == accepted)
        #expect(reopened.calculation?.total.amount == (try viewModelDecimal("37.86")))
    }

    @Test
    func `explicit zero remains a captured term and explicit removal restores absence`() async throws {
        let original = try saleDiscountOriginal()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let zeroEditor = saleDiscountCoordinator(draft: draft, line: original.lines[0])
        zeroEditor.discountText = "0"
        zeroEditor.requestApply()
        _ = try #require(zeroEditor.requestID)
        await zeroEditor.submit()
        #expect(draft.sale?.lines[0].discount?.percentage == 0)
        let currentLine = try #require(draft.sale?.lines.first)
        let removalEditor = saleDiscountCoordinator(draft: draft, line: currentLine)
        removalEditor.requestRemoval()
        _ = try #require(removalEditor.requestID)
        await removalEditor.submit()

        #expect(await sales.updateAttempts.count == 2)
        #expect(try await sales.sale(id: original.id)?.lines[0].discount == nil)
        #expect(draft.sale?.lines[0].discount == nil)
        #expect(draft.calculation?.discountAmount.amount == 0)
        #expect(draft.calculation?.total.amount == (try viewModelDecimal("43.27")))
        #expect(zeroEditor.hasAcceptedChange)
        #expect(removalEditor.hasAcceptedChange)
    }

    @Test
    func `a local failure preserves sale and totals and retry accepts the frozen percentage`() async throws {
        let original = try saleDiscountOriginal()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let priorCalculation = draft.calculation
        let editor = saleDiscountCoordinator(draft: draft, line: original.lines[0])
        await sales.failNextUpdate()
        editor.discountText = "10"
        editor.requestApply()
        _ = try #require(editor.requestID)
        await editor.submit()
        #expect(editor.hasAcceptanceError)
        #expect(draft.sale == original)
        #expect(draft.calculation == priorCalculation)
        #expect(try await sales.sale(id: original.id) == original)
        editor.retry()
        _ = try #require(editor.requestID)
        await editor.submit()

        let attempts = await sales.updateAttempts
        #expect(attempts.count == 2)
        #expect(attempts.first == attempts.last)
        #expect(try await sales.sale(id: original.id)?.lines[0].discount?.percentage == 10)
        #expect(draft.calculation?.discountAmount.amount == (try viewModelDecimal("4.33")))
        #expect(draft.calculation?.total.amount == (try viewModelDecimal("38.94")))
        #expect(editor.hasAcceptedChange)
        #expect(!editor.hasAcceptanceError)
    }

    @Test
    func `duplicate requests and submissions accept once while retaining the task identity`() async throws {
        let original = try saleDiscountOriginal()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let editor = saleDiscountCoordinator(draft: draft, line: original.lines[0])
        let checkpoint = SaleDraftScreenCheckpoint()
        await sales.holdNextUpdate(at: checkpoint, phase: .before)
        editor.discountText = "10"
        editor.requestApply()
        let requestID = try #require(editor.requestID)
        editor.requestApply()
        editor.requestRemoval()
        #expect(editor.requestID == requestID)
        let pending = Task {
            await editor.submit()
        }
        await checkpoint.waitForEntry()
        #expect(editor.isBusy)
        #expect(!editor.canEdit)
        #expect(editor.requestID == requestID)
        editor.discountText = "20"
        editor.requestApply()
        editor.retry()
        await editor.submit()
        await checkpoint.release()
        await pending.value
        editor.requestApply()
        editor.requestRemoval()
        editor.retry()
        await editor.submit()

        #expect(await sales.updateAttempts.count == 1)
        #expect(draft.sale?.lines[0].discount?.percentage == 10)
        #expect(editor.hasAcceptedChange)
        #expect(editor.requestID == nil)
    }

    @Test
    func `caller cancellation before acceptance preserves the parent and offers no failed retry`() async throws {
        let original = try saleDiscountOriginal()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let priorCalculation = draft.calculation
        let editor = saleDiscountCoordinator(draft: draft, line: original.lines[0])
        let checkpoint = SaleDraftScreenCheckpoint()
        await sales.holdNextUpdate(at: checkpoint, phase: .before)
        editor.discountText = "10"
        editor.requestApply()
        _ = try #require(editor.requestID)
        let pending = Task {
            await editor.submit()
        }
        await checkpoint.waitForEntry()
        pending.cancel()
        await checkpoint.release()
        await pending.value
        editor.retry()
        await editor.submit()

        #expect(editor.canEdit)
        #expect(!editor.hasAcceptanceError)
        #expect(!editor.hasAcceptedChange)
        #expect(!editor.isBusy)
        #expect(await sales.updateAttempts.count == 1)
        #expect(draft.sale == original)
        #expect(draft.calculation == priorCalculation)
        #expect(try await sales.sale(id: original.id) == original)
    }

    @Test(arguments: [false, true])
    func `durable success wins over cancellation while closing fences only editor publication`(
        closed: Bool
    ) async throws {
        let original = try saleDiscountOriginal()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let editor = saleDiscountCoordinator(draft: draft, line: original.lines[0])
        let checkpoint = SaleDraftScreenCheckpoint()
        await sales.holdNextUpdate(at: checkpoint, phase: .after)
        editor.discountText = "100"
        editor.requestApply()
        _ = try #require(editor.requestID)
        let pending = Task {
            await editor.submit()
        }
        await checkpoint.waitForEntry()
        if closed {
            editor.close()
        }
        pending.cancel()
        await checkpoint.release()
        await pending.value
        editor.retry()
        editor.requestApply()
        await editor.submit()

        #expect(await sales.updateAttempts.count == 1)
        #expect(try await sales.sale(id: original.id)?.lines[0].discount?.percentage == 100)
        #expect(draft.sale?.lines[0].discount?.percentage == 100)
        #expect(draft.calculation?.total.amount == 0)
        #expect(!draft.isClosed)
        #expect(!editor.hasAcceptanceError)
        #expect(editor.hasAcceptedChange == !closed)
        #expect(editor.state == (closed ? .closed : .accepted))
        #expect(editor.requestID == nil)
    }

    @Test
    func `a parent occupied after request rejects the edit without another repository write`() async throws {
        let original = try saleDiscountOriginal()
        let sales = SaleSelectionControlledRepository(sales: [original])
        let draft = saleSelectionDraft(repository: sales)
        _ = try await draft.load()
        let editor = saleDiscountCoordinator(draft: draft, line: original.lines[0])
        editor.discountText = "10"
        editor.requestApply()
        _ = try #require(editor.requestID)
        let checkpoint = SaleDraftScreenCheckpoint()
        await sales.holdNextUpdate(at: checkpoint, phase: .before)
        let updating = Task {
            try await draft.setQuantity(2, for: original.lines[0].id)
        }
        await checkpoint.waitForEntry()
        await editor.submit()
        #expect(editor.isUnavailable)
        #expect(!editor.canEdit)
        await checkpoint.release()
        _ = try await updating.value

        #expect(await sales.updateAttempts.count == 1)
        #expect(draft.sale?.lines[0].quantity == 2)
        #expect(draft.sale?.lines[0].discount?.percentage == 0)
        #expect(!editor.hasAcceptanceError)
        #expect(!editor.hasAcceptedChange)
    }
}

private func saleDiscountOriginal() throws -> Sale {
    let service = try SaleServiceSelectionOffering.product.service(currency: .eur)
    let line = try SaleLine.capturing(service: service, id: SaleLineID(rawValue: viewModelUUID(7_806)))
    return try saleSelectionEmptyDraft().replacingDraft(clientID: nil, lines: [line])
}

@MainActor
private func saleDiscountCoordinator(
    draft: SaleDraftViewModel,
    line: SaleLine,
    locale: String = "es_ES"
) -> SaleDiscountViewModel {
    SaleDiscountViewModel(
        target: .line(serviceName: line.serviceName),
        discount: line.discount,
        locale: Locale(identifier: locale),
        canEdit: { draft.canAddServices && draft.sale?.lines.contains(where: { $0.id == line.id }) == true },
        apply: { discount in
            _ = try await draft.setDiscount(discount, for: line.id)
        }
    )
}
