import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing fiscal request transaction identity")
struct BillingFiscalRequestTransactionTests {
    @Test(arguments: [
        BillingFiscalField.displayName, .taxIdentifier, .streetLine, .postalCode, .city, .province
    ])
    func `changing any fiscal field conflicts without consuming another number or replacing history`(
        _ field: BillingFiscalField
    ) async throws {
        let request = try fiscalTransactionRequest()
        let ledger = BillingTransactionLedger()
        let repository = FirestoreBillingDocumentReservationRepository(dataSource: ledger)
        let original = try await repository.reserve(request)
        let committed = await ledger.state()
        var changedInput = billingFiscalInput()
        changedInput[field] += " changed"
        let changed = try fiscalTransactionRequest(recipient: BillingFiscalRecipient(changedInput))

        await #expect(throws: BillingDocumentReservationError.conflict) {
            try await repository.reserve(changed)
        }

        #expect(await ledger.state() == committed)
        #expect(try await repository.reserve(request) == original)
        #expect(await ledger.state().commits == 1)
        #expect(try await ledger.counter(.invoice)?.lastNumber == 1)
        #expect(try await ledger.counter(.ticket) == nil)
    }

    @Test
    func `an invoice whose response was lost recovers its fiscal snapshot through a fresh repository with one commit`() async throws {
        let request = try fiscalTransactionRequest()
        let ledger = BillingTransactionLedger(interruption: .afterCommit)

        await #expect(throws: BillingDocumentReservationError.unavailable) {
            try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
        }
        let committed = await ledger.state()
        let recovered = try await FirestoreBillingDocumentReservationRepository(dataSource: ledger).reserve(request)
        let recipient = try #require(recovered.request.fiscalRecipient)

        #expect(recipient.taxIdentifier == "doc-ID/Ñ")
        #expect(recipient.billingAddress.postalCode == "SW1A 1AA")
        #expect(recovered.number.value == 1)
        #expect(await ledger.state() == committed)
        #expect(committed.commits == 1)
        #expect(await ledger.calls == 2)
    }

    @Test
    func `the inactive reservation composition exposes unavailable without inventing an allocation`() async throws {
        let request = try billingTransactionRequest()

        await #expect(throws: BillingDocumentReservationError.unavailable) {
            try await UnavailableBillingDocumentReservationRepository().reserve(request)
        }
    }

    @Test
    func `native cancellation takes precedence over inactive reservation failure`() async throws {
        let request = try billingTransactionRequest()
        let gate = RecoveryOperationGate()
        let task = Task {
            await gate.enter()
            do {
                let result = try await UnavailableBillingDocumentReservationRepository().reserve(request)
                await gate.finish()
                return result
            } catch {
                await gate.finish()
                throw error
            }
        }
        guard await gate.waitForEntry() else {
            _ = await task.result
            Issue.record("The inactive invocation completed before its cancellation gate")
            return
        }
        task.cancel()
        await gate.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
    }
}

private func fiscalTransactionRequest(recipient: BillingFiscalRecipient? = nil) throws -> BillingDocumentRequest {
    try BillingDocumentRequest(
        id: BillingDocumentRequestID(rawValue: viewModelUUID(1701)),
        documentID: BillingDocumentID(rawValue: viewModelUUID(1801)),
        sale: viewModelSale(stage: .awaitingDocument),
        kind: .invoice,
        requestedAt: Date(timeIntervalSinceReferenceDate: 1),
        fiscalRecipient: try recipient ?? BillingFiscalRecipient(billingFiscalInput())
    )
}
