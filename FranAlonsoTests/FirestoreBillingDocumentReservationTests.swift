import FirebaseFirestore
import Foundation
import Testing
@testable import FranAlonso

@Suite("Firestore billing reservation transaction")
struct FirestoreBillingDocumentReservationTests {
    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `creation atomically stores the paid document binding and independent counter and replay writes nothing`(
        _ kind: BillingDocumentKind
    ) async throws {
        let request = try billingTransactionRequest(kind: kind)
        let ledger = BillingTransactionLedger()
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40))
        try await ledger.seedCounter(BillingCounterDTO(payloadVersion: 1, series: .invoice, lastNumber: 90))

        let first = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
        let committed = await ledger.state()
        let replayed = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)

        #expect(first.request == request)
        #expect(first.number.value == (kind == .ticket ? 41 : 91))
        #expect(first.number.series == kind.series)
        #expect(first.issuedAt == Date(timeIntervalSince1970: 190))
        #expect(replayed == first)
        #expect(committed.bindings.count == 1)
        #expect(committed.documents.count == 1)
        #expect(committed.commits == 1)
        #expect(await ledger.state() == committed)
        #expect(try await ledger.counter(.ticket)?.lastNumber == (kind == .ticket ? 41 : 40))
        #expect(try await ledger.counter(.invoice)?.lastNumber == (kind == .invoice ? 91 : 90))
    }

    @Test(arguments: [BillingDocumentKind.ticket, .invoice])
    func `an absent counter starts its family at one without creating another family counter`(
        _ kind: BillingDocumentKind
    ) async throws {
        let ledger = BillingTransactionLedger()
        let request = try billingTransactionRequest(kind: kind)

        let document = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)

        #expect(document.number.value == 1)
        #expect(document.number.series == kind.series)
        #expect(try await ledger.counter(kind.series)?.lastNumber == 1)
        #expect(try await ledger.counter(kind == .ticket ? .invoice : .ticket) == nil)
        #expect(await ledger.state().commits == 1)
    }

    @Test(arguments: [BillingTransactionChangedRequest.documentIdentity, .family, .requestedAt, .sale])
    func `reusing a request identity with different accepted content conflicts and preserves all records`(
        _ difference: BillingTransactionChangedRequest
    ) async throws {
        let request = try billingTransactionRequest()
        let ledger = BillingTransactionLedger()
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let original = try await repository.reserve(request)
        let committed = await ledger.state()
        let changed = try difference.change(request)

        await #expect(throws: BillingDocumentReservationError.conflict) {
            try await repository.reserve(changed)
        }

        #expect(await ledger.state() == committed)
        #expect(try await repository.reserve(request) == original)
        #expect(await ledger.state() == committed)
    }

    @Test
    func `an occupied document identity cannot be assigned to another request or family`() async throws {
        let request = try billingTransactionRequest()
        let ledger = BillingTransactionLedger()
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let original = try await repository.reserve(request)
        let committed = await ledger.state()
        let collision = try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: viewModelUUID(712)),
            documentID: request.documentID,
            sale: viewModelSale(index: 2, stage: .awaitingDocument),
            kind: .invoice,
            requestedAt: Date(timeIntervalSince1970: 201)
        )

        await #expect(throws: BillingDocumentReservationError.conflict) {
            try await repository.reserve(collision)
        }

        #expect(await ledger.state() == committed)
        #expect(try await repository.reserve(request) == original)
        #expect(try await ledger.counter(.invoice) == nil)
    }

    @Test(arguments: [BillingTransactionInterruption.beforeCommit, .afterCommit])
    func `interruption before or after commitment recovers with exactly one allocation on explicit retry`(
        _ interruption: BillingTransactionInterruption
    ) async throws {
        let ledger = BillingTransactionLedger(interruption: interruption)
        let request = try billingTransactionRequest()
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)

        await #expect(throws: BillingDocumentReservationError.unavailable) {
            try await repository.reserve(request)
        }
        let interrupted = await ledger.state()
        #expect(interrupted.commits == (interruption == .beforeCommit ? 0 : 1))
        #expect(interrupted.documents.count == (interruption == .beforeCommit ? 0 : 1))
        #expect(interrupted.bindings.count == interrupted.documents.count)
        #expect(interrupted.counters.count == interrupted.documents.count)

        let recovered = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)

        #expect(recovered.request == request)
        #expect(recovered.number.value == 1)
        #expect(recovered.issuedAt == Date(timeIntervalSince1970: 190))
        #expect(await ledger.state().commits == 1)
        #expect(await ledger.state().documents.count == 1)
        #expect(await ledger.state().bindings.count == 1)
        #expect(try await ledger.counter(.ticket)?.lastNumber == 1)
        #expect(await ledger.calls == 2)
    }

    @Test(arguments: [BillingTransactionConcurrentRequests.distinct, .identical, .documentCollision])
    func `shared snapshots are replanned under contention without duplicates or consumed conflict numbers`(
        _ scenario: BillingTransactionConcurrentRequests
    ) async throws {
        let first = try billingTransactionRequest()
        let second = try scenario.secondRequest(first)
        let barrier = BillingTransactionReadBarrier()
        let ledger = BillingTransactionLedger(readBarrier: barrier)
        async let firstResult = billingConcurrentResult(first, ledger: ledger, barrier: barrier)
        async let secondResult = billingConcurrentResult(second, ledger: ledger, barrier: barrier)
        let results = await [firstResult, secondResult]
        let successes = results.compactMap { try? $0.get() }
        let conflicts = results.filter {
            if case let .failure(error) = $0 {
                return error as? BillingDocumentReservationError == .conflict
            }
            return false
        }

        switch scenario {
        case .distinct:
            #expect(successes.count == 2)
            #expect(successes.map(\.number.value).sorted() == [1, 2])
            #expect(Set(successes.map(\.id)) == Set([first.documentID, second.documentID]))
            #expect(await ledger.state().commits == 2)
        case .identical:
            #expect(successes.count == 2)
            #expect(successes.first == successes.last)
            #expect(successes.first?.number.value == 1)
            #expect(await ledger.state().commits == 1)
        case .documentCollision:
            #expect(successes.count == 1)
            #expect(conflicts.count == 1)
            #expect(successes.first?.number.value == 1)
            #expect(await ledger.state().commits == 1)
        }
        let state = await ledger.state()
        #expect(state.documents.count == state.commits)
        #expect(state.bindings.count == state.commits)
        #expect(try await ledger.counter(.ticket)?.lastNumber == Int64(state.commits))
        #expect(await ledger.staleAttempts == 1)
    }

    @Test(arguments: [ReservationResponseOutcome.acceptedResponse, .providerError])
    func `cancellation after commitment hides late success or error and keeps the document recoverable`(
        _ outcome: ReservationResponseOutcome
    ) async throws {
        let request = try billingTransactionRequest()
        let gate = RecoveryOperationGate()
        let ledger = BillingTransactionLedger(
            responseGate: gate,
            responseError: outcome == .providerError ? .permissionDenied : nil
        )
        let task = Task {
            do {
                let result = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
                await gate.finish()
                return result
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = await task.result
            Issue.record("The reservation completed before the committed-response gate")
            return
        }
        let committed = await ledger.state()
        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        let recovered = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)

        #expect(recovered.request == request)
        #expect(recovered.number.value == 1)
        #expect(recovered.issuedAt == Date(timeIntervalSince1970: 190))
        #expect(committed.commits == 1)
        #expect(await ledger.state() == committed)
    }

    @Test(arguments: [BillingTransactionUnknownField.request, .record, .binding, .counter])
    func `unknown billing transport fields are rejected without overwriting remote state`(
        _ field: BillingTransactionUnknownField
    ) async throws {
        let request = try billingTransactionRequest()
        let ledger = BillingTransactionLedger()
        let binding = billingTransactionBinding(request)
        let record = try billingTransactionRecord(request)
        switch field {
        case .request:
            try await ledger.seedBinding(binding, at: request.id.rawValue.uuidString)
            await ledger.seedDocumentBytes(
                try billingRecordBytesWithUnknownRequestField(record),
                at: request.documentID.rawValue.uuidString
            )
        case .record:
            try await ledger.seedBinding(binding, at: request.id.rawValue.uuidString)
            await ledger.seedDocumentBytes(
                try billingBytesWithUnknownField(record),
                at: request.documentID.rawValue.uuidString
            )
        case .binding:
            try await ledger.seedDocument(record, at: request.documentID.rawValue.uuidString)
            await ledger.seedBindingBytes(try billingBytesWithUnknownField(binding), at: request.id.rawValue.uuidString)
        case .counter:
            await ledger.seedCounterBytes(
                try billingBytesWithUnknownField(BillingCounterDTO(payloadVersion: 1, series: .ticket, lastNumber: 40)),
                series: .ticket
            )
        }
        let before = await ledger.state()

        await #expect(throws: BillingDocumentReservationError.invalidResponse) {
            try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
        }

        #expect(await ledger.state() == before)
        #expect(before.commits == 0)
    }

    @Test(arguments: [
        BillingTransactionCorruption.bindingWithoutDocument,
        .documentWithoutBinding,
        .bindingVersion,
        .bindingIdentity,
        .documentVersion,
        .requestVersion,
        .requestIdentity,
        .documentIdentity,
        .wrongSeries,
        .zeroNumber,
        .negativeNumber,
        .missingTimestamp,
        .unpaidSale
    ])
    func `orphaned or invalid immutable records cannot be repaired or replayed as confirmed documents`(
        _ corruption: BillingTransactionCorruption
    ) async throws {
        let request = try billingTransactionRequest()
        let ledger = BillingTransactionLedger()
        try await corruption.seed(request, in: ledger)
        let before = await ledger.state()

        await #expect(throws: BillingDocumentReservationError.invalidResponse) {
            try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
        }

        #expect(await ledger.state() == before)
        #expect(before.commits == 0)
    }

    @Test(arguments: [
        BillingTransactionInvalidCounter.unsupportedVersion,
        .wrongSeries,
        .negative,
        .malformed,
        .exhausted,
        .unknownField
    ])
    func `invalid or exhausted counters cannot create any part of an allocation`(
        _ invalid: BillingTransactionInvalidCounter
    ) async throws {
        let request = try billingTransactionRequest()
        let ledger = BillingTransactionLedger()
        try await invalid.seed(ledger)
        let before = await ledger.state()

        await #expect(throws: BillingDocumentReservationError.invalidResponse) {
            try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
        }

        #expect(await ledger.state() == before)
        #expect(before.documents.isEmpty)
        #expect(before.bindings.isEmpty)
        #expect(before.commits == 0)
    }

    @Test(arguments: [
        BillingTransactionInvalidCounter.unsupportedVersion,
        .wrongSeries,
        .negative,
        .malformed,
        .exhausted,
        .unknownField
    ])
    func `a valid immutable document remains recoverable without repairing an invalid counter`(
        _ invalid: BillingTransactionInvalidCounter
    ) async throws {
        let request = try billingTransactionRequest()
        let ledger = BillingTransactionLedger()
        try await ledger.seedDocument(billingTransactionRecord(request), at: request.documentID.rawValue.uuidString)
        try await ledger.seedBinding(billingTransactionBinding(request), at: request.id.rawValue.uuidString)
        try await invalid.seed(ledger)
        let before = await ledger.state()

        let replayed = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)

        #expect(replayed.request == request)
        #expect(replayed.number.value == 41)
        #expect(replayed.issuedAt == Date(timeIntervalSince1970: 190))
        #expect(await ledger.state() == before)
        #expect(before.commits == 0)
    }

    @Test
    func `Codable transaction transport retains decimal precision line order payment and exact date bits`() async throws {
        let request = try billingPrecisionRequest()
        let ledger = BillingTransactionLedger()

        let document = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
        let replayed = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)

        #expect(document.request == request)
        #expect(replayed == document)
        #expect(document.request.sale.lines.map(\.id) == [
            SaleLineID(rawValue: viewModelUUID(102)),
            SaleLineID(rawValue: viewModelUUID(101))
        ])
        #expect(document.request.sale.lines.last?.unitPrice.amount == (try viewModelDecimal("9007199254740993.01")))
        #expect(document.request.sale.createdAt.timeIntervalSinceReferenceDate.bitPattern
            == (0.12345678912345).bitPattern)
        #expect(document.request.requestedAt.timeIntervalSinceReferenceDate.bitPattern
            == (1.23456789123456).bitPattern)
        #expect(await ledger.state().commits == 1)
    }

    @Test(arguments: [
        BillingTransactionFailure.unavailable,
        .permissionDenied,
        .conflict,
        .invalidResponse,
        .privateTransport,
        .nativeCancellation
    ])
    func `transaction failures retain neutral meaning or cancellation without automatic repository retries`(
        _ failure: BillingTransactionFailure
    ) async throws {
        let request = try billingTransactionRequest()
        let source = BillingRefusingTransactionDataSource(failure: failure)
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: source)
        switch failure {
        case .nativeCancellation:
            await #expect(throws: CancellationError.self) {
                try await repository.reserve(request)
            }
        case .privateTransport:
            await #expect(throws: BillingDocumentReservationError.unavailable) {
                try await repository.reserve(request)
            }
        case .unavailable, .permissionDenied, .conflict, .invalidResponse:
            let expected = try #require(failure.error as? BillingDocumentReservationError)
            await #expect(throws: expected) {
                try await repository.reserve(request)
            }
        }
        #expect(await source.calls == 1)
    }

    @Test
    func `cancellation before invocation prevents entering the transaction seam`() async throws {
        let request = try billingTransactionRequest()
        let ledger = BillingTransactionLedger()
        let gate = RecoveryOperationGate()
        let task = Task {
            await gate.enter()
            do {
                let result = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
                await gate.finish()
                return result
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = await task.result
            Issue.record("The invocation completed before its cancellation gate")
            return
        }
        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }

        #expect(await ledger.calls == 0)
        #expect(await ledger.state().documents.isEmpty)
        #expect(await ledger.state().bindings.isEmpty)
        #expect(await ledger.state().counters.isEmpty)
    }

    @Test
    func `a foreign confirmed provider response is rejected instead of substituting the requested allocation`() async throws {
        let request = try billingTransactionRequest()
        let foreign = try billingTransactionRequest(index: 2, kind: .invoice)
        let source = BillingSubstitutingTransactionDataSource(response: try billingTransactionRecord(foreign))

        await #expect(throws: BillingDocumentReservationError.invalidResponse) {
            try await FirestoreBillingDocumentReservationRepository(dataSource: source).reserve(request)
        }

        #expect(await source.calls == 1)
    }

    @Test
    func `SDK write uses a server timestamp and only the resolved server record confirms the allocation`() throws {
        let request = try billingPrecisionRequest()
        let pending = try BillingDocumentRecordDTO(
            payloadVersion: 1,
            request: BillingDocumentRequestDTO(request),
            series: .invoice,
            number: 91,
            issuedAt: nil
        )
        var fields = try Firestore.Encoder().encode(FirestoreBillingDocumentDTO(pending))
        let serverTimestamp = try #require(fields["issuedAt"] as? FieldValue)
        #expect(serverTimestamp.isEqual(FieldValue.serverTimestamp()))
        fields["issuedAt"] = Timestamp(date: Date(timeIntervalSince1970: 190))
        let decoded = try Firestore.Decoder().decode(FirestoreBillingDocumentDTO.self, from: fields)

        let document = try decoded.toRecord(documentID: request.documentID.rawValue.uuidString).toDomain()

        #expect(document.request == request)
        #expect(document.number.value == 91)
        #expect(document.number.series == .invoice)
        #expect(document.issuedAt == Date(timeIntervalSince1970: 190))
    }

    @Test(arguments: [
        BillingSDKRecordCorruption.missingServerDate,
        .documentVersion,
        .requestVersion,
        .requestIdentity,
        .documentIdentity,
        .wrongSeries,
        .zeroNumber,
        .negativeNumber,
        .pathMismatch
    ])
    func `SDK decoded records reject invalid confirmation metadata or a different document path`(
        _ corruption: BillingSDKRecordCorruption
    ) throws {
        let request = try billingTransactionRequest()
        let envelope = FirestoreBillingDocumentDTO(try billingTransactionRecord(request))
        var fields = try Firestore.Encoder().encode(envelope)
        var path = request.documentID.rawValue.uuidString
        switch corruption {
        case .missingServerDate:
            fields["issuedAt"] = NSNull()
        case .documentVersion:
            fields["payloadVersion"] = 2
        case .requestVersion, .requestIdentity, .documentIdentity:
            var nested = try #require(fields["request"] as? [String: Any])
            switch corruption {
            case .requestVersion:
                nested["payloadVersion"] = 3
            case .requestIdentity:
                nested["id"] = "aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa"
            case .documentIdentity:
                nested["documentID"] = "bbbbbbbb-bbbb-bbbb-bbbb-bbbbbbbbbbbb"
            default:
                break
            }
            fields["request"] = nested
        case .wrongSeries:
            fields["series"] = "invoice"
        case .zeroNumber:
            fields["number"] = Int64(0)
        case .negativeNumber:
            fields["number"] = Int64(-1)
        case .pathMismatch:
            path = viewModelUUID(819).uuidString
        }
        let decoded = try Firestore.Decoder().decode(FirestoreBillingDocumentDTO.self, from: fields)

        #expect(throws: BillingDocumentReservationError.invalidResponse) {
            try decoded.toRecord(documentID: path)
        }
    }

    @Test(arguments: [BillingSDKUnknownField.record, .request])
    func `SDK decoder refuses unknown billing document and request fields`(_ field: BillingSDKUnknownField) throws {
        let request = try billingTransactionRequest()
        var fields = try Firestore.Encoder().encode(FirestoreBillingDocumentDTO(billingTransactionRecord(request)))
        switch field {
        case .record:
            fields["unexpected"] = true
        case .request:
            var nested = try #require(fields["request"] as? [String: Any])
            nested["unexpected"] = true
            fields["request"] = nested
        }

        #expect(throws: DecodingError.self) {
            try Firestore.Decoder().decode(FirestoreBillingDocumentDTO.self, from: fields)
        }
    }
}

enum BillingTransactionChangedRequest {
    case documentIdentity, family, requestedAt, sale

    func change(_ request: BillingDocumentRequest) throws -> BillingDocumentRequest {
        try BillingDocumentRequest(
            id: request.id,
            documentID: self == .documentIdentity
                ? BillingDocumentID(rawValue: viewModelUUID(819)) : request.documentID,
            sale: self == .sale ? viewModelSale(index: 2, stage: .awaitingDocument) : request.sale,
            kind: self == .family ? .invoice : request.kind,
            requestedAt: self == .requestedAt ? Date(timeIntervalSince1970: 202) : request.requestedAt
        )
    }
}

enum BillingTransactionConcurrentRequests {
    case distinct, identical, documentCollision

    func secondRequest(_ first: BillingDocumentRequest) throws -> BillingDocumentRequest {
        switch self {
        case .identical:
            first
        case .distinct:
            try billingTransactionRequest(index: 2)
        case .documentCollision:
            try BillingDocumentRequest(
                id: BillingDocumentRequestID(rawValue: viewModelUUID(702)),
                documentID: first.documentID,
                sale: viewModelSale(index: 2, stage: .awaitingDocument),
                kind: .ticket,
                requestedAt: Date(timeIntervalSince1970: 201)
            )
        }
    }
}

enum BillingTransactionUnknownField {
    case request, record, binding, counter
}

enum BillingSDKRecordCorruption {
    case missingServerDate, documentVersion, requestVersion, requestIdentity, documentIdentity
    case wrongSeries, zeroNumber, negativeNumber, pathMismatch
}

enum BillingSDKUnknownField {
    case record, request
}
