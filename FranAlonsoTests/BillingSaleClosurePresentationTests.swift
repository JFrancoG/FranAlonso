import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Billing explicit sale closure presentation")
@MainActor
struct BillingSaleClosurePresentationTests {
    @Test(
        "closing a confirmed PDF does not require upload or invoke any billing motor",
        arguments: [BillingDocumentKind.ticket, .invoice]
    )
    func closesConfirmedPDFWithoutUploadOrBillingMotor(_ kind: BillingDocumentKind) async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make(kind: kind)
        let recorder = BillingSaleClosureRecorder()
        let model = fixture.model(recorder: recorder)
        _ = try await model.recover(saleID: fixture.document.saleID, kind: kind)
        #expect(model.canCloseSale)
        #expect(!fixture.delivery.isFinal)
        let accepted = try await model.closeSale(in: ModelContext(fixture.container))
        guard case let .closed(_, _, _, id, time) = accepted.status else {
            Issue.record("Explicit closure must publish the accepted terminal snapshot")
            return
        }
        #expect(id == fixture.document.id)
        #expect(time == Date(timeIntervalSince1970: 1_790_010_001))
        #expect(model.closedSale == accepted)
        #expect(model.delivery == fixture.delivery)
        #expect(await fixture.authority.requests.isEmpty)
        #expect(await fixture.renderer.calls == 0)
    }

    @Test(
        "missing definitive document or PDF rejects closure before its acceptance capability",
        arguments: [BillingPersistenceCheckpoint.prepared, .numbered]
    )
    func rejectsPendingDocumentBeforeAcceptance(_ checkpoint: BillingPersistenceCheckpoint) async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make(checkpoint: checkpoint)
        let recorder = BillingSaleClosureRecorder()
        let model = fixture.model(recorder: recorder)
        _ = try await model.recover(saleID: fixture.document.saleID)
        #expect(!model.canCloseSale)
        await #expect(throws: SaleClosureError.documentPending) {
            try await model.closeSale(in: ModelContext(fixture.container))
        }
        #expect(recorder.requests.isEmpty)
        #expect(model.closedSale == nil)
        #expect(model.delivery == fixture.delivery)
    }

    @Test("an explicit retry preserves the first closure request and date after local failure")
    func preservesClosureIdentityAndTimeAcrossRetry() async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make()
        let recorder = BillingSaleClosureRecorder()
        recorder.failsFirst = true
        let model = fixture.model(recorder: recorder)
        _ = try await model.recover(saleID: fixture.document.saleID)
        await #expect(throws: SaleClosureError.persistenceUnavailable) {
            try await model.closeSale(in: ModelContext(fixture.container))
        }
        #expect(model.closureFailure == .persistenceUnavailable)
        #expect(model.canCloseSale)
        _ = try await model.closeSale(in: ModelContext(fixture.container))
        #expect(recorder.requests.count == 2)
        #expect(recorder.requests.first == recorder.requests.last)
        #expect(recorder.clockReads == 1)
        #expect(model.closureFailure == nil)
    }

    @Test("simultaneous closure and generation cannot enter a second acceptance")
    func rejectsSimultaneousClosureAndGeneration() async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make()
        let gate = RecoveryOperationGate()
        let recorder = BillingSaleClosureRecorder(gate: gate)
        let model = fixture.model(recorder: recorder)
        _ = try await model.recover(saleID: fixture.document.saleID)
        let first = Task {
            do {
                let result = try await model.closeSale(in: ModelContext(fixture.container))
                await gate.finish()
                return result
            } catch {
                await gate.finish()
                throw error
            }
        }
        _ = try #require(await gate.waitForEntry())
        #expect(model.isBusy)
        #expect(!model.canCloseSale)
        await #expect(throws: BillingDocumentStoreError.operationInProgress) {
            try await model.closeSale(in: ModelContext(fixture.container))
        }
        await #expect(throws: BillingDocumentStoreError.operationInProgress) {
            try await model.materialize()
        }
        await gate.release()
        _ = try await first.value
        #expect(recorder.requests.count == 1)
    }

    @Test("closing presentation revokes a late accepted snapshot without discarding its PDF")
    func revokesLateAcceptanceAfterPresentationClose() async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make()
        let gate = RecoveryOperationGate()
        let recorder = BillingSaleClosureRecorder(gate: gate)
        let model = fixture.model(recorder: recorder)
        _ = try await model.recover(saleID: fixture.document.saleID)
        let attempt = Task {
            do {
                let result = try await model.closeSale(in: ModelContext(fixture.container))
                await gate.finish()
                return result
            } catch {
                await gate.finish()
                throw error
            }
        }
        _ = try #require(await gate.waitForEntry())
        model.close()
        await gate.release()
        await #expect(throws: CancellationError.self) {
            try await attempt.value
        }
        #expect(model.closedSale == nil)
        #expect(model.delivery == fixture.delivery)
        #expect(!model.isBusy)
    }

    @Test("parent session revocation denies closure although its principal remains known")
    func rejectsRevokedParentCapability() async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make()
        let recorder = BillingSaleClosureRecorder()
        let availability = BillingFormAvailability()
        let model = fixture.model(recorder: recorder, available: availability)
        _ = try await model.recover(saleID: fixture.document.saleID)
        availability.value = false
        #expect(!model.canCloseSale)
        await #expect(throws: SaleClosureError.unauthorized) {
            try await model.closeSale(in: ModelContext(fixture.container))
        }
        #expect(recorder.requests.isEmpty)
        #expect(model.closedSale == nil)
    }

    @Test("repeated accepted closure returns its retained snapshot without another write")
    func replaysAcceptedSnapshotWithoutAnotherWrite() async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make()
        let recorder = BillingSaleClosureRecorder()
        let model = fixture.model(recorder: recorder)
        _ = try await model.recover(saleID: fixture.document.saleID)
        let first = try await model.closeSale(in: ModelContext(fixture.container))
        let repeated = try await model.closeSale(in: ModelContext(fixture.container))
        #expect(repeated == first)
        #expect(recorder.requests.count == 1)
        #expect(recorder.clockReads == 1)
    }

    @Test("reopening discovers an invoice before the default ticket selection can allocate identities")
    func recoversInvoiceBeforeDefaultTicketSelection() async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make(kind: .invoice)
        let model = fixture.model(recorder: BillingSaleClosureRecorder())
        try await model.load()
        #expect(model.selectedKind == .invoice)
        #expect(model.request == fixture.document.request)
        #expect(model.delivery == fixture.delivery)
        #expect(model.canCloseSale)
        #expect(await fixture.authority.requests.isEmpty)
    }

    @Test("Preparing a recovered invoice replays its sealed family without another request or local row")
    func replaysRecoveredInvoicePreparationWithoutAnotherIdentity() async throws {
        let fixture = try await BillingSaleClosurePresentationFixture.make(kind: .invoice)
        let model = fixture.model(recorder: BillingSaleClosureRecorder())
        try await model.load()
        let replay = try await model.prepareSelectionDurable()
        #expect(replay == fixture.delivery)
        #expect(replay.request == fixture.document.request)
        #expect(model.selectedKind == .invoice)
        #expect(await fixture.authority.requests.isEmpty)
        #expect(try ModelContext(fixture.container).fetchCount(FetchDescriptor<BillingDocumentDeliveryModel>()) == 1)
    }

    @Test(
        "An explicit family choice recovers either saved document without preparing or mutating billing",
        arguments: [BillingDocumentKind.ticket, .invoice]
    )
    func recoversChosenFamilyWithoutCreatingIdentities(_ kind: BillingDocumentKind) async throws {
        let fixture = try await BillingSaleClosureRecoveryFixture.make()
        fixture.model.requestLoad()
        await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
        try #require(fixture.model.requiresDocumentSelection)
        #expect(fixture.model.canSelectKind)
        #expect(!fixture.model.isEditing)
        #expect(!fixture.model.operationFailed)
        fixture.model.selectKind(kind)
        #expect(fixture.model.selectedKind == kind)
        fixture.model.requestSelectedDocumentRecovery()
        await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
        let expected = try fixture.delivery(kind: kind)
        #expect(fixture.model.delivery == expected)
        #expect(fixture.model.request == expected.request)
        #expect(fixture.model.canCloseSale)
        #expect(!fixture.model.requiresDocumentSelection)
        #expect(!fixture.model.recoveryFailed)
        try await fixture.expectUnchangedBilling()
    }

    @Test("An ambiguous discovery blocks preparation and fiscal edits until explicit recovery is accepted")
    func blocksPreparationAndFiscalEditingDuringFamilyChoice() async throws {
        let fixture = try await BillingSaleClosureRecoveryFixture.make()
        fixture.model.requestLoad()
        await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
        fixture.model.selectKind(.invoice)
        #expect(fixture.model.selectedKind == .invoice)
        fixture.model.updateField(.taxIdentifier, value: "Must not replace the sealed fiscal snapshot")
        #expect(fixture.model.fieldValue(.taxIdentifier).isEmpty)
        fixture.model.requestPreparation()
        #expect(fixture.model.operationRequest == nil)
        await #expect(throws: BillingDocumentPersistenceError.ambiguousSelection) {
            try await fixture.model.prepareSelectionDurable()
        }
        #expect(fixture.model.request == nil)
        try await fixture.expectUnchangedBilling()
    }

    @Test(
        "An empty or failed family read preserves explicit choice and retries the same saved family",
        arguments: [BillingRecoveryReadOutcome.empty, .unavailable]
    )
    func retriesFamilyReadWithoutPreparingAnotherDocument(_ outcome: BillingRecoveryReadOutcome) async throws {
        let fixture = try await BillingSaleClosureRecoveryFixture.make()
        fixture.model.requestLoad()
        await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
        try #require(fixture.model.requiresDocumentSelection)
        fixture.model.selectKind(.invoice)
        await fixture.reads.respondNext(with: outcome)
        fixture.model.requestSelectedDocumentRecovery()
        await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
        #expect(fixture.model.requiresDocumentSelection)
        #expect(fixture.model.recoveryFailed)
        #expect(fixture.model.canSelectKind)
        #expect(!fixture.model.isEditing)
        #expect(fixture.model.request == nil)
        #expect(fixture.model.delivery == nil)
        #expect(!fixture.model.canCloseSale)
        try await fixture.expectUnchangedBilling()
        fixture.model.requestSelectedDocumentRecovery()
        await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
        let expected = try fixture.delivery(kind: .invoice)
        #expect(fixture.model.delivery == expected)
        #expect(!fixture.model.requiresDocumentSelection)
        #expect(!fixture.model.recoveryFailed)
        #expect(fixture.model.canCloseSale)
        try await fixture.expectUnchangedBilling()
    }

    @Test("Parent revocation during automatic recovery cannot publish a locally valid invoice")
    func rejectsLateAutomaticRecoveryAfterParentRevocation() async throws {
        let fixture = try await BillingSaleClosureRecoveryFixture.make(kinds: [.invoice])
        let gate = RecoveryOperationGate()
        await fixture.reads.pauseNext(with: gate)
        fixture.model.requestLoad()
        let task = Task {
            await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
            await gate.finish()
        }
        _ = try #require(await gate.waitForEntry())
        fixture.availability.value = false
        await gate.release()
        await task.value
        #expect(fixture.model.delivery == nil)
        #expect(fixture.model.request == nil)
        #expect(fixture.model.recoveryFailed)
        #expect(!fixture.model.canCloseSale)
        try await fixture.expectUnchangedBilling()
    }

    @Test("Parent revocation during chosen recovery retains the choice without publishing its document")
    func rejectsLateChosenRecoveryAfterParentRevocation() async throws {
        let fixture = try await BillingSaleClosureRecoveryFixture.make()
        fixture.model.requestLoad()
        await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
        try #require(fixture.model.requiresDocumentSelection)
        fixture.model.selectKind(.invoice)
        let gate = RecoveryOperationGate()
        await fixture.reads.pauseNext(with: gate)
        fixture.model.requestSelectedDocumentRecovery()
        let task = Task {
            await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
            await gate.finish()
        }
        _ = try #require(await gate.waitForEntry())
        fixture.availability.value = false
        await gate.release()
        await task.value
        #expect(fixture.model.delivery == nil)
        #expect(fixture.model.request == nil)
        #expect(fixture.model.requiresDocumentSelection)
        #expect(fixture.model.recoveryFailed)
        #expect(!fixture.model.canCloseSale)
        try await fixture.expectUnchangedBilling()
    }

    @Test(
        "Cancelled or closed chosen recovery cannot publish a late document or change its captured family",
        arguments: [false, true]
    )
    func revokesChosenRecoveryPublication(_ closesPresentation: Bool) async throws {
        let fixture = try await BillingSaleClosureRecoveryFixture.make()
        fixture.model.requestLoad()
        await fixture.model.performRequestedOperation(in: ModelContext(fixture.container))
        try #require(fixture.model.requiresDocumentSelection)
        fixture.model.selectKind(.invoice)
        let gate = RecoveryOperationGate()
        await fixture.reads.pauseNext(with: gate)
        fixture.model.requestSelectedDocumentRecovery()
        let captured = try #require(fixture.model.operationRequest)
        let announcement = fixture.model.operationAnnouncementID
        let task = Task {
            await fixture.model.performRequestedOperation(captured, in: ModelContext(fixture.container))
            await gate.finish()
        }
        _ = try #require(await gate.waitForEntry())
        fixture.model.selectKind(.ticket)
        #expect(fixture.model.selectedKind == .invoice)
        if closesPresentation {
            fixture.model.close()
        } else {
            task.cancel()
        }
        await gate.release()
        await task.value
        #expect(fixture.model.delivery == nil)
        #expect(fixture.model.request == nil)
        #expect(fixture.model.operationAnnouncementID == announcement)
        #expect(!fixture.model.operationFailed)
        #expect(!fixture.model.canCloseSale)
        try await fixture.expectUnchangedBilling()
    }
}
