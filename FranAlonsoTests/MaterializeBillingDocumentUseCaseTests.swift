import Foundation
import Testing
@testable import FranAlonso

@Suite("Billing durable materialization pipeline")
struct MaterializeBillingDocumentUseCaseTests {
    @Test(arguments: [1, 2, 3, 4, 5])
    func failedDurableBoundaryPreventsNextMotorAndDiskReopenResumesSameBinding(_ save: Int) async throws {
        let directory = try BillingMaterializationPersistenceFixtures.temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appending(path: "interrupted.store")
        let request = try billingRenderingDocument().request
        let authority = BillingMaterializationAuthority()
        let renderer = BillingMaterializationRenderer()
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let checkpoint = try await BillingMaterializationPipelineFixtures.interruptedCheckpoint(
            at: url,
            save: save,
            request: request,
            authority: authority,
            renderer: renderer,
            remote: remote
        )
        #expect(await authority.requests.count == (save == 1 ? 0 : 1))
        #expect(await renderer.calls == (save <= 2 ? 0 : 1))
        #expect(await remote.documentCount == (save == 5 ? 1 : 0))
        #expect(checkpoint?.isFinal != true)
        let container = try BillingMaterializationPersistenceFixtures.container(at: url)
        let local = BillingMaterializationPipelineFixtures.local(container)
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: renderer,
            storage: InMemoryBillingDocumentPDFStorageRepository(remote: remote)
        )
        _ = try await engine.prepare(request)
        let final = try await engine(request.id)
        #expect(final.isFinal)
        #expect(final.request == request)
        #expect(final.document?.number.value == 731)
        #expect(await authority.requests.count == (save == 2 ? 2 : 1))
        #expect(await renderer.calls == (save == 3 ? 2 : 1))
        #expect(await remote.documentCount == 1)
        if save >= 4 {
            #expect(final.pdf == checkpoint?.pdf)
        }
    }
    @Test @MainActor
    func realRenderBecomesFinalOnlyAfterLocalReceiptAndReplaySkipsEveryMotor() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let local = BillingMaterializationPipelineFixtures.local(container)
        let authority = BillingMaterializationAuthority()
        let renderer = BillingMaterializationRenderer()
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: renderer,
            storage: InMemoryBillingDocumentPDFStorageRepository(remote: remote)
        )
        let request = try billingRenderingDocument().request
        let prepared = try await engine.prepare(request)
        #expect(prepared.document == nil)
        #expect(await authority.requests.isEmpty)
        let final = try await engine(request.id)
        #expect(final.isFinal)
        #expect(final.document?.number.value == 731)
        #expect(await final.pdf == renderer.output)
        #expect(final.receipt?.matches(documentID: request.documentID, principalID: "principal-A") == true)
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [final])
        #expect(try await engine(request.id) == final)
        #expect(await authority.requests == [request])
        #expect(await renderer.calls == 1)
        #expect(await remote.documentCount == 1)
        #expect(final.request.sale == request.sale)
    }

    @Test
    func lostReservationResponseRecoversIdenticalRequestAndNumber() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let local = BillingMaterializationPipelineFixtures.local(container)
        let authority = BillingMaterializationAuthority(loseFirstResponse: true)
        let renderer = BillingMaterializationRenderer()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: renderer,
            storage: InMemoryBillingDocumentPDFStorageRepository()
        )
        let request = try billingRenderingDocument().request
        _ = try await engine.prepare(request)
        await #expect(throws: BillingDocumentReservationError.unavailable) {
            _ = try await engine(request.id)
        }
        let pending = try #require(await local.delivery(id: request.id))
        #expect(pending.request == request)
        #expect(pending.document == nil)
        #expect(pending.failure?.phase == .numbering)
        let final = try await engine(request.id)
        #expect(final.document?.number.value == 731)
        #expect(await authority.requests == [request, request])
        #expect(await renderer.calls == 1)
    }

    @Test(arguments: [false, true])
    func acceptedUploadWithoutReplyReusesPersistedExactBytesAfterRecreation(_ cancelled: Bool) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let authority = BillingMaterializationAuthority()
        let renderer = BillingMaterializationRenderer()
        let request = try billingRenderingDocument().request
        let local = BillingMaterializationPipelineFixtures.local(container)
        let first = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: renderer,
            storage: InMemoryBillingDocumentPDFStorageRepository(
                remote: remote,
                failures: [cancelled ? .cancelledAfterAcceptance : .responseLost]
            )
        )
        _ = try await first.prepare(request)
        await #expect(throws: (any Error).self) {
            _ = try await first(request.id)
        }
        let checkpoint = try #require(await local.delivery(id: request.id))
        #expect(!checkpoint.isFinal)
        #expect(checkpoint.pdf != nil)
        #expect(checkpoint.uploadAttempts == 1)
        let second = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: renderer,
            storage: InMemoryBillingDocumentPDFStorageRepository(remote: remote)
        )
        let final = try await second(request.id)
        #expect(final.isFinal)
        #expect(final.pdf == checkpoint.pdf)
        #expect(final.uploadAttempts == 2)
        #expect(await renderer.calls == 1)
        #expect(await authority.requests == [request])
        #expect(await remote.pdf(documentID: request.documentID, principalID: "principal-A") == checkpoint.pdf)
    }

    @Test
    func missingCheckpointDoesNotContactMotors() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let authority = BillingMaterializationAuthority()
        let renderer = BillingMaterializationRenderer()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: BillingMaterializationPipelineFixtures.local(container),
            authority: authority,
            renderer: renderer,
            storage: InMemoryBillingDocumentPDFStorageRepository()
        )
        let id = BillingDocumentRequestID(rawValue: UUID())
        await #expect(throws: BillingDocumentPersistenceError.notFound) {
            _ = try await engine(id)
        }
        #expect(await authority.requests.isEmpty)
        #expect(await renderer.calls == 0)
    }
}
