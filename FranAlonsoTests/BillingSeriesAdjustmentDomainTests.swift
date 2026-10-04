import Foundation
import Testing
@testable import FranAlonso

@Suite("Administrative billing sequence commands")
struct BillingSeriesAdjustmentDomainTests {
    @Test(arguments: [
        BillingSeriesAdjustmentDomainBounds(expected: -1, target: 1),
        .init(expected: .min, target: 1),
        .init(expected: 0, target: 0),
        .init(expected: 0, target: -1),
        .init(expected: 40, target: 40),
        .init(expected: 40, target: 39),
        .init(expected: 40, target: .max),
        .init(expected: .max - 1, target: .max)
    ])
    func `invalid sequence heads never form an administrative command`(_ bounds: BillingSeriesAdjustmentDomainBounds) {
        #expect(throws: BillingSeriesAdjustmentError.invalidRequest) {
            _ = try BillingSeriesAdjustmentDomainFixtures.request(expected: bounds.expected, target: bounds.target)
        }
    }

    @Test(arguments: [
        BillingSeriesAdjustmentDomainBounds(expected: -1, target: 1),
        .init(expected: 0, target: 0),
        .init(expected: 0, target: -1),
        .init(expected: 40, target: 40),
        .init(expected: 40, target: 39),
        .init(expected: 40, target: .max)
    ])
    func `decoding cannot bypass an administrative command invariant`(_ bounds: BillingSeriesAdjustmentDomainBounds) {
        let payload = BillingSeriesAdjustmentDomainFixtures.requestPayload(
            expected: bounds.expected,
            target: bounds.target
        )

        #expect(throws: BillingSeriesAdjustmentError.invalidRequest) {
            _ = try JSONDecoder().decode(BillingSeriesAdjustmentRequest.self, from: payload)
        }
    }

    @Test(arguments: [
        "", " ", " administrator", "administrator ", "administrator/user",
        "administrator\tuser", "administrator\u{0000}user", "administrator\u{00A0}user"
    ])
    func `a malformed principal cannot appear in an accepted receipt`(_ principal: String) throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request()

        #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            _ = try BillingSeriesAdjustmentReceipt(
                request: request,
                principalID: principal,
                adjustedAt: BillingSeriesAdjustmentDomainFixtures.adjustedAt
            )
        }
    }

    @Test(arguments: [Double.infinity, -.infinity, .nan])
    func `a nonfinite authority timestamp never forms an accepted receipt`(_ seconds: Double) throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request()

        #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            _ = try BillingSeriesAdjustmentReceipt(
                request: request,
                principalID: BillingSeriesAdjustmentDomainFixtures.principalID,
                adjustedAt: Date(timeIntervalSince1970: seconds)
            )
        }
    }

    @Test(arguments: ["\"\"", "\"administrator/user\"", "\"administrator\\tuser\""])
    func `decoding an acceptance cannot bypass principal validation`(_ principalJSON: String) {
        let payload = BillingSeriesAdjustmentDomainFixtures.receiptPayload(principalJSON: principalJSON)
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970

        #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            _ = try decoder.decode(BillingSeriesAdjustmentReceipt.self, from: payload)
        }
    }

    @Test(arguments: ["\"Infinity\"", "\"-Infinity\"", "\"NaN\""])
    func `decoded nonfinite authority timestamps cannot bypass receipt validation`(_ timestampJSON: String) {
        let payload = BillingSeriesAdjustmentDomainFixtures.receiptPayload(
            principalJSON: "\"synthetic-billing-administrator\"",
            adjustedAtJSON: timestampJSON
        )
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .secondsSince1970
        decoder.nonConformingFloatDecodingStrategy = .convertFromString(
            positiveInfinity: "Infinity",
            negativeInfinity: "-Infinity",
            nan: "NaN"
        )

        #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            _ = try decoder.decode(BillingSeriesAdjustmentReceipt.self, from: payload)
        }
    }

    @Test(arguments: [
        BillingSeriesAdjustmentDomainAdvance(series: .ticket, expected: 0, target: 1),
        .init(series: .invoice, expected: 40, target: 90),
        .init(series: .ticket, expected: .max - 2, target: .max - 1),
        .init(series: .invoice, expected: 0, target: .max - 1)
    ])
    func `an allowed advance returns one original acceptance without another attempt`(
        _ advance: BillingSeriesAdjustmentDomainAdvance
    ) async throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request(
            series: advance.series,
            expected: advance.expected,
            target: advance.target
        )
        let original = try BillingSeriesAdjustmentDomainFixtures.receipt(request)
        let provider = BillingSeriesAdjustmentDomainRepositorySpy(response: original)

        let accepted = try await AdjustBillingSeriesUseCase(repository: provider)(request)

        #expect(accepted == original)
        #expect(accepted.adjustedAt == Date(timeIntervalSince1970: 400))
        #expect(await provider.received == [request])
    }

    @Test(arguments: [
        BillingSeriesAdjustmentDomainDifference.operationIdentity, .series, .expectedHead, .targetHead
    ])
    func `a substituted administrative acceptance is rejected after a single attempt`(
        _ difference: BillingSeriesAdjustmentDomainDifference
    ) async throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request()
        let substituted = try BillingSeriesAdjustmentDomainFixtures.differingRequest(request, difference: difference)
        let provider = BillingSeriesAdjustmentDomainRepositorySpy(
            response: try BillingSeriesAdjustmentDomainFixtures.receipt(substituted)
        )

        await #expect(throws: BillingSeriesAdjustmentError.invalidResponse) {
            try await AdjustBillingSeriesUseCase(repository: provider)(request)
        }

        #expect(await provider.received == [request])
    }

    @Test(arguments: [
        BillingSeriesAdjustmentError.invalidRequest, .permissionDenied, .conflict, .invalidResponse, .unavailable
    ])
    func `neutral repository failures retain their meaning without automatic retry`(
        _ error: BillingSeriesAdjustmentError
    ) async throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request()
        let provider = BillingSeriesAdjustmentDomainRepositorySpy(error: error)

        await #expect(throws: error) {
            try await AdjustBillingSeriesUseCase(repository: provider)(request)
        }

        #expect(await provider.received == [request])
    }

    @Test
    func `unknown infrastructure failures become unavailable after only one attempt`() async throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request()
        let provider = BillingSeriesAdjustmentDomainRepositorySpy(
            error: BillingSeriesAdjustmentDomainProviderFailure.privateFailure
        )

        await #expect(throws: BillingSeriesAdjustmentError.unavailable) {
            try await AdjustBillingSeriesUseCase(repository: provider)(request)
        }

        #expect(await provider.received == [request])
    }

    @Test
    func `native repository cancellation remains cancellation without automatic retry`() async throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request()
        let provider = BillingSeriesAdjustmentDomainRepositorySpy(error: CancellationError())

        await #expect(throws: CancellationError.self) {
            try await AdjustBillingSeriesUseCase(repository: provider)(request)
        }

        #expect(await provider.received == [request])
    }

    @Test
    func `cancellation before invocation prevents contacting the administrative repository`() async throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request()
        let provider = BillingSeriesAdjustmentDomainRepositorySpy(
            response: try BillingSeriesAdjustmentDomainFixtures.receipt(request)
        )
        let gate = RecoveryOperationGate()
        let task = Task {
            await gate.enter()
            do {
                let accepted = try await AdjustBillingSeriesUseCase(repository: provider)(request)
                await gate.finish()
                return accepted
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

        #expect(await provider.received.isEmpty)
    }

    @Test(arguments: [BillingSeriesAdjustmentDomainLateOutcome.receipt, .providerFailure])
    func `cancellation after contact rejects a late acceptance or failure`(
        _ outcome: BillingSeriesAdjustmentDomainLateOutcome
    ) async throws {
        let request = try BillingSeriesAdjustmentDomainFixtures.request()
        let gate = RecoveryOperationGate()
        let provider = BillingSeriesAdjustmentDomainRepositorySpy(
            response: try BillingSeriesAdjustmentDomainFixtures.receipt(request),
            error: outcome == .providerFailure ? BillingSeriesAdjustmentError.permissionDenied : nil,
            responseGate: gate
        )
        let task = Task {
            do {
                let accepted = try await AdjustBillingSeriesUseCase(repository: provider)(request)
                await gate.finish()
                return accepted
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = await task.result
            Issue.record("The adjustment task finished before its response gate")
            return
        }

        task.cancel()
        await gate.release()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }

        #expect(await provider.received == [request])
    }
}
