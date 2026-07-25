import Foundation

/// Signals committed local Clients changes to active repository observations.
///
/// Signals carry no snapshot. Every observer reloads SwiftData after receiving one, so
/// delayed or reordered actor messages cannot move observable state behind the local source
/// of truth. A newest-only buffer coalesces redundant invalidations for slow observers.
actor ClientObservationSignal {
    private typealias Continuation = AsyncStream<Void>.Continuation

    private var continuations: [UUID: Continuation] = [:]

    /// Registers an observation and immediately requests its initial SwiftData load.
    ///
    /// Cancellation removes the continuation from this signal.
    ///
    /// - Returns: A stream that emits once initially and after every known local commit.
    func stream() -> AsyncStream<Void> {
        let subscriptionID = UUID()
        let pair = AsyncStream<Void>.makeStream(
            bufferingPolicy: .bufferingNewest(1)
        )

        pair.continuation.onTermination = { [weak self] _ in
            Task {
                await self?.removeContinuation(for: subscriptionID)
            }
        }
        continuations[subscriptionID] = pair.continuation
        pair.continuation.yield()
        return pair.stream
    }

    /// Invalidates every active observation after a local commit succeeds.
    func publishChange() {
        var terminatedSubscriptionIDs: [UUID] = []
        for (subscriptionID, continuation) in continuations {
            if case .terminated = continuation.yield() {
                terminatedSubscriptionIDs.append(subscriptionID)
            }
        }

        for subscriptionID in terminatedSubscriptionIDs {
            continuations.removeValue(forKey: subscriptionID)
        }
    }

    private func removeContinuation(for subscriptionID: UUID) {
        continuations.removeValue(forKey: subscriptionID)
    }
}
