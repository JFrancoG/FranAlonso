import Testing
@testable import FranAlonso

@Suite("Workday screen semantics", .timeLimit(.minutes(1)))
@MainActor
struct WorkdayScreenSemanticsTests {
    @Test
    func `board client labels resolve visible associations without merging their sales`() async throws {
        let firstClient = Client.draft(id: ClientID(rawValue: viewModelUUID(600)), displayName: "Cliente uno")
        let secondClient = Client.draft(id: ClientID(rawValue: viewModelUUID(601)), displayName: "Cliente dos")
        let sales = try [
            viewModelSale(index: 1, clientID: firstClient.id),
            viewModelSale(index: 2, clientID: firstClient.id),
            viewModelSale(index: 3, clientID: secondClient.id),
            viewModelSale(index: 4)
        ]
        let model = WorkdayViewModel(
            observe: ObserveSalesUseCase(repository: InMemorySaleRepository(sales: sales)),
            getClient: GetClientUseCase(repository: InMemoryClientRepository(clients: [firstClient, secondClient]))
        )

        await model.load()
        await model.resolveClientNames()

        #expect(model.clientIDs == [ClientID(rawValue: viewModelUUID(600)), ClientID(rawValue: viewModelUUID(601))])
        #expect(model.clientDisplayNames[firstClient.id] == "Cliente uno")
        #expect(model.clientDisplayNames[secondClient.id] == "Cliente dos")
        guard case let .content(board) = model.state else {
            Issue.record("Name resolution must retain all operational snapshots")
            return
        }
        #expect(board.upcoming.map(\.id) == [
            SaleID(rawValue: viewModelUUID(1)),
            SaleID(rawValue: viewModelUUID(2)),
            SaleID(rawValue: viewModelUUID(3)),
            SaleID(rawValue: viewModelUUID(4))
        ])
    }

    @Test
    func `suspended client lookup never blocks a newer sale observation or replaces its labels`() async throws {
        let oldClient = Client.draft(id: ClientID(rawValue: viewModelUUID(600)), displayName: "Nombre anterior")
        let newClient = Client.draft(id: ClientID(rawValue: viewModelUUID(601)), displayName: "Nombre actual")
        let original = try viewModelSale(clientID: oldClient.id)
        let replacement = try viewModelSale(clientID: newClient.id)
        let repository = InMemorySaleRepository(sales: [original])
        let clients = ScreenClientReadRepository(clients: [oldClient, newClient])
        let model = WorkdayViewModel(
            observe: ObserveSalesUseCase(repository: repository),
            getClient: GetClientUseCase(repository: clients)
        )
        await model.load()
        let checkpoint = SaleDraftScreenCheckpoint()
        await clients.holdNextRead(at: checkpoint)
        let previousNames = Task {
            await model.resolveClientNames()
        }
        await checkpoint.waitForEntry()
        do {
            try await repository.saveSale(replacement)
            await model.load()
            await model.resolveClientNames()
        } catch {
            await checkpoint.release()
            await previousNames.value
            throw error
        }
        await checkpoint.release()
        await previousNames.value

        #expect(model.clientIDs == [newClient.id])
        #expect(model.clientDisplayNames[oldClient.id] == nil)
        #expect(model.clientDisplayNames[newClient.id] == "Nombre actual")
        guard case let .content(board) = model.state else {
            Issue.record("Sales observation must finish independently of the suspended client lookup")
            return
        }
        #expect(board.upcoming.first?.clientID == newClient.id)
        #expect(board.upcoming.map(\.id) == [original.id])
    }

    @Test(arguments: [false, true])
    func `client label completion after cancellation or close never publishes private display names`(
        closed: Bool
    ) async throws {
        let client = Client.draft(id: ClientID(rawValue: viewModelUUID(600)), displayName: "Nombre cancelado")
        let repository = InMemorySaleRepository(sales: [try viewModelSale(clientID: client.id)])
        let clients = ScreenClientReadRepository(clients: [client])
        let model = WorkdayViewModel(
            observe: ObserveSalesUseCase(repository: repository),
            getClient: GetClientUseCase(repository: clients)
        )
        await model.load()
        let checkpoint = SaleDraftScreenCheckpoint()
        await clients.holdNextRead(at: checkpoint)
        let pending = Task {
            await model.resolveClientNames()
        }
        await checkpoint.waitForEntry()
        if closed {
            model.close()
        } else {
            pending.cancel()
        }
        await checkpoint.release()
        await pending.value

        #expect(model.clientDisplayNames.isEmpty)
        #expect(model.lastError == nil)
        if closed {
            #expect(model.state == .closed)
        } else {
            await model.resolveClientNames()
            #expect(model.clientDisplayNames[client.id] == "Nombre cancelado")
        }
    }

    @Test
    func `missing or failed clients do not fail sales content or hide independently resolved labels`() async throws {
        let missingID = ClientID(rawValue: viewModelUUID(600))
        let present = Client.draft(id: ClientID(rawValue: viewModelUUID(601)), displayName: "Cliente disponible")
        let sales = try [viewModelSale(index: 1, clientID: missingID), viewModelSale(index: 2, clientID: present.id)]
        let clients = ScreenClientReadRepository(clients: [present])
        let model = WorkdayViewModel(
            observe: ObserveSalesUseCase(repository: InMemorySaleRepository(sales: sales)),
            getClient: GetClientUseCase(repository: clients)
        )
        await model.load()
        await model.resolveClientNames()

        #expect(model.clientDisplayNames[missingID] == nil)
        #expect(model.clientDisplayNames[present.id] == "Cliente disponible")
        #expect(model.lastError == nil)
        guard case let .content(board) = model.state else {
            Issue.record("Client availability must not change the sales load state")
            return
        }
        #expect(board.sales.count == 2)
        try await clients.saveClient(Client.draft(id: missingID, displayName: "Cliente con error temporal"))
        await clients.failNextRead()
        await model.resolveClientNames()
        #expect(model.clientDisplayNames[missingID] == nil)
        #expect(model.clientDisplayNames[present.id] == "Cliente disponible")
        #expect(model.lastError == nil)
    }
}
