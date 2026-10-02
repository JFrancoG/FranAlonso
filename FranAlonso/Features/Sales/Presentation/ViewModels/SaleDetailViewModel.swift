import Foundation
import Observation

/// Observes one terminal snapshot and its original amounts without granting mutation capabilities.
@Observable @MainActor
final class SaleDetailViewModel {
    enum State: Equatable {
        case idle, loading, content(Sale, SaleCalculation), unavailable, failed, closed
    }

    let destination: SaleDetailDestination
    private(set) var state: State = .idle
    private(set) var lastError: (any Error)?
    private(set) var clientName: String?
    private let observeSales: ObserveSalesUseCase
    private let getClient: GetClientUseCase?
    private let policy = SalesHistoryPolicy()
    @ObservationIgnored private var observationGeneration: UUID?
    @ObservationIgnored private var nameGeneration: UUID?

    var sale: Sale? {
        guard case let .content(sale, _) = state else { return nil }
        return sale
    }

    var clientID: ClientID? { sale?.clientID }

    /// Reflects closure/compensation materialized by the local source, retaining presentation identity.
    /// Missing/nonterminal snapshots are unavailable; calculation/read failures are recoverable errors.
    /// Cancellation returns to idle. Replacement or close fences values, failures and completion.
    func load() async {
        guard state != .closed else { return }
        let generation = UUID()
        observationGeneration = generation
        nameGeneration = nil
        clientName = nil
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
                if let sale = sales.first(where: { $0.id == destination.saleID }),
                   policy.closureDate(of: sale) != nil {
                    let calculation = try SaleCalculator().calculate(
                        sale: sale,
                        currency: sale.lines.first?.unitPrice.currency ?? .eur
                    )
                    if clientID != sale.clientID {
                        nameGeneration = nil
                        clientName = nil
                    }
                    state = .content(sale, calculation)
                } else {
                    nameGeneration = nil
                    clientName = nil
                    state = .unavailable
                }
            }
            try Task.checkCancellation()
            guard observationGeneration == generation else { return }
            if !receivedSnapshot {
                state = .unavailable
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

    /// Supplies an optional current display label without replacing the historical client identity.
    func resolveClientName() async {
        let generation = UUID()
        nameGeneration = generation
        clientName = nil
        guard let id = clientID, let getClient, state != .closed else { return }
        do {
            try Task.checkCancellation()
            let client = try await getClient(id)
            try Task.checkCancellation()
            guard nameGeneration == generation, clientID == id, state != .closed else { return }
            clientName = client.displayName
        } catch {
            // The association remains visible even when its optional label is unavailable.
        }
    }

    /// Terminally revokes this presentation's suspended reads without owning task handles.
    func close() {
        observationGeneration = nil
        nameGeneration = nil
        clientName = nil
        lastError = nil
        state = .closed
    }

    init(destination: SaleDetailDestination, observe: ObserveSalesUseCase, getClient: GetClientUseCase? = nil) {
        self.destination = destination
        observeSales = observe
        self.getClient = getClient
    }
}
