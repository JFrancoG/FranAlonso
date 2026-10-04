import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Billing captured task intention coordination")
@MainActor
struct BillingOperationCoordinatorTests {
    @Test("An old nil task snapshot cannot consume a newly requested recovery")
    func ignoresNilSnapshotAfterNewRecoveryRequest() async throws {
        let fixture = try makeFixture()
        let captured: BillingOperationRequest? = nil
        fixture.model.requestLoad()
        let requested = try #require(fixture.model.operationRequest)
        await fixture.model.performRequestedOperation(captured, in: ModelContext(fixture.container))
        #expect(fixture.model.operationRequest == requested)
        #expect(await fixture.reads.count == 0)
        #expect(!fixture.model.operationFailed)
        #expect(!fixture.model.recoveryFailed)
    }

    @Test("An obsolete completed task snapshot cannot clear a replacement recovery intention")
    func ignoresCompletedSnapshotAfterReplacementRequest() async throws {
        let fixture = try makeFixture()
        fixture.model.requestLoad()
        let completed = try #require(fixture.model.operationRequest)
        await fixture.model.performRequestedOperation(completed, in: ModelContext(fixture.container))
        fixture.model.requestLoad()
        let replacement = try #require(fixture.model.operationRequest)
        #expect(replacement.id != completed.id)
        await fixture.model.performRequestedOperation(completed, in: ModelContext(fixture.container))
        #expect(fixture.model.operationRequest == replacement)
        #expect(await fixture.reads.count == 1)
        #expect(!fixture.model.operationFailed)
        #expect(!fixture.model.recoveryFailed)
    }

    @Test("A duplicate suspended recovery performer cannot create a busy error or disable the retained form")
    func ignoresDuplicatePerformerDuringSuspendedRecovery() async throws {
        let gate = RecoveryOperationGate()
        let fixture = try makeFixture(gate: gate)
        fixture.model.requestLoad()
        let requested = try #require(fixture.model.operationRequest)
        let first = Task {
            await fixture.model.performRequestedOperation(requested, in: ModelContext(fixture.container))
            await gate.finish()
        }
        _ = try #require(await gate.waitForEntry())
        await fixture.model.performRequestedOperation(requested, in: ModelContext(fixture.container))
        #expect(fixture.model.operationRequest == requested)
        #expect(!fixture.model.operationFailed)
        #expect(!fixture.model.recoveryFailed)
        #expect(await fixture.reads.count == 1)
        await gate.release()
        await first.value
        #expect(fixture.model.operationRequest == nil)
        #expect(fixture.model.isEditing)
        #expect(!fixture.model.isBusy)
        #expect(!fixture.model.operationFailed)
        #expect(!fixture.model.recoveryFailed)
    }

    private func makeFixture(gate: RecoveryOperationGate? = nil) throws -> BillingCoordinatorFixture {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let reads = BillingCoordinatorReads(gate: gate)
        let local = BillingCoordinatorReadRepository(
            base: BillingMaterializationPipelineFixtures.local(container),
            reads: reads
        )
        let authority = BillingMaterializationAuthority()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: BillingMaterializationRenderer(),
            storage: InMemoryBillingDocumentPDFStorageRepository()
        )
        let model = BillingViewModel(
            sale: try billingRenderingDocument().request.sale,
            reserve: ReserveBillingDocumentUseCase(repository: authority),
            materialize: engine
        )
        return BillingCoordinatorFixture(container: container, reads: reads, model: model)
    }
}

private struct BillingCoordinatorFixture {
    let container: ModelContainer
    let reads: BillingCoordinatorReads
    let model: BillingViewModel<BillingMaterializationAuthority>
}

private actor BillingCoordinatorReads {
    let gate: RecoveryOperationGate?
    private(set) var count = 0

    init(gate: RecoveryOperationGate?) {
        self.gate = gate
    }

    func enter() async {
        count += 1
        await gate?.enter()
    }
}

private struct BillingCoordinatorReadRepository: BillingDocumentLocalRepository {
    let base: DefaultBillingDocumentLocalRepository
    let reads: BillingCoordinatorReads
    var principalID: String { base.principalID }

    func deliveries(saleID: SaleID) async throws -> [BillingDocumentDelivery] {
        await reads.enter()
        return try await base.deliveries(saleID: saleID)
    }

    func delivery(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery? {
        try await base.delivery(id: id)
    }

    func prepare(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery {
        try await base.prepare(request)
    }

    func accept(_ document: BillingDocument) async throws -> BillingDocumentDelivery {
        try await base.accept(document)
    }

    func acceptPDF(id: BillingDocumentRequestID, pdf: Data) async throws -> BillingDocumentDelivery {
        try await base.acceptPDF(id: id, pdf: pdf)
    }

    func beginUpload(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery {
        try await base.beginUpload(id: id)
    }

    func completeUpload(
        id: BillingDocumentRequestID,
        receipt: BillingPDFUploadReceipt
    ) async throws -> BillingDocumentDelivery {
        try await base.completeUpload(id: id, receipt: receipt)
    }

    func recordFailure(
        id: BillingDocumentRequestID,
        phase: BillingDocumentDeliveryPhase,
        reason: BillingDocumentFailure,
        attempt: Int?
    ) async throws {
        try await base.recordFailure(
            id: id,
            phase: phase,
            reason: reason,
            attempt: attempt
        )
    }
}
