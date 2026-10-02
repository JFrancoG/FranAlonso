import Foundation
import SwiftData
import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Workday isolated composition", .timeLimit(.minutes(1)))
@MainActor
struct WorkdayCompositionTests {
    @Test
    func `workday launch selects isolated composition while invalid intent stays closed`() {
        let plan = ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: ["--franalonso-demo-workday"]
        )
        #expect(plan == .demo(.workday))
    }

    @Test
    func `workday scenario contains separate operations and leaves previous demos untouched`() throws {
        let workday = try DevelopDemoComposition.make(configuration: .workday).applicationComposition
        let context = ModelContext(workday.modelContainer)
        let sales = try SaleLocalDataSource().fetchAll(in: context)
        let history = SalesHistoryPolicy()(sales)
        let operational = sales.filter { SalesHistoryPolicy().closureDate(of: $0) == nil }

        #expect(sales.count == 9)
        #expect(operational.count == 6)
        #expect(history.count == 3)
        #expect(SalesHistoryPolicy()(history, filter: .closed).count == 2)
        #expect(SalesHistoryPolicy()(history, filter: .voided).count == 1)
        #expect(sales.filter { $0.status == .draft }.count == 3)
        #expect(sales.filter { $0.status == .inProgress }.count == 1)
        #expect(sales.filter { $0.status == .awaitingPayment }.count == 1)
        #expect(sales.filter {
            if case .awaitingDocument = $0.status { return true }
            return false
        }.count == 1)
        #expect(operational.filter { $0.clientID == nil }.count == 2)
        #expect(Set(operational.compactMap(\.clientID)).count == 2)
        #expect(try context.fetchCount(FetchDescriptor<SalePendingUpsertModel>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<SalePendingDiscardModel>()) == 0)
        #expect(workday.runtime == nil)

        let oldDemo = try DevelopDemoComposition.make(configuration: .clients).applicationComposition
        #expect(try ModelContext(oldDemo.modelContainer).fetchCount(FetchDescriptor<SaleModel>()) == 0)
    }

    @Test(arguments: [
        ["--franalonso-demo-workday", "--franalonso-demo-workday"],
        ["--franalonso-demo-workday", "--franalonso-demo-clients"],
        ["--franalonso-demo-workday", "--franalonso-auth-fixture-signed-out"],
        ["--franalonso-demo-workday-unknown"]
    ])
    func `invalid workday intent never falls back to live`(_ arguments: [String]) {
        #expect(ApplicationLaunchPlan.resolve(
            appEnvironment: "develop",
            bundleIdentifier: "com.plusprojects.FranAlonso.develop",
            arguments: arguments
        ) == .invalidFixtureConfiguration)
        #expect(ApplicationLaunchPlan.resolve(
            appEnvironment: "production",
            bundleIdentifier: "com.plusprojects.FranAlonso",
            arguments: ["--franalonso-demo-workday"]
        ) == .invalidFixtureConfiguration)
    }

    @Test
    func `factories share accepted quantity changes with the live local board and reopen`() async throws {
        let original = try viewModelSale()
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let source = SaleLocalDataSource()
        try source.upsert(original, in: ModelContext(container))
        let dependencies = AppDependencies.preview(modelContainer: container)
        let workday = dependencies.makeWorkday()

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await workday.load()
            }
            defer { group.cancelAll() }
            _ = try await waitForBoard(workday) { $0.upcoming.count == 1 }
            workday.openSale(original.id)
            let destination = try #require(workday.destination)
            let detail = dependencies.makeSaleDraft(destination)
            _ = try await detail.load()
            _ = try await detail.increaseQuantity(for: original.lines[0].id)
            detail.close()
            workday.finishSession(destination.id)

            let board = try await waitForBoard(workday) { $0.upcoming.first?.lines.first?.quantity == 2 }
            #expect(board.upcoming.map(\.id) == [original.id])
            let persisted = try #require(try source.sale(id: original.id, in: ModelContext(container)))
            #expect(persisted.lines[0].quantity == 2)
            workday.openSale(original.id)
            let reopened = dependencies.makeSaleDraft(try #require(workday.destination))
            _ = try await reopened.load()
            #expect(reopened.sale == persisted)
            #expect(reopened.calculation?.total.amount == (try viewModelDecimal("24.20")))
            reopened.close()
        }
        workday.close()
    }

    @Test
    func `new presentation writes only after creation and close preserves until explicit discard`() async throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let dependencies = AppDependencies.preview(modelContainer: container)
        let workday = dependencies.makeWorkday()
        workday.beginCreatingSale()
        let untouched = try #require(workday.destination)
        let unopened = dependencies.makeSaleDraft(untouched)
        #expect(try await unopened.load() == nil)
        unopened.close()
        workday.finishSession(untouched.id)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<SaleModel>()) == 0)

        try await withThrowingTaskGroup(of: Void.self) { group in
            group.addTask {
                await workday.load()
            }
            defer { group.cancelAll() }
            workday.beginCreatingSale()
            let destination = try #require(workday.destination)
            let creating = dependencies.makeSaleDraft(destination)
            _ = try await creating.load()
            let accepted = try await creating.create()
            creating.close()
            workday.finishSession(destination.id)
            let board = try await waitForBoard(workday) { $0.upcoming.count == 1 }
            #expect(board.upcoming.first?.id == accepted.id)
            #expect(try SaleLocalDataSource().sale(id: accepted.id, in: ModelContext(container)) == accepted)
            workday.openSale(accepted.id)
            let detail = dependencies.makeSaleDraft(try #require(workday.destination))
            _ = try await detail.load()
            try await detail.discard()
            detail.close()
            #expect(try SaleLocalDataSource().sale(id: accepted.id, in: ModelContext(container)) == nil)
        }
        workday.close()
    }
}

@MainActor
private func waitForBoard(
    _ workday: WorkdayViewModel,
    matching predicate: @MainActor (WorkdaySales) -> Bool
) async throws -> WorkdaySales {
    for _ in 0..<10_000 {
        if case let .content(board) = workday.state, predicate(board) {
            return board
        }
        await Task.yield()
    }
    throw WorkdayCompositionTestError.observationDidNotArrive
}

private enum WorkdayCompositionTestError: Error { case observationDidNotArrive }
#endif
