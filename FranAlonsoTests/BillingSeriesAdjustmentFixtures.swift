import Foundation
@testable import FranAlonso

func seriesAdjustmentRequest(
    index: Int = 1,
    series: BillingDocumentSeries = .ticket,
    expected: Int64 = 40,
    target: Int64 = 50
) throws -> BillingSeriesAdjustmentRequest {
    try BillingSeriesAdjustmentRequest(
        operationID: viewModelUUID(9200 + index),
        series: series,
        expectedLastNumber: expected,
        targetLastNumber: target,
        reason: .seriesAlignment
    )
}

func seriesAdjustmentAudit(
    _ request: BillingSeriesAdjustmentRequest,
    principal: String = "admin-opaque-A",
    date: Date = Date(timeIntervalSince1970: 400)
) throws -> BillingSeriesAdjustmentAuditDTO {
    try BillingSeriesAdjustmentAuditDTO(
        payloadVersion: 1,
        request: BillingSeriesAdjustmentRequestDTO(request),
        principalID: principal,
        adjustedAt: SaleTimestampDTO(date)
    )
}

// If an inert RED implementation never reaches the seam, finish wakes the observer with false.
actor SeriesAdjustmentGate {
    private var entered = false
    private var finished = false
    private var released = false
    private var entryWaiters: [CheckedContinuation<Bool, Never>] = []
    private var releaseWaiters: [CheckedContinuation<Void, Never>] = []

    func enter() async {
        entered = true
        for waiter in entryWaiters {
            waiter.resume(returning: true)
        }
        entryWaiters.removeAll()
        guard !released else { return }
        await withCheckedContinuation {
            releaseWaiters.append($0)
        }
    }

    func waitUntilEntered() async -> Bool {
        if entered {
            return true
        }
        guard !finished else { return false }
        return await withCheckedContinuation {
            entryWaiters.append($0)
        }
    }

    func release() {
        released = true
        for waiter in releaseWaiters {
            waiter.resume()
        }
        releaseWaiters.removeAll()
    }

    func finish() {
        finished = true
        for waiter in entryWaiters {
            waiter.resume(returning: entered)
        }
        entryWaiters.removeAll()
        release()
    }
}

actor SeriesAdjustmentAuthorizer: BillingSeriesAdministrationAuthorizer {
    private var principal: String?
    private var failure: BillingSeriesAdjustmentError?
    private var gate: SeriesAdjustmentGate?
    private let gateAtCall: Int
    private(set) var requests: [BillingSeriesAdjustmentRequest] = []

    init(
        principal: String? = "admin-opaque-A",
        failure: BillingSeriesAdjustmentError? = nil,
        gate: SeriesAdjustmentGate? = nil,
        gateAtCall: Int = 1
    ) {
        self.principal = principal
        self.failure = failure
        self.gate = gate
        self.gateAtCall = gateAtCall
    }

    func replace(principal: String?) {
        self.principal = principal
    }

    func refuse(_ failure: BillingSeriesAdjustmentError) {
        self.failure = failure
    }

    func authorize(_ request: BillingSeriesAdjustmentRequest) async throws -> String {
        requests.append(request)
        let pendingGate = requests.count == gateAtCall ? gate : nil
        if pendingGate != nil {
            gate = nil
        }
        if let pendingGate {
            await pendingGate.enter()
        }
        if let failure {
            throw failure
        }
        guard let principal else { throw BillingSeriesAdjustmentError.permissionDenied }
        return principal
    }
}

enum SeriesAdjustmentInterruption { case beforeCommit, afterCommit }
enum SeriesAdjustmentReadKind { case adjustment, reservation }

struct SeriesAdjustmentLedgerState: Equatable {
    let audits: [String: Data]
    let bindings: [String: Data]
    let documents: [String: Data]
    let counters: [BillingDocumentSeries: Data]
    let commits: Int
}

// Optimistic deterministic transport model. It exercises both production plans but proves no live SDK guarantees.
actor SeriesAdjustmentLedger: BillingSeriesAdjustmentTransactionDataSource, BillingTransactionDataSource {
    private var audits: [String: Data] = [:]
    private var bindings: [String: Data] = [:]
    private var documents: [String: Data] = [:]
    private var counters: [BillingDocumentSeries: Data] = [:]
    private var version = 0
    private var commits = 0
    private var interruption: SeriesAdjustmentInterruption?
    private var responseGate: SeriesAdjustmentGate?
    private var readGate: SeriesAdjustmentGate?
    private let readKind: SeriesAdjustmentReadKind?
    private(set) var adjustmentCalls = 0
    private(set) var staleAttempts = 0

    init(
        interruption: SeriesAdjustmentInterruption? = nil,
        responseGate: SeriesAdjustmentGate? = nil,
        readGate: SeriesAdjustmentGate? = nil,
        readKind: SeriesAdjustmentReadKind? = nil
    ) {
        self.interruption = interruption
        self.responseGate = responseGate
        self.readGate = readGate
        self.readKind = readKind
    }

    func seedCounter(_ counter: BillingCounterDTO, at series: BillingDocumentSeries = .ticket) throws {
        counters[series] = try JSONEncoder().encode(counter)
    }

    func seedCounterBytes(_ bytes: Data, at series: BillingDocumentSeries = .ticket) {
        counters[series] = bytes
    }

    func seedAuditBytes(_ bytes: Data, at id: String) {
        audits[id] = bytes
    }

    func seedAudit(_ audit: BillingSeriesAdjustmentAuditDTO, at id: String) throws {
        audits[id] = try JSONEncoder().encode(audit)
    }

    func state() -> SeriesAdjustmentLedgerState {
        SeriesAdjustmentLedgerState(
            audits: audits,
            bindings: bindings,
            documents: documents,
            counters: counters,
            commits: commits
        )
    }

    func counter(_ series: BillingDocumentSeries) throws -> BillingCounterDTO? {
        try counters[series].map {
            try JSONDecoder().decode(BillingCounterDTO.self, from: $0)
        }
    }

    func audit(_ id: UUID) throws -> BillingSeriesAdjustmentAuditDTO? {
        try audits[id.uuidString].map {
            try JSONDecoder().decode(BillingSeriesAdjustmentAuditDTO.self, from: $0)
        }
    }

    func transact(
        request: BillingSeriesAdjustmentRequestDTO,
        principalID: String,
        plan: @escaping @Sendable (BillingSeriesAdjustmentTransactionSnapshot) throws -> BillingSeriesAdjustmentTransactionPlan
    ) async throws -> BillingSeriesAdjustmentAuditDTO {
        adjustmentCalls += 1
        let transported = try JSONDecoder().decode(
            BillingSeriesAdjustmentRequestDTO.self,
            from: JSONEncoder().encode(request)
        )
        while true {
            let readVersion = version
            let snapshot = BillingSeriesAdjustmentTransactionSnapshot(
                audit: auditState(at: transported.id),
                counter: counterState(at: transported.series)
            )
            await pauseFirstRead(.adjustment)
            guard readVersion == version else {
                staleAttempts += 1
                continue
            }
            let proposed = try plan(snapshot)
            let encoded = try JSONEncoder().encode(proposed)
            let transportedPlan = try JSONDecoder().decode(BillingSeriesAdjustmentTransactionPlan.self, from: encoded)
            let result: BillingSeriesAdjustmentAuditDTO
            switch transportedPlan {
            case let .replay(existing):
                result = existing
            case let .create(pending, counter):
                try interruptBeforeCommit()
                let committed = BillingSeriesAdjustmentAuditDTO(
                    payloadVersion: pending.payloadVersion,
                    request: pending.request,
                    principalID: pending.principalID,
                    adjustedAt: try SaleTimestampDTO(Date(timeIntervalSince1970: 400))
                )
                let auditBytes = try JSONEncoder().encode(committed)
                let counterBytes = try JSONEncoder().encode(counter)
                audits[transported.id] = auditBytes
                counters[transported.series] = counterBytes
                commits += 1
                version += 1
                result = committed
                try interruptAfterCommit()
            }
            let pendingGate = responseGate
            responseGate = nil
            if let pendingGate {
                await pendingGate.enter()
            }
            return result
        }
    }

    func transact(
        request: BillingDocumentRequestDTO,
        plan: @escaping @Sendable (BillingTransactionSnapshot) throws -> BillingTransactionPlan
    ) async throws -> BillingDocumentRecordDTO {
        let transported = try JSONDecoder().decode(BillingDocumentRequestDTO.self, from: JSONEncoder().encode(request))
        while true {
            let readVersion = version
            let snapshot = try BillingTransactionSnapshot(
                binding: bindings[transported.id].map {
                    try JSONDecoder().decode(BillingRequestBindingDTO.self, from: $0)
                },
                document: documents[transported.documentID].map {
                    try JSONDecoder().decode(BillingDocumentRecordDTO.self, from: $0)
                },
                counter: counterState(at: transported.kind.series)
            )
            await pauseFirstRead(.reservation)
            guard readVersion == version else {
                staleAttempts += 1
                continue
            }
            let proposed = try plan(snapshot)
            let encoded = try JSONEncoder().encode(proposed)
            let transportedPlan = try JSONDecoder().decode(BillingTransactionPlan.self, from: encoded)
            switch transportedPlan {
            case let .replay(existing):
                return existing
            case let .create(pending, binding, counter):
                let committed = BillingDocumentRecordDTO(
                    payloadVersion: pending.payloadVersion,
                    request: pending.request,
                    series: pending.series,
                    number: pending.number,
                    issuedAt: try SaleTimestampDTO(Date(timeIntervalSince1970: 410))
                )
                let documentBytes = try JSONEncoder().encode(committed)
                let bindingBytes = try JSONEncoder().encode(binding)
                let counterBytes = try JSONEncoder().encode(counter)
                documents[transported.documentID] = documentBytes
                bindings[transported.id] = bindingBytes
                counters[transported.kind.series] = counterBytes
                commits += 1
                version += 1
                return committed
            }
        }
    }

    private func pauseFirstRead(_ kind: SeriesAdjustmentReadKind) async {
        guard kind == readKind, let gate = readGate else { return }
        readGate = nil
        await gate.enter()
    }

    private func interruptBeforeCommit() throws {
        if interruption == .beforeCommit {
            interruption = nil
            throw BillingSeriesAdjustmentError.unavailable
        }
    }

    private func interruptAfterCommit() throws {
        if interruption == .afterCommit {
            interruption = nil
            throw BillingSeriesAdjustmentError.unavailable
        }
    }

    private func auditState(at id: String) -> BillingSeriesAdjustmentAuditState {
        guard let bytes = audits[id] else { return .absent }
        guard let value = try? JSONDecoder().decode(BillingSeriesAdjustmentAuditDTO.self, from: bytes) else {
            return .malformed
        }
        return .value(value)
    }

    private func counterState(at series: BillingDocumentSeries) -> BillingCounterState {
        guard let bytes = counters[series] else { return .absent }
        guard let value = try? JSONDecoder().decode(BillingCounterDTO.self, from: bytes) else { return .malformed }
        return .value(value)
    }
}

func seriesAdjustmentResult(
    _ request: BillingSeriesAdjustmentRequest,
    ledger: SeriesAdjustmentLedger,
    authorizer: SeriesAdjustmentAuthorizer,
    gate: SeriesAdjustmentGate
) async -> Result<BillingSeriesAdjustmentReceipt, any Error> {
    do {
        let receipt = try await FirestoreBillingSeriesAdjustmentRepository(dataSource: ledger, authorizer: authorizer)
            .adjust(request)
        await gate.finish()
        return .success(receipt)
    } catch {
        await gate.finish()
        return .failure(error)
    }
}

enum SeriesAdjustmentCounterCorruption {
    case unsupportedVersion, wrongSeries, negative, malformed, unknownField

    func bytes() throws -> Data {
        let counter = BillingCounterDTO(
            payloadVersion: self == .unsupportedVersion ? 2 : 1,
            series: self == .wrongSeries ? .invoice : .ticket,
            lastNumber: self == .negative ? -1 : 40
        )
        switch self {
        case .malformed:
            return Data("{\"lastNumber\":\"private-invalid\"}".utf8)
        case .unknownField:
            return try billingBytesWithUnknownField(counter)
        case .unsupportedVersion, .wrongSeries, .negative:
            return try JSONEncoder().encode(counter)
        }
    }
}

enum SeriesAdjustmentAuditCorruption {
    case unsupportedVersion, missingTimestamp, blankPrincipal, noncanonicalID, wrongRequestVersion
    case malformed, unknownField, nestedUnknownField

    func bytes(_ request: BillingSeriesAdjustmentRequest) throws -> Data {
        let original = BillingSeriesAdjustmentRequestDTO(request)
        let dto = BillingSeriesAdjustmentRequestDTO(
            payloadVersion: self == .wrongRequestVersion ? 2 : 1,
            id: self == .noncanonicalID ? "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa" : original.id,
            series: original.series,
            expectedLastNumber: original.expectedLastNumber,
            targetLastNumber: original.targetLastNumber,
            reason: original.reason
        )
        let audit = BillingSeriesAdjustmentAuditDTO(
            payloadVersion: self == .unsupportedVersion ? 2 : 1,
            request: dto,
            principalID: self == .blankPrincipal ? " \n " : "admin-opaque-A",
            adjustedAt: self == .missingTimestamp ? nil : try SaleTimestampDTO(Date(timeIntervalSince1970: 400))
        )
        switch self {
        case .malformed:
            return Data("{\"principalID\":false}".utf8)
        case .unknownField:
            return try billingBytesWithUnknownField(audit)
        case .nestedUnknownField:
            let data = try JSONEncoder().encode(audit)
            guard let text = String(data: data, encoding: .utf8) else {
                throw BillingSeriesAdjustmentError.invalidResponse
            }
            return Data(text.replacingOccurrences(of: "\"request\":{", with: "\"request\":{\"unsupported\":1,").utf8)
        case .unsupportedVersion, .missingTimestamp, .blankPrincipal, .noncanonicalID, .wrongRequestVersion:
            return try JSONEncoder().encode(audit)
        }
    }
}

actor SeriesAdjustmentSubstitutionSource: BillingSeriesAdjustmentTransactionDataSource {
    let response: BillingSeriesAdjustmentAuditDTO
    private(set) var calls = 0

    init(response: BillingSeriesAdjustmentAuditDTO) { self.response = response }

    func transact(
        request: BillingSeriesAdjustmentRequestDTO,
        principalID: String,
        plan: @escaping @Sendable (BillingSeriesAdjustmentTransactionSnapshot) throws -> BillingSeriesAdjustmentTransactionPlan
    ) -> BillingSeriesAdjustmentAuditDTO {
        calls += 1
        return response
    }
}
