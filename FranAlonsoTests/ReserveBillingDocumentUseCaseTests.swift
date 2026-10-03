import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing document reservation")
struct ReserveBillingDocumentUseCaseTests {
    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `recreating the use case replays the original allocation and paid snapshot`(
        _ kind: BillingDocumentKind
    ) async throws {
        let request = try reservationRequest(kind: kind)
        let authority = ReservationLedger()
        let first = try await ReserveBillingDocumentUseCase(repository: authority)(request)
        let recovered = try await ReserveBillingDocumentUseCase(repository: authority)(request)

        #expect(recovered == first)
        #expect(recovered.request == request)
        #expect(recovered.id == request.documentID)
        #expect(recovered.number.series == kind.series)
        #expect(recovered.number.value == (kind == .ticket ? 41 : 91))
        #expect(recovered.issuedAt == Date(timeIntervalSince1970: 190))
        #expect(await authority.documentCount == 1)
        #expect(await authority.received == [request, request])
    }

    @Test
    func `interleaved ticket and invoice requests consume only their own series`() async throws {
        let authority = ReservationLedger()
        let reserve = ReserveBillingDocumentUseCase(repository: authority)
        let ticket = try await reserve(reservationRequest(index: 1, kind: .ticket))
        let invoice = try await reserve(reservationRequest(index: 2, kind: .invoice))
        let nextTicket = try await reserve(reservationRequest(index: 3, kind: .ticket))
        let nextInvoice = try await reserve(reservationRequest(index: 4, kind: .invoice))

        #expect(ticket.number.value == 41)
        #expect(nextTicket.number.value == 42)
        #expect(invoice.number.value == 91)
        #expect(nextInvoice.number.value == 92)
        #expect([ticket.number.series, nextTicket.number.series] == [BillingDocumentSeries.ticket, .ticket])
        #expect([invoice.number.series, nextInvoice.number.series] == [BillingDocumentSeries.invoice, .invoice])
        #expect(await authority.documentCount == 4)
        #expect(await authority.received.count == 4)
    }

    @Test(arguments: [
        ReservationRequestDifference.documentIdentity,
        .family,
        .requestTime,
        .saleIdentity,
        .clientIdentity,
        .saleCreationTime,
        .lineSnapshot,
        .paymentMetadata,
        .commercialTerms
    ])
    func `a reused request identity with changed content conflicts without consuming a number`(
        _ difference: ReservationRequestDifference
    ) async throws {
        let authority = ReservationLedger()
        let request = try reservationRequest()
        let original = try await ReserveBillingDocumentUseCase(repository: authority)(request)
        let changed = try differingReservationRequest(request, difference: difference)

        await #expect(throws: BillingDocumentReservationError.conflict) {
            try await ReserveBillingDocumentUseCase(repository: authority)(changed)
        }
        let replayed = try await ReserveBillingDocumentUseCase(repository: authority)(request)
        let next = try await ReserveBillingDocumentUseCase(repository: authority)(reservationRequest(index: 20))

        #expect(replayed == original)
        #expect(next.number.value == 42)
        #expect(await authority.documentCount == 2)
        #expect(await authority.received == [request, changed, request, next.request])
    }

    @Test
    func `a document identity already owned by another request cannot be rebound`() async throws {
        let authority = ReservationLedger()
        let request = try reservationRequest()
        let original = try await ReserveBillingDocumentUseCase(repository: authority)(request)
        let collision = try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: viewModelUUID(711)),
            documentID: request.documentID,
            sale: viewModelSale(index: 2, stage: .awaitingDocument),
            kind: .invoice,
            requestedAt: Date(timeIntervalSince1970: 201)
        )

        await #expect(throws: BillingDocumentReservationError.conflict) {
            try await ReserveBillingDocumentUseCase(repository: authority)(collision)
        }
        let recovered = try await ReserveBillingDocumentUseCase(repository: authority)(request)
        let invoice = try await ReserveBillingDocumentUseCase(repository: authority)(
            reservationRequest(index: 3, kind: .invoice)
        )

        #expect(recovered == original)
        #expect(invoice.number.value == 91)
        #expect(await authority.documentCount == 2)
        #expect(await authority.received == [request, collision, request, invoice.request])
    }

    @Test(arguments: [
        ReservationRequestDifference.requestIdentity,
        .documentIdentity,
        .family,
        .requestTime,
        .saleIdentity,
        .clientIdentity,
        .saleCreationTime,
        .lineSnapshot,
        .paymentMetadata,
        .commercialTerms
    ])
    func `a provider response must match the complete original request`(
        _ difference: ReservationRequestDifference
    ) async throws {
        let request = try reservationRequest()
        let substituted = try differingReservationRequest(request, difference: difference)
        let response = try BillingDocument.numbered(
            request: substituted,
            number: BillingDocumentNumber(series: substituted.kind.series, value: 41),
            issuedAt: Date(timeIntervalSince1970: 190)
        )
        let provider = SubstitutingReservationRepository(response: response)

        await #expect(throws: BillingDocumentReservationError.invalidResponse) {
            try await ReserveBillingDocumentUseCase(repository: provider)(request)
        }

        #expect(await provider.received == [request])
    }

    @Test(arguments: [
        BillingDocumentReservationError.unavailable,
        .permissionDenied,
        .conflict,
        .invalidResponse
    ])
    func `neutral provider failures retain their meaning without automatic retry`(
        _ error: BillingDocumentReservationError
    ) async throws {
        let request = try reservationRequest()
        let provider = FailingReservationRepository(error: error)

        await #expect(throws: error) {
            try await ReserveBillingDocumentUseCase(repository: provider)(request)
        }

        #expect(await provider.received == [request])
    }

    @Test
    func `an unknown provider failure becomes unavailable without exposing its private error`() async throws {
        let request = try reservationRequest()
        let provider = FailingReservationRepository(error: ReservationProviderPrivateError.internalFailure)

        await #expect(throws: BillingDocumentReservationError.unavailable) {
            try await ReserveBillingDocumentUseCase(repository: provider)(request)
        }

        #expect(await provider.received == [request])
    }

    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `a lost response after acceptance recovers the original allocation on explicit retry`(
        _ kind: BillingDocumentKind
    ) async throws {
        let request = try reservationRequest(kind: kind)
        let authority = ReservationLedger(losesNextResponse: true)

        await #expect(throws: BillingDocumentReservationError.unavailable) {
            try await ReserveBillingDocumentUseCase(repository: authority)(request)
        }
        let committed = try #require(await authority.document(for: request.id))
        #expect(await authority.documentCount == 1)
        #expect(await authority.received == [request])

        let recovered = try await ReserveBillingDocumentUseCase(repository: authority)(request)

        #expect(recovered == committed)
        #expect(recovered.request == request)
        #expect(recovered.number.value == (kind == .ticket ? 41 : 91))
        #expect(recovered.issuedAt == Date(timeIntervalSince1970: 190))
        #expect(await authority.documentCount == 1)
        #expect(await authority.received == [request, request])
    }

    @Test
    func `cancellation before invocation prevents contacting the reservation authority`() async throws {
        let request = try reservationRequest()
        let authority = ReservationLedger()
        let gate = RecoveryOperationGate()
        let task = Task {
            await gate.enter()
            do {
                let document = try await ReserveBillingDocumentUseCase(repository: authority)(request)
                await gate.finish()
                return document
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = await task.result
            Issue.record("The invocation task finished before its cancellation gate")
            return
        }

        task.cancel()
        await gate.release()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }

        #expect(await authority.documentCount == 0)
        #expect(await authority.received.isEmpty)
    }

    @Test(arguments: [ReservationResponseOutcome.acceptedResponse, .providerError])
    func `cancellation after commitment rejects late success or failure and permits recovery`(
        _ outcome: ReservationResponseOutcome
    ) async throws {
        let request = try reservationRequest()
        let gate = RecoveryOperationGate()
        let authority = ReservationLedger(
            responseGate: gate,
            losesNextResponse: false,
            nextResponseError: outcome == .providerError ? .permissionDenied : nil
        )
        let task = Task {
            do {
                let document = try await ReserveBillingDocumentUseCase(repository: authority)(request)
                await gate.finish()
                return document
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = await task.result
            Issue.record("The reservation task finished before the committed-response gate")
            return
        }
        let committed = await authority.document(for: request.id)

        task.cancel()
        await gate.release()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }

        let original = try #require(committed)
        let recovered = try await ReserveBillingDocumentUseCase(repository: authority)(request)
        #expect(recovered == original)
        #expect(recovered.request == request)
        #expect(recovered.number.value == 41)
        #expect(recovered.issuedAt == Date(timeIntervalSince1970: 190))
        #expect(await authority.documentCount == 1)
        #expect(await authority.received == [request, request])
    }

    @Test
    func `native provider cancellation remains cancellation and is never retried automatically`() async throws {
        let request = try reservationRequest()
        let provider = FailingReservationRepository(error: CancellationError())

        await #expect(throws: CancellationError.self) {
            try await ReserveBillingDocumentUseCase(repository: provider)(request)
        }

        #expect(await provider.received == [request])
    }
}

enum ReservationRequestDifference {
    case requestIdentity, documentIdentity, family, requestTime, saleIdentity
    case clientIdentity, saleCreationTime, lineSnapshot, paymentMetadata, commercialTerms
}

enum ReservationResponseOutcome {
    case acceptedResponse, providerError
}

private enum ReservationProviderPrivateError: Error {
    case internalFailure
}

private func reservationRequest(index: Int = 1, kind: BillingDocumentKind = .ticket) throws -> BillingDocumentRequest {
    try BillingDocumentRequest(
        id: BillingDocumentRequestID(rawValue: viewModelUUID(700 + index)),
        documentID: BillingDocumentID(rawValue: viewModelUUID(800 + index)),
        sale: viewModelSale(index: index, stage: .awaitingDocument),
        kind: kind,
        requestedAt: Date(timeIntervalSince1970: 201)
    )
}

private func differingReservationRequest(
    _ request: BillingDocumentRequest,
    difference: ReservationRequestDifference
) throws -> BillingDocumentRequest {
    var id = request.id
    var documentID = request.documentID
    var sale = request.sale
    var kind = request.kind
    var requestedAt = request.requestedAt
    switch difference {
    case .requestIdentity:
        id = BillingDocumentRequestID(rawValue: viewModelUUID(710))
    case .documentIdentity:
        documentID = BillingDocumentID(rawValue: viewModelUUID(810))
    case .family:
        kind = .invoice
    case .requestTime:
        requestedAt = Date(timeIntervalSince1970: 202)
    case .saleIdentity:
        sale = try viewModelSale(index: 2, stage: .awaitingDocument)
    case .clientIdentity:
        sale = try viewModelSale(stage: .awaitingDocument, clientID: ClientID(rawValue: viewModelUUID(600)))
    case .saleCreationTime:
        sale = try viewModelSale(stage: .awaitingDocument, createdAt: Date(timeIntervalSince1970: 101))
    case .lineSnapshot:
        sale = try reservationPaidSale(quantity: 2)
    case .paymentMetadata:
        sale = try reservationPaidSale(method: .card)
    case .commercialTerms:
        sale = try reservationPaidSale(
            globalDiscount: SaleGlobalDiscount(discount: Discount(percentage: 10), policy: .lineThenGlobalV1)
        )
    }
    return try BillingDocumentRequest(
        id: id,
        documentID: documentID,
        sale: sale,
        kind: kind,
        requestedAt: requestedAt
    )
}

private func reservationPaidSale(
    quantity: Int = 1,
    method: PaymentMethod = .cash,
    globalDiscount: SaleGlobalDiscount? = nil
) throws -> Sale {
    let line = try viewModelLine(quantity: quantity)
    var sale = try Sale.draft(
        id: SaleID(rawValue: viewModelUUID(1)),
        clientID: nil,
        createdAt: Date(timeIntervalSince1970: 100),
        lines: [line],
        globalDiscount: globalDiscount
    )
    try sale.start()
    try sale.startLine(id: line.id)
    try sale.completeLine(id: line.id)
    try sale.registerPayment(
        id: PaymentID(rawValue: viewModelUUID(800)),
        method: method,
        paidAt: Date(timeIntervalSince1970: 200)
    )
    return sale
}

// This controlled authority models the contract; it is not evidence of Firestore atomicity.
private actor ReservationLedger: BillingDocumentReservationRepository {
    private var documents: [BillingDocumentRequestID: BillingDocument] = [:]
    private var counters: [BillingDocumentSeries: Int] = [.ticket: 40, .invoice: 90]
    private var responseGate: RecoveryOperationGate?
    private var losesNextResponse: Bool
    private var nextResponseError: BillingDocumentReservationError?
    private(set) var received: [BillingDocumentRequest] = []

    init(
        responseGate: RecoveryOperationGate? = nil,
        losesNextResponse: Bool = false,
        nextResponseError: BillingDocumentReservationError? = nil
    ) {
        self.responseGate = responseGate
        self.losesNextResponse = losesNextResponse
        self.nextResponseError = nextResponseError
    }

    var documentCount: Int { documents.count }

    func document(for id: BillingDocumentRequestID) -> BillingDocument? { documents[id] }

    func reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument {
        received.append(request)
        let document = try accept(request)
        if losesNextResponse {
            losesNextResponse = false
            throw BillingDocumentReservationError.unavailable
        }
        let gate = responseGate
        let error = nextResponseError
        responseGate = nil
        nextResponseError = nil
        if let gate {
            await gate.enter()
        }
        if let error {
            throw error
        }
        return document
    }

    private func accept(_ request: BillingDocumentRequest) throws -> BillingDocument {
        if let stored = documents[request.id] {
            guard stored.request == request else { throw BillingDocumentReservationError.conflict }
            return stored
        }
        guard !documents.values.contains(where: { $0.id == request.documentID }) else {
            throw BillingDocumentReservationError.conflict
        }
        let value = (counters[request.kind.series] ?? 0) + 1
        let document = try BillingDocument.numbered(
            request: request,
            number: BillingDocumentNumber(series: request.kind.series, value: value),
            issuedAt: Date(timeIntervalSince1970: 190)
        )
        counters[request.kind.series] = value
        documents[request.id] = document
        return document
    }
}

private actor SubstitutingReservationRepository: BillingDocumentReservationRepository {
    let response: BillingDocument
    private(set) var received: [BillingDocumentRequest] = []

    init(response: BillingDocument) {
        self.response = response
    }

    func reserve(_ request: BillingDocumentRequest) -> BillingDocument {
        received.append(request)
        return response
    }
}

private actor FailingReservationRepository: BillingDocumentReservationRepository {
    let error: any Error
    private(set) var received: [BillingDocumentRequest] = []

    init(error: any Error) {
        self.error = error
    }

    func reserve(_ request: BillingDocumentRequest) throws -> BillingDocument {
        received.append(request)
        throw error
    }
}
