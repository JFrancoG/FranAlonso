import Foundation
import Synchronization
import Testing
@testable import FranAlonso

@Suite("Billing durable presentation authority") @MainActor
struct BillingDocumentMaterializationStoreTests {
    @Test
    func reopenedSelectionDiscoversBeforeGeneratingNewIdentities() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let local = BillingMaterializationPipelineFixtures.local(container)
        let authority = BillingMaterializationAuthority()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: BillingMaterializationRenderer(),
            storage: InMemoryBillingDocumentPDFStorageRepository()
        )
        let request = try billingRenderingDocument().request
        _ = try await local.prepare(request)
        let generated = Mutex(0)
        let prepare = PrepareBillingDocumentRequestUseCase(makeRequestID: {
            generated.withLock {
                $0 += 1
            }
            return BillingDocumentRequestID(rawValue: UUID())
        })
        let model = BillingViewModel(
            sale: request.sale,
            reserve: ReserveBillingDocumentUseCase(repository: authority),
            prepare: prepare,
            materialize: engine
        )
        #expect(model.prepareSelection() == nil)
        #expect(generated.withLock { $0 } == 0)
        #expect(try await model.prepareSelectionDurable().request == request)
        #expect(generated.withLock { $0 } == 0)
        #expect(model.request == request)
    }

    @Test
    func twoFamiliesRequireExplicitSelectionOnRecovery() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let local = BillingMaterializationPipelineFixtures.local(container)
        let ticket = try billingRenderingDocument().request
        let invoice = try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: UUID()),
            documentID: BillingDocumentID(rawValue: UUID()),
            sale: ticket.sale,
            kind: .invoice,
            requestedAt: ticket.requestedAt,
            fiscalRecipient: billingRenderingFiscalRecipient()
        )
        _ = try await local.prepare(ticket)
        _ = try await local.prepare(invoice)
        let authority = BillingMaterializationAuthority()
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
        await #expect(throws: BillingDocumentPersistenceError.ambiguousSelection) {
            _ = try await store.recover(saleID: ticket.sale.id)
        }
        #expect(store.delivery == nil)
        #expect(try await store.recover(saleID: ticket.sale.id, kind: .invoice)?.request == invoice)
    }
    @Test
    func configuredModeRejectsEphemeralPreparationAndNewFacadeDiscoversSavedRequest() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let local = BillingMaterializationPipelineFixtures.local(container)
        let authority = BillingMaterializationAuthority()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: BillingMaterializationRenderer(),
            storage: InMemoryBillingDocumentPDFStorageRepository()
        )
        let request = try billingRenderingDocument().request
        let store = BillingDocumentStore(
            reserve: ReserveBillingDocumentUseCase(repository: authority),
            materialize: engine
        )
        #expect(throws: BillingDocumentStoreError.persistenceRequired) {
            try store.prepare(request)
        }
        let prepared = try await store.prepareDurable(request)
        #expect(store.delivery == prepared)
        store.close()
        let next = BillingViewModel(reserve: ReserveBillingDocumentUseCase(repository: authority), materialize: engine)
        let recovered = try await next.recover(saleID: request.sale.id)
        #expect(recovered?.request == request)
        #expect(next.delivery == recovered)
        #expect(next.request == request)
        #expect(await authority.requests.isEmpty)
        let final = try await next.materialize()
        #expect(next.delivery == final)
        #expect(next.document == final.document)
        #expect(final.isFinal)
    }

    @Test
    func lostReplyPresentationRereadsLocalPDFWithoutInventingFinalSuccess() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let local = BillingMaterializationPipelineFixtures.local(container)
        let authority = BillingMaterializationAuthority()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: BillingMaterializationRenderer(),
            storage: InMemoryBillingDocumentPDFStorageRepository(failures: [.responseLost])
        )
        let store = BillingDocumentStore(
            reserve: ReserveBillingDocumentUseCase(repository: authority),
            materialize: engine
        )
        let request = try billingRenderingDocument().request
        _ = try await store.prepareDurable(request)
        await #expect(throws: BillingPDFStorageError.unavailable) {
            _ = try await store.materialize()
        }
        #expect(store.delivery?.pdf != nil)
        #expect(store.delivery?.isFinal == false)
        #expect(store.delivery == (try await local.delivery(id: request.id)))
        #expect(!store.isBusy)
    }

    @Test(arguments: [false, true])
    func revokedGenerationCannotPublishLateCompletion(_ close: Bool) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let pause = BillingStoragePause()
        let authority = BillingMaterializationAuthority(pause: pause)
        let local = BillingMaterializationPipelineFixtures.local(container)
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
            defer {
                Task {
                    await pause.complete()
                }
            }
            return try await store.materialize()
        }
        let paused = await pause.waitUntilPausedOrCompleted()
        #expect(paused)
        if close {
            store.close()
        } else {
            store.cancelReservation()
        }
        await pause.release()
        await #expect(throws: CancellationError.self) {
            _ = try await attempt.value
        }
        #expect(store.delivery == prepared)
        #expect(store.document == nil)
        #expect(!store.isBusy)
        #expect(try await local.delivery(id: request.id)?.isFinal == true)
    }
}
