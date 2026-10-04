import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Durable billing checkpoints")
@MainActor
struct BillingDocumentPersistenceTests {
    @Test("Preparation saves the complete paid snapshot and its principal before returning")
    func preparedRequestIsDurable() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try BillingMaterializationPersistenceFixtures.document()
        let prepared = try await repository.prepare(document.request)
        let persisted = try #require(BillingMaterializationPersistenceFixtures.persisted(container).first)
        #expect(persisted == prepared)
        #expect(persisted.request == document.request)
        #expect(persisted.principalID == BillingMaterializationPersistenceFixtures.principalID)
        #expect(!persisted.isFinal)
        #expect(persisted.pdf == nil)
        #expect(try await repository.prepare(document.request) == prepared)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<BillingDocumentDeliveryModel>()) == 1)
    }

    @Test(
        "One sealed sale and family reject competing IDs and changed captured terms",
        arguments: BillingPersistenceRequestMutation.allCases
    )
    func changedRequestPreservesOriginal(mutation: BillingPersistenceRequestMutation) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try BillingMaterializationPersistenceFixtures.document()
        let original = try await repository.prepare(document.request)
        let competing = try mutation.request(document)
        await #expect(throws: BillingDocumentPersistenceError.conflict) {
            try await repository.prepare(competing)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [original])
    }

    @Test(
        "Confirmed numbers are immutable across duplicate and changed result replay",
        arguments: BillingStorageBindingMutation.allCases.filter { $0 != .pdf }
    )
    func changedNumberedResultPreservesOriginal(mutation: BillingStorageBindingMutation) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try BillingMaterializationPersistenceFixtures.document()
        _ = try await repository.prepare(document.request)
        let accepted = try await repository.accept(document)
        #expect(try await repository.accept(document) == accepted)
        let changed = try mutation.document(document)
        await #expect(throws: BillingDocumentPersistenceError.conflict) {
            try await repository.accept(changed)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [accepted])
    }

    @Test("Accepted PDF replay retains exact bytes while replacement bytes are rejected")
    func exactPreparedBytesCannotBeReplaced() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try BillingMaterializationPersistenceFixtures.document()
        _ = try await repository.prepare(document.request)
        _ = try await repository.accept(document)
        let bytes = try billingPDFTemplate()
        let accepted = try await repository.acceptPDF(id: document.request.id, pdf: bytes)
        #expect(try await repository.acceptPDF(id: document.request.id, pdf: bytes) == accepted)
        let changed = try billingPDFTemplate(pageCount: 2)
        await #expect(throws: BillingDocumentPersistenceError.conflict) {
            try await repository.acceptPDF(id: document.request.id, pdf: changed)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container).first?.pdf == bytes)
    }

    @Test(
        "Invalid prepared PDF cannot advance the durable numbered checkpoint",
        arguments: BillingStorageInvalidPDF.allCases
    )
    func invalidPDFPreservesCheckpoint(invalid: BillingStorageInvalidPDF) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let document = try BillingMaterializationPersistenceFixtures.document()
        _ = try await repository.prepare(document.request)
        let numbered = try await repository.accept(document)
        let bytes = try invalid.bytes()
        await #expect(throws: BillingDocumentPersistenceError.invalidState) {
            try await repository.acceptPDF(id: document.request.id, pdf: bytes)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == [numbered])
    }

    @Test(
        "Save failure rolls back each checkpoint and a new owner can retry without residue",
        arguments: BillingPersistenceSaveStep.allCases
    )
    func eachSaveFailureRollsBack(step: BillingPersistenceSaveStep) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let document = try BillingMaterializationPersistenceFixtures.document()
        let bytes = try billingPDFTemplate()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        if let prior = step.priorCheckpoint {
            _ = try await BillingMaterializationPersistenceFixtures.advance(
                repository,
                to: prior,
                document: document,
                pdf: bytes
            )
        }
        let before = try BillingMaterializationPersistenceFixtures.persisted(container)
        let failing = DefaultBillingDocumentLocalRepository(
            persistence: BillingDocumentPersistenceActor(modelContainer: container) { _ in
                throw BillingDocumentPersistenceError.persistenceUnavailable
            },
            access: billingStorageAccess(principalID: BillingMaterializationPersistenceFixtures.principalID)
        )
        await #expect(throws: BillingDocumentPersistenceError.persistenceUnavailable) {
            try await step.apply(to: failing, document: document, pdf: bytes)
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) == before)
        let recovered = BillingMaterializationPersistenceFixtures.repository(container)
        try await step.apply(to: recovered, document: document, pdf: bytes)
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container) != before)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<BillingDocumentDeliveryModel>()) == 1)
    }

    @Test(
        "Corrupt, unknown and mismatched indexed envelopes fail closed and keep their bytes",
        arguments: BillingPersistenceEnvelopeDamage.allCases
    )
    func malformedEnvelopeIsPreserved(damage: BillingPersistenceEnvelopeDamage) async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let document = try BillingMaterializationPersistenceFixtures.document()
        let pending = try BillingDocumentDelivery(
            request: document.request,
            principalID: BillingMaterializationPersistenceFixtures.principalID
        )
        let model = try BillingDocumentDeliveryModel(pending)
        damage.apply(to: model)
        let id = BillingDocumentRequestID(rawValue: model.id)
        let retained = model.payload
        let context = ModelContext(container)
        context.insert(model)
        try context.save()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        await #expect(throws: BillingDocumentPersistenceError.invalidState) {
            try await repository.delivery(id: id)
        }
        let rows = try ModelContext(container).fetch(FetchDescriptor<BillingDocumentDeliveryModel>())
        let preserved = try #require(rows.first)
        #expect(preserved.payload == retained)
        #expect(try ModelContext(container).fetchCount(FetchDescriptor<BillingDocumentDeliveryModel>()) == 1)
    }

    @Test("Cancelled preparation commits no row and explicit recovery can start normally")
    func cancellationBeforeCommitLeavesNoRow() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let repository = BillingMaterializationPersistenceFixtures.repository(container)
        let request = try BillingMaterializationPersistenceFixtures.document().request
        let task = Task {
            withUnsafeCurrentTask {
                $0?.cancel()
            }
            return try await repository.prepare(request)
        }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container).isEmpty)
        _ = try await repository.prepare(request)
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container).count == 1)
    }

    @Test("Cancellation after save denies publication but retains the committed checkpoint")
    func cancellationAfterCommitRemainsRecoverable() async throws {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let request = try BillingMaterializationPersistenceFixtures.document().request
        let repository = DefaultBillingDocumentLocalRepository(
            persistence: BillingDocumentPersistenceActor(modelContainer: container) { context in
                try context.save()
                withUnsafeCurrentTask {
                    $0?.cancel()
                }
            },
            access: billingStorageAccess(principalID: BillingMaterializationPersistenceFixtures.principalID)
        )
        let task = Task {
            try await repository.prepare(request)
        }
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try BillingMaterializationPersistenceFixtures.persisted(container).first?.request == request)
        let recovered = BillingMaterializationPersistenceFixtures.repository(container)
        #expect(try await recovered.delivery(id: request.id)?.request == request)
    }
}
