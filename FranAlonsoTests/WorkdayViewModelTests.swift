import Foundation
import Testing
@testable import FranAlonso

@MainActor
struct WorkdayViewModelTests {
    @Test
    func `the board publishes the classified local snapshot rather than calendar-day activity`() async throws {
        let oldDraft = try viewModelSale(index: 1, createdAt: Date(timeIntervalSince1970: 1))
        let working = try viewModelSale(index: 2, stage: .inProgress)
        let paid = try viewModelSale(index: 3, stage: .awaitingDocument)
        let terminal = try viewModelSale(index: 4, stage: .closed)
        let repository = ViewModelSaleRepository(sales: [terminal, paid, oldDraft, working])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))

        await model.load()

        guard case let .content(board) = model.state else {
            Issue.record("Operational snapshots must produce board content")
            return
        }
        #expect(board.upcoming.map(\.id) == [oldDraft.id])
        #expect(board.inProgress.map(\.id) == [working.id])
        #expect(board.awaitingClosure.map(\.id) == [paid.id])
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `terminal-only local content renders empty instead of reopening historical sales`() async throws {
        let repository = ViewModelSaleRepository(sales: [try viewModelSale(stage: .closed)])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))

        await model.load()

        #expect(model.state == .empty)
        model.openSale(SaleID(rawValue: viewModelUUID(1)))
        #expect(model.destination == nil)
        #expect(model.selectedSaleID == nil)
    }

    @Test
    func `creating reserves stable identities until the matching session is dismissed`() async {
        let repository = ViewModelSaleRepository()
        let identities = [viewModelUUID(500), viewModelUUID(1), viewModelUUID(501), viewModelUUID(2)]
        var next = 0
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository)) {
            defer { next += 1 }
            return identities[next]
        }

        model.beginCreatingSale()
        model.beginCreatingSale()
        await model.load()

        let first = model.destination
        #expect(first?.id == viewModelUUID(500))
        #expect(first?.saleID == SaleID(rawValue: viewModelUUID(1)))
        #expect(first?.mode == .create)
        #expect(model.selectedSaleID == nil)
        model.finishSession(viewModelUUID(700))
        #expect(model.destination == first)
        model.finishSession(viewModelUUID(500))
        model.beginCreatingSale()
        model.finishSession(viewModelUUID(500))
        #expect(model.destination?.id == viewModelUUID(501))
        #expect(model.destination?.saleID == SaleID(rawValue: viewModelUUID(2)))
    }

    @Test(arguments: [ViewModelSaleStage.draft, .inProgress, .awaitingPayment, .awaitingDocument])
    func `opening chooses edit capability only for drafts and prevents duplicate sessions`(
        stage: ViewModelSaleStage
    ) async throws {
        let original = try viewModelSale(stage: stage)
        let repository = ViewModelSaleRepository(sales: [original])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository)) { viewModelUUID(500) }
        await model.load()
        model.openSale(SaleID(rawValue: viewModelUUID(999)))
        #expect(model.destination == nil)

        model.openSale(original.id)
        let session = model.destination
        model.openSale(original.id)
        model.beginCreatingSale()

        #expect(model.destination == session)
        #expect(model.selectedSaleID == original.id)
        #expect(session?.id == viewModelUUID(500))
        #expect(session?.mode == (stage == .draft ? .editDraft : .operate))
    }

    @Test
    func `progressing retains its session and delayed dismissal cannot close its replacement`() async throws {
        let draft = try viewModelSale()
        let working = try viewModelSale(stage: .inProgress)
        let repository = ViewModelSaleRepository(sales: [draft])
        var next = 500
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository)) {
            defer { next += 1 }
            return viewModelUUID(next)
        }
        await model.load()
        model.openSale(draft.id)
        let previousSession = try #require(model.destination)
        await repository.saveSale(working)

        await model.load()

        #expect(model.destination == previousSession)
        #expect(model.selectedSaleID == draft.id)
        model.finishSession(previousSession.id)
        model.openSale(working.id)
        let currentSession = try #require(model.destination)
        model.finishSession(previousSession.id)
        #expect(model.destination == currentSession)
        #expect(currentSession.mode == .operate)
    }

    @Test
    func `a paid sale retains inspection until a final document removes it from the board`() async throws {
        let working = try viewModelSale(stage: .inProgress)
        let repository = ViewModelSaleRepository(sales: [working])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        await model.load()
        model.openSale(working.id)
        let session = try #require(model.destination)
        try await repository.saveSale(viewModelSale(stage: .awaitingDocument))

        await model.load()

        #expect(model.destination == session)
        #expect(model.selectedSaleID == working.id)
        try await repository.saveSale(viewModelSale(stage: .closed))
        await model.load()
        #expect(model.state == .empty)
        #expect(model.destination == nil)
        #expect(model.selectedSaleID == nil)
    }

    @Test
    func `a disappearing draft clears its selection and cannot be reopened`() async throws {
        let draft = try viewModelSale()
        let repository = ViewModelSaleRepository(sales: [draft])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        await model.load()
        model.openSale(draft.id)
        await repository.removeFixture(id: draft.id)

        await model.load()

        #expect(model.destination == nil)
        #expect(model.selectedSaleID == nil)
        model.openSale(draft.id)
        #expect(model.destination == nil)
    }

    @Test
    func `observation failure publishes an error and a successful retry clears it`() async throws {
        let draft = try viewModelSale()
        let repository = ViewModelSaleRepository(sales: [draft])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        await repository.failNextObservation()

        await model.load()

        #expect(model.state == .failed)
        #expect(model.lastError as? ViewModelRepositoryError == .unavailable)
        await model.load()
        guard case let .content(board) = model.state else {
            Issue.record("A recovered local stream must restore content")
            return
        }
        #expect(board.upcoming.map(\.id) == [draft.id])
        #expect(model.lastError == nil)
    }

    @Test
    func `close is terminal and cannot reopen observations or navigation`() async throws {
        let repository = ViewModelSaleRepository(sales: [try viewModelSale()])
        let model = WorkdayViewModel(observe: ObserveSalesUseCase(repository: repository))
        await model.load()
        model.beginCreatingSale()

        model.close()
        await model.load()
        model.beginCreatingSale()
        model.openSale(SaleID(rawValue: viewModelUUID(1)))

        #expect(model.state == .closed)
        #expect(model.destination == nil)
        #expect(model.lastError == nil)
        #expect(await repository.writeCount == 0)
    }
}
