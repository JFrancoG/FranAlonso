import Foundation
import Observation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Sale service picker composition", .timeLimit(.minutes(1)))
@MainActor
struct SaleServicePickerCompositionTests {
    @Test
    func `App selection shares catalogue writes and freezes two independent accepted snapshots`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let original = try saleSelectionEmptyDraft()
        try SaleLocalDataSource().upsert(original, in: ModelContext(container))
        let service = try SaleServiceSelectionOffering.professional.service(currency: .eur)
        try ServiceLocalDataSource().upsert(service, in: ModelContext(container))
        let dependencies = AppDependencies.preview(modelContainer: container)
        let draft = dependencies.makeSaleDraft(SaleDraftDestination(id: UUID(), saleID: original.id, mode: .editDraft))
        _ = try await draft.load()
        draft.presentServicePicker()
        let firstDestination = try #require(draft.servicePickerDestination)
        let first = dependencies.makeSaleServicePicker(for: draft)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await first.loadCatalogue()
            }
            defer { group.cancelAll() }
            try await waitForSaleSelectionCatalogue(first) { $0.first?.name == "Corte original" }
            first.requestSelection(id: service.id)
            await first.submitSelection()
            try #require(first.hasAcceptedSelection)
            let frozen = try #require(draft.sale?.lines.first)
            let editing = dependencies.makeServiceForm(
                ServiceFormDestination(id: UUID(), serviceID: service.id, mode: .edit),
                Locale(identifier: "en_US_POSIX")
            )
            await editing.load()
            editing.draft = ServiceFormDraft(
                name: "Oferta revisada",
                priceText: "51.09",
                taxText: "10",
                discountText: "10"
            )
            await editing.save(in: container.mainContext)
            try await waitForSaleSelectionCatalogue(first) { $0.first?.name == "Oferta revisada" }
            #expect(draft.sale?.lines.first == frozen)
            #expect(frozen.serviceName == "Corte original")
            #expect(frozen.unitPrice.amount == (try viewModelDecimal("12.10")))
            first.close()
        }
        draft.finishServicePicker(firstDestination.id)
        #expect(!draft.isClosed)
        draft.presentServicePicker()
        let second = dependencies.makeSaleServicePicker(for: draft)
        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await second.loadCatalogue()
            }
            defer { group.cancelAll() }
            try await waitForSaleSelectionCatalogue(second) { $0.first?.name == "Oferta revisada" }
            second.requestSelection(id: service.id)
            await second.submitSelection()
            try #require(second.hasAcceptedSelection)
            second.close()
        }
        let persisted = try #require(try SaleLocalDataSource().sale(id: original.id, in: ModelContext(container)))
        try #require(persisted.lines.count == 2)
        #expect(persisted.lines[0].id != persisted.lines[1].id)
        #expect(persisted.lines.map(\.serviceID) == [service.id, service.id])
        #expect(persisted.lines.map(\.serviceName) == ["Corte original", "Oferta revisada"])
        let expectedAmounts = try ["12.10", "51.09"].map(viewModelDecimal)
        #expect(persisted.lines.map(\.unitPrice.amount) == expectedAmounts)
        #expect(persisted.lines.map { $0.discount?.percentage } == [nil, 10])
        #expect(draft.calculation?.total.amount == (try viewModelDecimal("58.08")))
        draft.close()
        let reopened = dependencies.makeSaleDraft(
            SaleDraftDestination(id: UUID(), saleID: original.id, mode: .editDraft)
        )
        _ = try await reopened.load()
        #expect(reopened.sale == persisted)
        #expect(reopened.calculation?.total.amount == (try viewModelDecimal("58.08")))
        reopened.close()
    }
}

@MainActor
private func waitForSaleSelectionCatalogue(
    _ model: SaleServicePickerViewModel,
    matching predicate: @MainActor ([Service]) -> Bool
) async throws {
    let changes = AsyncStream<Void>.makeStream()
    defer { changes.continuation.finish() }
    var iterator = changes.stream.makeAsyncIterator()
    while !predicate(model.picker.visibleServices) {
        try Task.checkCancellation()
        withObservationTracking {
            _ = model.picker.state
        } onChange: {
            changes.continuation.yield(())
        }
        guard await iterator.next() != nil else { throw CancellationError() }
    }
}
