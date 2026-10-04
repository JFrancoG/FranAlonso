import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Billing recovery and authorization")
@MainActor
struct BillingDocumentRecoveryTests {
    @Test(
        "A new disk owner discovers the same sealed state at every local boundary",
        arguments: BillingPersistenceCheckpoint.allCases
    )
    func checkpointsSurviveReleaseAndReopen(checkpoint: BillingPersistenceCheckpoint) async throws {
        let directory = try BillingMaterializationPersistenceFixtures.temporaryDirectory()
        defer {
            try? FileManager.default.removeItem(at: directory)
        }
        let url = directory.appendingPathComponent("billing.store")
        let document = try BillingMaterializationPersistenceFixtures.document()
        let bytes = try billingPDFTemplate()
        let written = try await BillingMaterializationPersistenceFixtures.write(
            at: url,
            checkpoint: checkpoint,
            document: document,
            pdf: bytes
        )
        let reopened = try BillingMaterializationPersistenceFixtures.container(at: url)
        let repository = BillingMaterializationPersistenceFixtures.repository(reopened)
        let discovered = try await repository.deliveries(saleID: document.saleID)
        #expect(discovered == [written])
        #expect(try await repository.delivery(id: document.request.id) == written)
        #expect(try await repository.prepare(document.request) == written)
        #expect(try BillingMaterializationPersistenceFixtures.persisted(reopened) == [written])
        #expect(discovered.first?.request.sale.status == document.request.sale.status)
        if checkpoint == .pdf || checkpoint == .attempt || checkpoint == .final {
            #expect(discovered.first?.pdf == bytes)
        }
        if checkpoint == .final {
            #expect(discovered.first?.receipt == BillingMaterializationPersistenceFixtures.receipt(document))
            #expect(discovered.first?.isFinal == true)
        }
    }

    @Test("Ticket and invoice are retained independently and discovery returns both families")
    func discoveryPreservesBothFamilies() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let invoice = try BillingMaterializationPersistenceFixtures.document()
        let ticketSource = try BillingMaterializationPersistenceFixtures.document(kind: .ticket).request
        let ticket = try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: UUID()),
            documentID: BillingDocumentID(rawValue: UUID()),
            sale: ticketSource.sale,
            kind: .ticket,
            requestedAt: ticketSource.requestedAt
        )
        _ = try await repository.prepare(invoice.request)
        _ = try await repository.prepare(ticket)
        let discovered = try await repository.deliveries(saleID: invoice.saleID)
        #expect(discovered.count == 2)
        #expect(discovered.contains { $0.request == invoice.request })
        #expect(discovered.contains { $0.request == ticket })
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container).count == 2)
    }

    @Test("A valid capability for a foreign principal cannot read or mutate retained work")
    func principalBindingPreventsCrossPrincipalAccess() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let document = try BillingMaterializationPersistenceFixtures.document()
        let owner = BillingMaterializationPersistenceFixtures.repository(container)
        let retained = try await owner.prepare(document.request)
        let foreign = DefaultBillingDocumentLocalRepository(
            persistence: BillingDocumentPersistenceActor(modelContainer: container),
            access: billingStorageAccess(principalID: "foreign-principal")
        )
        await #expect(throws: BillingDocumentPersistenceError.unauthorized) {
            try await foreign.delivery(id: document.request.id)
        }
        await #expect(throws: BillingDocumentPersistenceError.unauthorized) {
            try await foreign.deliveries(saleID: document.saleID)
        }
        await #expect(throws: BillingDocumentPersistenceError.unauthorized) {
            try await foreign.prepare(document.request)
        }
        await #expect(throws: BillingDocumentPersistenceError.unauthorized) {
            try await foreign.accept(document)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [retained])
    }

    @Test("Revocation rejects reads and new writes even while the UID remains known")
    func revokedCapabilityCannotUseKnownPrincipal() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let document = try BillingMaterializationPersistenceFixtures.document()
        let owner = BillingMaterializationPersistenceFixtures.repository(container)
        let retained = try await owner.prepare(document.request)
        let permit = BillingPersistencePermit()
        let access = BillingAssetAccess(principalID: BillingMaterializationPersistenceFixtures.principalID) {
            try await permit.validate()
        }
        let revoked = BillingMaterializationPersistenceFixtures.repository(container, access: access)
        await permit.revoke()
        await #expect(throws: BillingDocumentPersistenceError.unauthorized) {
            try await revoked.delivery(id: document.request.id)
        }
        await #expect(throws: BillingDocumentPersistenceError.unauthorized) {
            try await revoked.accept(document)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [retained])
    }

    @Test("Revocation after an authorized commit denies publication and allows a later authorized recovery")
    func revocationAfterCommitPreservesDurableWork() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let request = try BillingMaterializationPersistenceFixtures.document().request
        let permit = BillingPersistencePermit(revokeOnCheck: 2)
        let access = BillingAssetAccess(principalID: BillingMaterializationPersistenceFixtures.principalID) {
            try await permit.validate()
        }
        let repository = BillingMaterializationPersistenceFixtures.repository(container, access: access)
        await #expect(throws: BillingDocumentPersistenceError.unauthorized) {
            try await repository.prepare(request)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container).first?.request == request)
        let recovered = BillingMaterializationPersistenceFixtures.repository(container)
        #expect(try await recovered.delivery(id: request.id)?.request == request)
    }

    @Test("A receipt requires exact correlation; final replay and late failures cannot demote accepted work")
    func receiptReplayAndStaleFailurePreserveFinal() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try BillingMaterializationPersistenceFixtures.document()
        let bytes = try billingPDFTemplate()
        _ = try await BillingMaterializationPersistenceFixtures.advance(
            repository,
            to: .attempt,
            document: document,
            pdf: bytes
        )
        let final = try await repository.completeUpload(
            id: document.request.id,
            receipt: BillingMaterializationPersistenceFixtures.receipt(document)
        )
        let wrong = BillingPDFUploadReceipt.accepted(documentID: document.id, principalID: "foreign-principal")
        await #expect(throws: BillingDocumentPersistenceError.conflict) {
            try await repository.completeUpload(id: document.request.id, receipt: wrong)
        }
        for phase in [BillingDocumentDeliveryPhase.numbering, .rendering, .upload] {
            try await repository.recordFailure(
                id: document.request.id,
                phase: phase,
                reason: .conflict,
                attempt: 1
            )
        }
        #expect(try await repository.completeUpload(
            id: document.request.id,
            receipt: BillingMaterializationPersistenceFixtures.receipt(document)
        ) == final)
        #expect(try await repository.beginUpload(id: document.request.id) == final)
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [final])
        #expect(final.uploadAttempts == 1)
    }

    @Test("Old stage and attempt failures cannot overwrite a newer checkpoint")
    func staleFailuresPreserveNewerProgress() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try BillingMaterializationPersistenceFixtures.document()
        let bytes = try billingPDFTemplate()
        let first = try await BillingMaterializationPersistenceFixtures.advance(
            repository,
            to: .attempt,
            document: document,
            pdf: bytes
        )
        let second = try await repository.beginUpload(id: document.request.id)
        try await repository.recordFailure(
            id: document.request.id,
            phase: .numbering,
            reason: .conflict,
            attempt: nil
        )
        try await repository.recordFailure(
            id: document.request.id,
            phase: .rendering,
            reason: .conflict,
            attempt: nil
        )
        try await repository.recordFailure(
            id: document.request.id,
            phase: .upload,
            reason: .unavailable,
            attempt: first.uploadAttempts
        )
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [second])
        #expect(second.uploadAttempts == 2)
        try await repository.recordFailure(
            id: document.request.id,
            phase: .upload,
            reason: .unavailable,
            attempt: second.uploadAttempts
        )
        let failed = try #require(try await repository.delivery(id: document.request.id))
        #expect(failed.failure?.phase == .upload)
        #expect(failed.failure?.reason == .unavailable)
        #expect(failed.pdf == bytes)
        #expect(failed.document == document)
    }
}
