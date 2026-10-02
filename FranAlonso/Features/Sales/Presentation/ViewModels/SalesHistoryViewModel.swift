import Foundation
import Observation

/// Coordinates terminal queries and independent read-only detail sessions over the local source.
@Observable @MainActor
final class SalesHistoryViewModel {
    enum State: Equatable {
        case idle, loading, content([Sale]), failed, closed
    }

    private(set) var state: State = .idle
    private(set) var destination: SaleDetailDestination?
    private(set) var lastError: (any Error)?
    private(set) var clientDisplayNames: [ClientID: String] = [:]
    var filter: SalesHistoryFilter = .all
    var order: SalesHistoryOrder = .newestFirst
    var query = ""
    private let observeSales: ObserveSalesUseCase
    private let getClient: GetClientUseCase?
    private let makeID: @MainActor () -> UUID
    private let policy = SalesHistoryPolicy()
    @ObservationIgnored private var observationGeneration: UUID?
    @ObservationIgnored private var namesGeneration: UUID?

    /// Search uses captured service names and the sale reference, never current catalogue terms.
    var visibleSales: [Sale] {
        guard case let .content(sales) = state else { return [] }
        let search = query.trimmingCharacters(in: .whitespacesAndNewlines)
        return policy(sales, filter: filter, order: order).filter { sale in
            search.isEmpty || sale.id.rawValue.uuidString.localizedStandardContains(search)
                || sale.lines.contains { $0.serviceName.localizedStandardContains(search) }
        }
    }

    var clientIDs: [ClientID] {
        guard case let .content(sales) = state else { return [] }
        return Set(sales.compactMap(\.clientID)).sorted { $0.rawValue.uuidString < $1.rawValue.uuidString }
    }

    /// Observes for the caller's task lifetime. Replacement and terminal close fence every suspension.
    /// Cancellation returns to idle without surfacing an error; a finite empty stream yields empty content.
    func load() async {
        guard state != .closed else { return }
        let generation = UUID()
        observationGeneration = generation
        namesGeneration = nil
        state = .loading
        lastError = nil
        do {
            try Task.checkCancellation()
            let stream = await observeSales()
            try Task.checkCancellation()
            guard observationGeneration == generation else { return }
            var receivedSnapshot = false
            for try await sales in stream {
                try Task.checkCancellation()
                guard observationGeneration == generation else { return }
                receivedSnapshot = true
                publish(sales)
            }
            try Task.checkCancellation()
            guard observationGeneration == generation else { return }
            if !receivedSnapshot {
                publish([])
            }
        } catch {
            guard observationGeneration == generation else { return }
            if error is CancellationError || Task.isCancelled {
                state = .idle
            } else {
                lastError = error
                state = .failed
            }
        }
    }

    /// Reads optional current client labels separately; missing/deactivated/unreadable clients keep their association.
    /// Superseded identities, task cancellation and close prevent late labels from publishing.
    func resolveClientNames() async {
        let generation = UUID()
        namesGeneration = generation
        let requestedIDs = clientIDs
        clientDisplayNames = [:]
        guard state != .closed, let getClient else { return }
        var names: [ClientID: String] = [:]
        for id in requestedIDs {
            do {
                try Task.checkCancellation()
                let client = try await getClient(id)
                try Task.checkCancellation()
                guard namesGeneration == generation, state != .closed, clientIDs == requestedIDs else { return }
                names[id] = client.displayName
            } catch {
                guard !(error is CancellationError), !Task.isCancelled, namesGeneration == generation,
                      state != .closed, clientIDs == requestedIDs else { return }
            }
        }
        guard !Task.isCancelled, namesGeneration == generation, state != .closed,
              clientIDs == requestedIDs else { return }
        clientDisplayNames = names
    }

    /// Opens only a visible terminal operation. Query changes do not dismiss a valid active detail.
    func openSale(_ id: SaleID) {
        guard destination == nil, visibleSales.contains(where: { $0.id == id }) else { return }
        destination = SaleDetailDestination(id: makeID(), saleID: id)
    }

    /// Clears the query and status restriction while preserving the selected chronology.
    func resetFilters() {
        filter = .all
        query = ""
    }

    /// Supplies a valid focus target after dismissal; missing/filtered origins fall back to the status control.
    func restorableSaleID(_ id: SaleID?) -> SaleID? {
        guard let id, visibleSales.contains(where: { $0.id == id }) else { return nil }
        return id
    }

    /// Ignores delayed dismissal from a previous presentation.
    func finishSession(_ id: UUID) {
        guard destination?.id == id else { return }
        destination = nil
    }

    /// Revokes observation and label generations and ends navigation; caller-owned tasks can finish harmlessly.
    func close() {
        observationGeneration = nil
        namesGeneration = nil
        destination = nil
        clientDisplayNames = [:]
        lastError = nil
        state = .closed
    }

    private func publish(_ sales: [Sale]) {
        let terminal = policy(sales)
        state = .content(terminal)
        clientDisplayNames = clientDisplayNames.filter { clientIDs.contains($0.key) }
        if let destination, !terminal.contains(where: { $0.id == destination.saleID }) {
            self.destination = nil
        }
    }

    init(
        observe: ObserveSalesUseCase,
        getClient: GetClientUseCase? = nil,
        makeID: @escaping @MainActor () -> UUID = { UUID() }
    ) {
        observeSales = observe
        self.getClient = getClient
        self.makeID = makeID
    }
}
