import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing cancellation during local recovery")
@MainActor
struct BillingDocumentRecoveryCancellationTests {
    @Test
    func cancellationWhileRereadingFailureReleasesBusyStateForExplicitRecovery() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let pause = BillingStoragePause()
        let reads = BillingMaterializationRecoveryReadGate(pause: pause)
        let local = BillingMaterializationRecoveryReadRepository(
            base: BillingMaterializationPipelineFixtures.local(container),
            reads: reads
        )
        let authority = BillingMaterializationAuthority(loseFirstResponse: true)
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: BillingMaterializationRenderer(),
            storage: InMemoryBillingDocumentPDFStorageRepository()
        )
        let store = BillingDocumentStore(
            reserve: ReserveBillingDocumentUseCase(repository: authority),
            materialize: engine
        )
        let request = try billingRenderingDocument().request
        let prepared = try await store.prepareDurable(request)
        let attempt = Task {
            do {
                let result = try await store.materialize()
                await pause.complete()
                return result
            } catch {
                await pause.complete()
                throw error
            }
        }
        let paused = await pause.waitUntilPausedOrCompleted()
        #expect(paused)
        #expect(store.isBusy)
        attempt.cancel()
        await pause.release()
        await #expect(throws: CancellationError.self) {
            _ = try await attempt.value
        }
        #expect(!store.isBusy)
        #expect(store.delivery == prepared)
        let recovered = try await store.recover(id: request.id)
        #expect(recovered?.request == request)
        #expect(recovered?.document == nil)
        #expect(recovered?.failure?.phase == .numbering)
        #expect(store.delivery == recovered)
    }
}

private actor BillingMaterializationRecoveryReadGate {
    private let pause: BillingStoragePause
    private var count = 0

    init(pause: BillingStoragePause) {
        self.pause = pause
    }

    func read() async {
        count += 1
        if count == 2 {
            await pause.wait()
        }
    }
}

private struct BillingMaterializationRecoveryReadRepository: BillingDocumentLocalRepository {
    let base: DefaultBillingDocumentLocalRepository
    let reads: BillingMaterializationRecoveryReadGate
    var principalID: String { base.principalID }

    func prepare(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery {
        try await base.prepare(request)
    }

    func delivery(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery? {
        await reads.read()
        return try await base.delivery(id: id)
    }

    func deliveries(saleID: SaleID) async throws -> [BillingDocumentDelivery] {
        try await base.deliveries(saleID: saleID)
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
