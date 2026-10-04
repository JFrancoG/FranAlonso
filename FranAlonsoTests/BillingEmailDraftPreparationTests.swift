import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Read-only billing email draft preparation")
@MainActor
struct BillingEmailDraftPreparationTests {
    @Test(arguments: [
        (BillingDocumentKind.ticket, "es", "Tu ticket nº 41", "Adjunto encontrarás tu ticket nº 41."),
        (.invoice, "es", "Tu factura nº 91", "Adjunto encontrarás tu factura nº 91."),
        (.ticket, "en", "Your receipt no. 41", "Please find your receipt no. 41 attached."),
        (.invoice, "en", "Your invoice no. 91", "Please find your invoice no. 91 attached.")
    ])
    func `final local family prepares localized content without changing its checkpoint`(
        _ kind: BillingDocumentKind,
        _ language: String,
        _ subject: String,
        _ body: String
    ) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try billingRenderingDocument(kind: kind)
        let bytes = try billingPDFTemplate()
        let retained = try await BillingMaterializationPersistenceFixtures.advance(
            repository,
            to: .final,
            document: document,
            pdf: bytes
        )
        let reads = BillingEmailDraftReadRepository(base: repository)
        let prepare = BillingEmailDraftFixtures.preparer(local: reads, language: language)
        let draft = try await prepare(requestID: document.request.id, recipient: BillingEmailDraftFixtures.recipient)
        let retry = try await prepare(requestID: document.request.id, recipient: BillingEmailDraftFixtures.recipient)
        #expect(draft.subject == subject)
        #expect(draft.body == body)
        #expect(draft.pdf == bytes)
        #expect(draft.receipt == retained.receipt)
        #expect(draft.document.request.sale.status == document.request.sale.status)
        #expect(retry == draft)
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [retained])
        #expect(await reads.readCount == 2)
        #expect(await reads.writeCount == 0)
        #expect(draft.mimeType == "application/pdf")
        let family = kind == .ticket ? "ticket" : "invoice"
        #expect(draft.fileName == family + "-13800000-0000-0000-0000-000000020005.pdf")
    }

    @Test
    func `released disk owner reopens the final document without a new attempt or identity`() async throws {
        let directory = try BillingMaterializationPersistenceFixtures.temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("billing-email.store")
        let document = try billingRenderingDocument(kind: .invoice)
        let bytes = try billingPDFTemplate()
        let probe = BillingEmailDraftDiskOwnerProbe()
        let retained = try await BillingEmailDraftFixtures.writeAndRelease(
            at: url,
            document: document,
            pdf: bytes,
            probe: probe
        )
        for _ in 0..<100 where probe.container != nil {
            await Task.yield()
        }
        try #require(probe.container == nil)
        let reopened = try BillingMaterializationPersistenceFixtures.container(at: url)
        let prepare = BillingEmailDraftFixtures.preparer(
            local: BillingMaterializationPersistenceFixtures.repository(reopened)
        )
        let draft = try await prepare(requestID: document.request.id, recipient: BillingEmailDraftFixtures.recipient)
        #expect(draft.id == document.id)
        #expect(draft.requestID == document.request.id)
        #expect(draft.pdf == bytes)
        #expect(try BillingMaterializationPersistenceFixtures.persisted(reopened) == [retained])
        #expect(retained.uploadAttempts == 1)
    }

    @Test(arguments: [
        BillingPersistenceCheckpoint.prepared, .numbered, .pdf, .attempt
    ])
    func `every unfinished checkpoint denies draft publication`(
        _ checkpoint: BillingPersistenceCheckpoint
    ) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try billingRenderingDocument()
        let retained = try await BillingMaterializationPersistenceFixtures.advance(
            repository,
            to: checkpoint,
            document: document,
            pdf: billingPDFTemplate()
        )
        let prepare = BillingEmailDraftFixtures.preparer(local: repository)
        await #expect(throws: BillingEmailError.documentNotFinal) {
            try await prepare(requestID: document.request.id, recipient: BillingEmailDraftFixtures.recipient)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [retained])
    }

    @Test
    func `absent request is not materialized to prepare an email`() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let prepare = BillingEmailDraftFixtures.preparer(local: repository)
        let request = try billingRenderingDocument().request
        await #expect(throws: BillingEmailError.documentNotFound) {
            try await prepare(requestID: request.id, recipient: BillingEmailDraftFixtures.recipient)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container).isEmpty)
    }

    @Test(arguments: [false, true])
    func `mismatched capability or revoked permission denies the local read`(_ revoked: Bool) async throws {
        let final = try await BillingEmailDraftFixtures.finalDelivery()
        let local = BillingEmailDraftReadRepository(supplied: final)
        let permit = BillingStoragePermit()
        if revoked {
            await permit.revoke()
        }
        let access = BillingAssetAccess(principalID: revoked ? final.principalID : "foreign-principal") {
            try await permit.validate()
        }
        let prepare = BillingEmailDraftFixtures.preparer(local: local, access: access)
        await #expect(throws: BillingEmailError.unauthorized) {
            try await prepare(requestID: final.id, recipient: BillingEmailDraftFixtures.recipient)
        }
        #expect(await local.readCount == 0)
        #expect(await local.writeCount == 0)
    }

    @Test(arguments: [false, true])
    func `foreign result binding denies an otherwise authorized read`(_ foreignPrincipal: Bool) async throws {
        let final = try await BillingEmailDraftFixtures.finalDelivery()
        let local = BillingEmailDraftReadRepository(
            principalID: foreignPrincipal ? "another-principal" : final.principalID,
            supplied: final
        )
        let access = billingStorageAccess(principalID: local.principalID)
        let prepare = BillingEmailDraftFixtures.preparer(local: local, access: access)
        let otherID = try #require(UUID(uuidString: "13110000-0000-0000-0000-000000000998"))
        let requestID = foreignPrincipal ? final.id : BillingDocumentRequestID(rawValue: otherID)
        await #expect(throws: BillingEmailError.invalidDraft) {
            try await prepare(requestID: requestID, recipient: BillingEmailDraftFixtures.recipient)
        }
        #expect(await local.writeCount == 0)
    }

    @Test(arguments: [false, true])
    func `read failure is neutral and a revoked capability wins over provider details`(_ revoked: Bool) async throws {
        let final = try await BillingEmailDraftFixtures.finalDelivery()
        let pause = BillingStoragePause()
        let local = BillingEmailDraftReadRepository(supplied: final, pause: pause, fails: true)
        let permit = BillingStoragePermit()
        let access = BillingAssetAccess(principalID: final.principalID) {
            try await permit.validate()
        }
        let prepare = BillingEmailDraftFixtures.preparer(local: local, access: access)
        let task = Task {
            do {
                let draft = try await prepare(requestID: final.id, recipient: BillingEmailDraftFixtures.recipient)
                await pause.complete()
                return draft
            } catch {
                await pause.complete()
                throw error
            }
        }
        try #require(await pause.waitUntilPausedOrCompleted())
        if revoked {
            await permit.revoke()
        }
        await pause.release()
        await #expect(throws: revoked ? BillingEmailError.unauthorized : .unavailable) {
            try await task.value
        }
        #expect(await local.writeCount == 0)
    }

    @Test(arguments: [false, true])
    func `cancellation or revocation after a read denies publication and preserves final state`(
        _ cancelled: Bool
    ) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try billingRenderingDocument()
        let retained = try await BillingMaterializationPersistenceFixtures.advance(
            repository,
            to: .final,
            document: document,
            pdf: billingPDFTemplate()
        )
        let pause = BillingStoragePause()
        let local = BillingEmailDraftReadRepository(base: repository, pause: pause)
        let permit = BillingStoragePermit()
        let access = BillingAssetAccess(principalID: retained.principalID) {
            try await permit.validate()
        }
        let prepare = BillingEmailDraftFixtures.preparer(local: local, access: access)
        let task = Task {
            do {
                let draft = try await prepare(requestID: retained.id, recipient: BillingEmailDraftFixtures.recipient)
                await pause.complete()
                return draft
            } catch {
                await pause.complete()
                throw error
            }
        }
        try #require(await pause.waitUntilPausedOrCompleted())
        if cancelled {
            task.cancel()
        } else {
            await permit.revoke()
        }
        await pause.release()
        if cancelled {
            await #expect(throws: CancellationError.self) {
                try await task.value
            }
        } else {
            await #expect(throws: BillingEmailError.unauthorized) {
                try await task.value
            }
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [retained])
        #expect(await local.writeCount == 0)
    }
}
