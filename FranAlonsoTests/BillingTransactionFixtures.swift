import Foundation
@testable import FranAlonso

enum BillingTransactionInterruption {
    case beforeCommit, afterCommit
}

struct BillingTransactionLedgerState: Equatable {
    let bindings: [String: Data]
    let documents: [String: Data]
    let counters: [BillingDocumentSeries: Data]
    let commits: Int
}

// Models optimistic contention at the production transaction seam, not Firestore server guarantees.
actor BillingTransactionLedger: BillingTransactionDataSource {
    private var bindings: [String: Data] = [:]
    private var documents: [String: Data] = [:]
    private var counters: [BillingDocumentSeries: Data] = [:]
    private var version = 0
    private var commits = 0
    private var firstReads = 0
    private var interruption: BillingTransactionInterruption?
    private var responseGate: RecoveryOperationGate?
    private var responseError: BillingDocumentReservationError?
    private let readBarrier: BillingTransactionReadBarrier?
    private(set) var calls = 0
    private(set) var staleAttempts = 0

    init(
        interruption: BillingTransactionInterruption? = nil,
        responseGate: RecoveryOperationGate? = nil,
        responseError: BillingDocumentReservationError? = nil,
        readBarrier: BillingTransactionReadBarrier? = nil
    ) {
        self.interruption = interruption
        self.responseGate = responseGate
        self.responseError = responseError
        self.readBarrier = readBarrier
    }

    func seedCounter(_ value: BillingCounterDTO) throws {
        counters[value.series] = try JSONEncoder().encode(value)
    }

    func seedBinding(_ value: BillingRequestBindingDTO, at key: String) throws {
        bindings[key] = try JSONEncoder().encode(value)
    }

    func seedDocument(_ value: BillingDocumentRecordDTO, at key: String) throws {
        documents[key] = try JSONEncoder().encode(value)
    }

    func seedDocumentBytes(_ value: Data, at key: String) {
        documents[key] = value
    }

    func seedBindingBytes(_ value: Data, at key: String) {
        bindings[key] = value
    }

    func seedCounterBytes(_ value: Data, series: BillingDocumentSeries) {
        counters[series] = value
    }

    func state() -> BillingTransactionLedgerState {
        BillingTransactionLedgerState(bindings: bindings, documents: documents, counters: counters, commits: commits)
    }

    func counter(_ series: BillingDocumentSeries) throws -> BillingCounterDTO? {
        try counters[series].map {
            try JSONDecoder().decode(BillingCounterDTO.self, from: $0)
        }
    }

    func document(_ id: BillingDocumentID) throws -> BillingDocumentRecordDTO? {
        try documents[id.rawValue.uuidString].map {
            try JSONDecoder().decode(BillingDocumentRecordDTO.self, from: $0)
        }
    }

    func transact(
        request: BillingDocumentRequestDTO,
        plan: @escaping @Sendable (BillingTransactionSnapshot) throws -> BillingTransactionPlan
    ) async throws -> BillingDocumentRecordDTO {
        calls += 1
        let transported = try JSONDecoder().decode(BillingDocumentRequestDTO.self, from: JSONEncoder().encode(request))
        while true {
            let readVersion = version
            let snapshot = try snapshot(for: transported)
            if let readBarrier, firstReads < 2 {
                firstReads += 1
                await readBarrier.arrive()
            }
            let proposed = try plan(snapshot)
            let encodedPlan = try JSONEncoder().encode(proposed)
            let transportedPlan = try JSONDecoder().decode(BillingTransactionPlan.self, from: encodedPlan)
            guard readVersion == version else {
                staleAttempts += 1
                continue
            }
            let record: BillingDocumentRecordDTO
            switch transportedPlan {
            case let .replay(existing):
                record = existing
            case let .create(pending, binding, counter):
                if interruption == .beforeCommit {
                    interruption = nil
                    throw BillingDocumentReservationError.unavailable
                }
                let committed = BillingDocumentRecordDTO(
                    payloadVersion: pending.payloadVersion,
                    request: pending.request,
                    series: pending.series,
                    number: pending.number,
                    issuedAt: try SaleTimestampDTO(Date(timeIntervalSince1970: 190))
                )
                let documentBytes = try JSONEncoder().encode(committed)
                let bindingBytes = try JSONEncoder().encode(binding)
                let counterBytes = try JSONEncoder().encode(counter)
                documents[transported.documentID] = documentBytes
                bindings[transported.id] = bindingBytes
                counters[transported.kind.series] = counterBytes
                commits += 1
                version += 1
                record = committed
                if interruption == .afterCommit {
                    interruption = nil
                    throw BillingDocumentReservationError.unavailable
                }
            }
            let gate = responseGate
            let error = responseError
            responseGate = nil
            responseError = nil
            if let gate {
                await gate.enter()
            }
            if let error {
                throw error
            }
            return record
        }
    }

    private func snapshot(for request: BillingDocumentRequestDTO) throws -> BillingTransactionSnapshot {
        let decoder = JSONDecoder()
        let binding = try bindings[request.id].map {
            try decoder.decode(BillingRequestBindingDTO.self, from: $0)
        }
        let document = try documents[request.documentID].map {
            try decoder.decode(BillingDocumentRecordDTO.self, from: $0)
        }
        let counter: BillingCounterState
        if let bytes = counters[request.kind.series] {
            if let value = try? decoder.decode(BillingCounterDTO.self, from: bytes) {
                counter = .value(value)
            } else {
                counter = .malformed
            }
        } else {
            counter = .absent
        }
        return BillingTransactionSnapshot(binding: binding, document: document, counter: counter)
    }
}

actor BillingTransactionReadBarrier {
    private var arrivals = 0
    private var finishes = 0
    private var waiters: [CheckedContinuation<Void, Never>] = []

    func arrive() async {
        arrivals += 1
        guard arrivals + finishes < 2 else {
            release()
            return
        }
        await withCheckedContinuation {
            waiters.append($0)
        }
    }

    func finish() {
        finishes += 1
        if arrivals + finishes >= 2 {
            release()
        }
    }

    private func release() {
        for waiter in waiters {
            waiter.resume()
        }
        waiters.removeAll()
    }
}

func billingTransactionRequest(index: Int = 1, kind: BillingDocumentKind = .ticket) throws -> BillingDocumentRequest {
    try BillingDocumentRequest(
        id: BillingDocumentRequestID(rawValue: viewModelUUID(700 + index)),
        documentID: BillingDocumentID(rawValue: viewModelUUID(800 + index)),
        sale: viewModelSale(index: index, stage: .awaitingDocument),
        kind: kind,
        requestedAt: Date(timeIntervalSince1970: 201)
    )
}

func billingTransactionRecord(_ request: BillingDocumentRequest) throws -> BillingDocumentRecordDTO {
    try BillingDocumentRecordDTO(
        payloadVersion: 1,
        request: BillingDocumentRequestDTO(request),
        series: request.kind.series,
        number: 41,
        issuedAt: SaleTimestampDTO(Date(timeIntervalSince1970: 190))
    )
}

func billingTransactionBinding(_ request: BillingDocumentRequest) -> BillingRequestBindingDTO {
    BillingRequestBindingDTO(
        payloadVersion: 1,
        requestID: request.id.rawValue.uuidString,
        documentID: request.documentID.rawValue.uuidString
    )
}

func billingConcurrentResult(
    _ request: BillingDocumentRequest,
    ledger: BillingTransactionLedger,
    barrier: BillingTransactionReadBarrier
) async -> Result<BillingDocument, any Error> {
    do {
        let document = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
        await barrier.finish()
        return .success(document)
    } catch {
        await barrier.finish()
        return .failure(error)
    }
}

func billingBytesWithUnknownField(_ value: some Encodable) throws -> Data {
    var bytes = try JSONEncoder().encode(value)
    bytes.removeLast()
    bytes.append(Data(",\"unexpected\":true}".utf8))
    return bytes
}

func billingRecordBytesWithUnknownRequestField(_ value: BillingDocumentRecordDTO) throws -> Data {
    let bytes = try JSONEncoder().encode(value)
    guard var fixture = String(data: bytes, encoding: .utf8), let range = fixture.range(of: "\"request\":{") else {
        throw BillingDocumentReservationError.invalidResponse
    }
    fixture.replaceSubrange(range, with: "\"request\":{\"unexpected\":true,")
    return Data(fixture.utf8)
}

enum BillingTransactionInvalidCounter {
    case unsupportedVersion, wrongSeries, negative, malformed, exhausted, unknownField

    func seed(_ ledger: BillingTransactionLedger) async throws {
        let counter = BillingCounterDTO(
            payloadVersion: self == .unsupportedVersion ? 2 : 1,
            series: self == .wrongSeries ? .invoice : .ticket,
            lastNumber: self == .negative ? -1 : self == .exhausted ? Int64.max : 40
        )
        let bytes: Data
        switch self {
        case .malformed:
            bytes = Data("{\"lastNumber\":\"not-a-number\"}".utf8)
        case .unknownField:
            bytes = try billingBytesWithUnknownField(counter)
        case .unsupportedVersion, .wrongSeries, .negative, .exhausted:
            bytes = try JSONEncoder().encode(counter)
        }
        await ledger.seedCounterBytes(bytes, series: .ticket)
    }
}

enum BillingTransactionCorruption {
    case bindingWithoutDocument, documentWithoutBinding, bindingVersion, bindingIdentity
    case documentVersion, requestVersion, requestIdentity, documentIdentity, wrongSeries
    case zeroNumber, negativeNumber, missingTimestamp, unpaidSale

    func seed(_ request: BillingDocumentRequest, in ledger: BillingTransactionLedger) async throws {
        let original = try BillingDocumentRequestDTO(request)
        let sale = SaleDTO(
            payloadVersion: original.sale.payloadVersion,
            id: original.sale.id,
            clientID: original.sale.clientID,
            createdAt: original.sale.createdAt,
            lines: original.sale.lines,
            status: self == .unpaidSale ? .draft : original.sale.status,
            globalDiscount: original.sale.globalDiscount
        )
        let transportedRequest = BillingDocumentRequestDTO(
            payloadVersion: self == .requestVersion ? 3 : 1,
            id: self == .requestIdentity ? "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" : original.id,
            documentID: self == .documentIdentity
                ? "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb" : original.documentID,
            kind: original.kind,
            requestedAt: original.requestedAt,
            sale: sale
        )
        let record = BillingDocumentRecordDTO(
            payloadVersion: self == .documentVersion ? 2 : 1,
            request: transportedRequest,
            series: self == .wrongSeries ? .invoice : .ticket,
            number: self == .zeroNumber ? 0 : self == .negativeNumber ? -1 : 41,
            issuedAt: self == .missingTimestamp ? nil : try SaleTimestampDTO(Date(timeIntervalSince1970: 190))
        )
        let binding = BillingRequestBindingDTO(
            payloadVersion: self == .bindingVersion ? 2 : 1,
            requestID: self == .bindingIdentity ? "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" : original.id,
            documentID: original.documentID
        )
        if self != .documentWithoutBinding {
            try await ledger.seedBinding(binding, at: original.id)
        }
        if self != .bindingWithoutDocument {
            try await ledger.seedDocument(record, at: original.documentID)
        }
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 41))
    }
}

func billingPrecisionRequest() throws -> BillingDocumentRequest {
    let first = try SaleLine.upcoming(
        id: SaleLineID(rawValue: viewModelUUID(101)),
        serviceID: ServiceID(rawValue: viewModelUUID(201)),
        serviceName: "Captured precise service",
        quantity: 2,
        unitPrice: Money(amount: viewModelDecimal("9007199254740993.01"), currency: .eur),
        taxRate: TaxRate(percentage: viewModelDecimal("21.123456789123456789")),
        discount: Discount(percentage: viewModelDecimal("12.3456789123456789")),
        linkedProductID: ProductID(rawValue: viewModelUUID(501))
    )
    let second = try viewModelLine(index: 102, quantity: 3)
    var sale = try Sale.draft(
        id: SaleID(rawValue: viewModelUUID(3)),
        clientID: ClientID(rawValue: viewModelUUID(600)),
        createdAt: Date(timeIntervalSinceReferenceDate: 0.12345678912345),
        lines: [second, first],
        globalDiscount: SaleGlobalDiscount(
            discount: Discount(percentage: viewModelDecimal("3.210987654321")),
            policy: .lineThenGlobalV1
        )
    )
    try sale.start()
    for line in sale.lines {
        try sale.startLine(id: line.id)
        try sale.completeLine(id: line.id)
    }
    try sale.registerPayment(
        id: PaymentID(rawValue: viewModelUUID(803)),
        method: .card,
        paidAt: Date(timeIntervalSinceReferenceDate: 0.98765432123456)
    )
    return try BillingDocumentRequest(
        id: BillingDocumentRequestID(rawValue: viewModelUUID(703)),
        documentID: BillingDocumentID(rawValue: viewModelUUID(803)),
        sale: sale,
        kind: .invoice,
        requestedAt: Date(timeIntervalSinceReferenceDate: 1.23456789123456)
    )
}

enum BillingTransactionFailure {
    case unavailable, permissionDenied, conflict, invalidResponse, privateTransport, nativeCancellation

    var error: any Error {
        switch self {
        case .unavailable: BillingDocumentReservationError.unavailable
        case .permissionDenied: BillingDocumentReservationError.permissionDenied
        case .conflict: BillingDocumentReservationError.conflict
        case .invalidResponse: BillingDocumentReservationError.invalidResponse
        case .privateTransport: BillingTransactionPrivateError.transportFailure
        case .nativeCancellation: CancellationError()
        }
    }
}

private enum BillingTransactionPrivateError: Error {
    case transportFailure
}

actor BillingRefusingTransactionDataSource: BillingTransactionDataSource {
    let failure: BillingTransactionFailure
    private(set) var calls = 0

    init(failure: BillingTransactionFailure) { self.failure = failure }

    func transact(
        request: BillingDocumentRequestDTO,
        plan: @escaping @Sendable (BillingTransactionSnapshot) throws -> BillingTransactionPlan
    ) throws -> BillingDocumentRecordDTO {
        calls += 1
        throw failure.error
    }
}

actor BillingSubstitutingTransactionDataSource: BillingTransactionDataSource {
    let response: BillingDocumentRecordDTO
    private(set) var calls = 0

    init(response: BillingDocumentRecordDTO) { self.response = response }

    func transact(
        request: BillingDocumentRequestDTO,
        plan: @escaping @Sendable (BillingTransactionSnapshot) throws -> BillingTransactionPlan
    ) -> BillingDocumentRecordDTO {
        calls += 1
        return response
    }
}
