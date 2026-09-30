import Foundation
import Observation

/// Coordinates the current local catalogue offered for a future sale selection.
@Observable
@MainActor
final class ServicePickerViewModel {
    enum State: Equatable {
        case idle
        case loading
        case empty
        case content([Service])
        case failed
    }

    private(set) var state: State = .idle
    var query = ""
    var filter: FilterSelectableServicesUseCase.Filter = .all
    private let observeServices: ObserveServicesUseCase
    private let filterServices = FilterSelectableServicesUseCase()
    @ObservationIgnored private var observationGeneration = UUID()

    init(observeServices: ObserveServicesUseCase) {
        self.observeServices = observeServices
    }

    /// Applies editable search and type filters to the only currently selectable catalogue snapshot.
    var visibleServices: [Service] {
        guard case .content(let services) = state else { return [] }
        return filterServices(services, query: query, filter: filter)
    }

    /// Distinguishes a search/filter mismatch from an empty catalogue of active services.
    var hasNoSearchResults: Bool {
        guard case .content = state else { return false }
        return visibleServices.isEmpty
    }

    /// Resolves an identity against the latest visible collection at the instant of selection.
    ///
    /// The returned value retains every commercial field independently of future catalogue changes.
    /// It does not reserve inventory or accept a sale; the sale flow owns those later policies.
    func selectService(id: ServiceID) -> Service? {
        visibleServices.first { $0.id == id }
    }

    /// Observes local snapshots for the caller's task without retaining or starting another task.
    ///
    /// A new observation clears stale choices while preserving search/type input. Normal completion
    /// retains the last snapshot; completion without a snapshot and failures clear choices and fail.
    /// Cancellation clears choices and returns to idle. Replaced generations cannot publish state.
    func load() async {
        let generation = UUID()
        observationGeneration = generation
        state = .loading

        do {
            try Task.checkCancellation()
            let stream = await observeServices()
            guard observationGeneration == generation else { return }
            var receivedSnapshot = false

            for try await services in stream {
                try Task.checkCancellation()
                guard observationGeneration == generation else { return }
                receivedSnapshot = true
                let activeServices = filterServices(services, query: "", filter: .all)
                state = activeServices.isEmpty ? .empty : .content(activeServices)
            }

            try Task.checkCancellation()
            guard observationGeneration == generation else { return }
            if !receivedSnapshot {
                state = .failed
            }
        } catch is CancellationError {
            guard observationGeneration == generation else { return }
            state = .idle
        } catch {
            guard observationGeneration == generation else { return }
            state = Task.isCancelled ? .idle : .failed
        }
    }
}
