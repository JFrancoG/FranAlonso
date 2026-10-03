import Testing
@testable import FranAlonso

@Suite("Billing document presentation state") @MainActor
struct BillingDocumentStoreTests {
    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `preparation freezes a paid request without contacting the numbering authority`(
        _ kind: BillingDocumentKind
    ) async throws {
        let authority = BillingPresentationRepository()
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest(kind: kind)

        try store.prepare(request)

        #expect(store.state == .allocation(.pendingNumber(request)))
        #expect(store.document == nil)
        #expect(store.canReserve)
        #expect(await authority.received.isEmpty)
    }

    @Test
    func `one prepared request cannot be replaced by a different paid snapshot`() async throws {
        let authority = BillingPresentationRepository()
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let original = try billingTransactionRequest()
        try store.prepare(original)
        try store.prepare(original)

        #expect(throws: BillingDocumentStoreError.requestAlreadyPrepared) {
            try store.prepare(billingTransactionRequest(index: 2, kind: .invoice))
        }

        #expect(store.request == original)
        #expect(await authority.received.isEmpty)
    }

    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `confirmed allocation is monotonic and repeated reservation makes no second contact`(
        _ kind: BillingDocumentKind
    ) async throws {
        let authority = BillingPresentationRepository()
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest(kind: kind)
        try store.prepare(request)

        let document = try await store.reserve()
        store.cancelReservation()
        try store.prepare(request)
        let replay = try await store.reserve()

        #expect(document == (try billingPresentationDocument(request)))
        #expect(replay == document)
        #expect(store.state == .allocation(.numbered(document)))
        #expect(!store.canReserve)
        #expect(await authority.received == [request])
    }

    @Test(arguments: [BillingDocumentReservationError.unavailable, .permissionDenied, .conflict, .invalidResponse])
    func `reservation failure keeps its request and explicit retry clears the failure`(
        _ error: BillingDocumentReservationError
    ) async throws {
        let authority = BillingPresentationRepository(replies: [.init(gate: nil, response: .failure(error))])
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()
        try store.prepare(request)

        await #expect(throws: error) {

            try await store.reserve()

        }
        let reason: BillingDocumentFailure = switch error {
        case .permissionDenied: .permissionDenied
        case .conflict: .conflict
        case .unavailable, .invalidResponse: .unavailable
        }
        #expect(store.localState == .failed(request, reason: reason))
        #expect(store.canReserve)
        #expect(store.document == nil)
        try store.prepare(request)
        #expect(store.failure == reason)

        let document = try await store.reserve()

        #expect(document.request == request)
        #expect(store.failure == nil)
        #expect(await authority.received == [request, request])
    }

    @Test(arguments: [BillingPresentationResponse.unknownFailure, .mismatchedRequest])
    func `private errors and unrelated responses cannot publish an untrusted document`(
        _ response: BillingPresentationResponse
    ) async throws {
        let authority = BillingPresentationRepository(replies: [.init(gate: nil, response: response)])
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()
        try store.prepare(request)

        let error: BillingDocumentReservationError = switch response {
        case .mismatchedRequest: .invalidResponse
        default: .unavailable
        }
        await #expect(throws: error) {
            try await store.reserve()
        }
        #expect(store.localState == .failed(request, reason: .unavailable))
        #expect(store.document == nil)
        #expect(await authority.received == [request])
    }

    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `lost response after remote commit recovers one allocation through the full production pipeline`(
        _ kind: BillingDocumentKind
    ) async throws {
        let ledger = BillingTransactionLedger(interruption: .afterCommit)
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: repository))
        let request = try billingTransactionRequest(kind: kind)
        try store.prepare(request)

        await #expect(throws: BillingDocumentReservationError.unavailable) {

            try await store.reserve()

        }
        let remote = try #require(await ledger.document(request.documentID))
        let committed = await ledger.state()
        #expect(committed.commits == 1)
        #expect(store.localState == .failed(request, reason: .unavailable))

        let recovered = try await store.reserve()

        #expect(recovered == (try remote.toDomain()))
        #expect(recovered.number.value == 1)
        #expect(store.localState == .numbered(recovered))
        #expect(await ledger.state() == committed)
        #expect(await ledger.calls == 2)
    }

    @Test
    func `unprepared and overlapping intentions are rejected without disturbing the active request`() async throws {
        let gate = RecoveryOperationGate()
        let authority = BillingPresentationRepository(replies: [.init(gate: gate, response: .success)])
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        await #expect(throws: BillingDocumentStoreError.noRequest) {
            try await store.reserve()
        }
        #expect(store.state == .selection)
        let request = try billingTransactionRequest()
        try store.prepare(request)
        let task = Task {
            try await store.reserve()
        }
        #expect(await gate.waitForEntry())
        #expect(store.state == .reserving(request))
        #expect(store.isBusy)
        #expect(!store.canReserve)
        #expect(throws: BillingDocumentStoreError.operationInProgress) {
            try store.prepare(request)
        }
        await #expect(throws: BillingDocumentStoreError.operationInProgress) {
            try await store.reserve()
        }
        #expect(store.state == .reserving(request))
        #expect(await authority.received == [request])

        await gate.release()
        let confirmed = try await task.value
        #expect(store.document == confirmed)
        #expect(!store.isBusy)
    }

    @Test(arguments: [false, true])
    func `precontact task cancellation leaves pending request even after a prior failure`(
        _ previouslyFailed: Bool
    ) async throws {
        let authority = BillingPresentationRepository(
            replies: [.init(gate: nil, response: .failure(.permissionDenied))]
        )
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()
        try store.prepare(request)
        if previouslyFailed {
            await #expect(throws: BillingDocumentReservationError.permissionDenied) {
                try await store.reserve()
            }
        }
        let previousCalls = await authority.received
        let beforeContact = RecoveryOperationGate()
        let task = Task {
            await beforeContact.enter()
            return try await store.reserve()
        }
        #expect(await beforeContact.waitForEntry())
        task.cancel()
        await beforeContact.release()

        await #expect(throws: CancellationError.self) {

            try await task.value

        }
        #expect(store.localState == .pendingNumber(request))
        #expect(!store.isBusy)
        #expect(store.failure == nil)
        #expect(await authority.received == previousCalls)
    }

    @Test(arguments: [false, true])
    func `native cancellation after commit retains the exact request for a later explicit recovery`(
        _ lateError: Bool
    ) async throws {
        let gate = RecoveryOperationGate()
        let ledger = BillingTransactionLedger(responseGate: gate, responseError: lateError ? .permissionDenied : nil)
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: repository))
        let request = try billingTransactionRequest()
        try store.prepare(request)
        let task = Task {
            try await store.reserve()
        }
        #expect(await gate.waitForEntry())
        let committed = await ledger.state()
        #expect(committed.commits == 1)
        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {

            try await task.value

        }
        #expect(store.localState == .pendingNumber(request))
        #expect(store.document == nil)
        let recovered = try await store.reserve()
        #expect(recovered.request == request)
        #expect(recovered.number.value == 1)
        #expect(await ledger.state() == committed)
    }

    @Test(arguments: [BillingPresentationResponse.success, .failure(.permissionDenied)])
    func `an old success or failure cannot change a newer reservation still in flight`(
        _ oldResponse: BillingPresentationResponse
    ) async throws {
        let oldGate = RecoveryOperationGate()
        let newGate = RecoveryOperationGate()
        let authority = BillingPresentationRepository(replies: [
            .init(gate: oldGate, response: oldResponse),
            .init(gate: newGate, response: .success)
        ])
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()
        try store.prepare(request)
        let oldTask = Task {
            try await store.reserve()
        }
        #expect(await oldGate.waitForEntry())
        store.cancelReservation()
        store.cancelReservation()
        #expect(store.localState == .pendingNumber(request))
        let newTask = Task {
            try await store.reserve()
        }
        #expect(await newGate.waitForEntry())
        await oldGate.release()

        await #expect(throws: CancellationError.self) {

            try await oldTask.value

        }
        #expect(store.state == .reserving(request))
        #expect(store.isBusy)
        #expect(store.failure == nil)
        #expect(await authority.received == [request, request])

        await newGate.release()
        let document = try await newTask.value
        #expect(store.localState == .numbered(document))
        #expect(!store.isBusy)
    }

    @Test(arguments: [BillingPresentationResponse.success, .failure(.permissionDenied)])
    func `closing presentation fences both late success and failure while retaining recovery`(
        _ response: BillingPresentationResponse
    ) async throws {
        let gate = RecoveryOperationGate()
        let authority = BillingPresentationRepository(replies: [.init(gate: gate, response: response)])
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()
        try store.prepare(request)
        let task = Task {
            try await store.reserve()
        }
        #expect(await gate.waitForEntry())
        store.close()
        #expect(store.state == .closed(.pendingNumber(request)))
        #expect(!store.isBusy)
        #expect(!store.canReserve)
        await gate.release()

        await #expect(throws: CancellationError.self) {

            try await task.value

        }
        #expect(store.state == .closed(.pendingNumber(request)))
        #expect(store.request == request)
        #expect(store.document == nil)
    }

    @Test(arguments: [BillingPresentationClosureStage.selection, .pending, .failed, .numbered])
    func `terminal close retains its exact snapshot and rejects reopening`(
        _ stage: BillingPresentationClosureStage
    ) async throws {
        let response: BillingPresentationResponse = stage == .failed ? .failure(.conflict) : .success
        let authority = BillingPresentationRepository(replies: [.init(gate: nil, response: response)])
        let store = BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority))
        let request = try billingTransactionRequest()
        if stage != .selection {
            try store.prepare(request)
        }
        if stage == .failed {
            await #expect(throws: BillingDocumentReservationError.conflict) {
                try await store.reserve()
            }
        }
        if stage == .numbered {
            _ = try await store.reserve()
        }
        let retained = store.localState
        let previousCalls = await authority.received
        store.close()
        store.close()
        store.cancelReservation()

        #expect(store.state == .closed(retained))
        #expect(store.localState == retained)
        #expect(throws: BillingDocumentStoreError.closed) {
            try store.prepare(request)
        }
        await #expect(throws: BillingDocumentStoreError.closed) {
            try await store.reserve()
        }
        #expect(await authority.received == previousCalls)
    }
}
