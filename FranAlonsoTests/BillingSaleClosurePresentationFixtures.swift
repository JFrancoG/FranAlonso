import Foundation
import SwiftData
import Synchronization
import Testing
@testable import FranAlonso

@MainActor
struct BillingSaleClosurePresentationFixture {
    let container: ModelContainer
    let local: DefaultBillingDocumentLocalRepository
    let authority: BillingMaterializationAuthority
    let renderer: BillingMaterializationRenderer
    let engine: MaterializeBillingDocumentUseCase<BillingMaterializationAuthority>
    let document: BillingDocument
    let delivery: BillingDocumentDelivery

    static func make(
        kind: BillingDocumentKind = .ticket,
        checkpoint: BillingPersistenceCheckpoint = .pdf,
        loseFirstResponse: Bool = false
    ) async throws -> BillingSaleClosurePresentationFixture {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let local = BillingMaterializationPipelineFixtures.local(container)
        let authority = BillingMaterializationAuthority(loseFirstResponse: loseFirstResponse)
        let renderer = BillingMaterializationRenderer()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: local,
            authority: authority,
            renderer: renderer,
            storage: UnavailableBillingDocumentPDFStorageRepository()
        )
        let document = try billingRenderingDocument(kind: kind)
        let delivery = try await BillingMaterializationPersistenceFixtures.advance(
            local,
            to: checkpoint,
            document: document,
            pdf: billingPDFTemplate()
        )
        return BillingSaleClosurePresentationFixture(
            container: container,
            local: local,
            authority: authority,
            renderer: renderer,
            engine: engine,
            document: document,
            delivery: delivery
        )
    }

    func store() -> BillingDocumentStore<BillingMaterializationAuthority> {
        BillingDocumentStore(reserve: ReserveBillingDocumentUseCase(repository: authority), materialize: engine)
    }

    func model(
        recorder: BillingSaleClosureRecorder,
        available: BillingFormAvailability = BillingFormAvailability()
    ) -> BillingViewModel<BillingMaterializationAuthority> {
        BillingViewModel(
            sale: document.request.sale,
            reserve: ReserveBillingDocumentUseCase(repository: authority),
            materialize: engine,
            closeSale: { request, _ in
                try await recorder.accept(request)
            },
            now: { recorder.nextTime() },
            canPrepare: { available.value }
        )
    }
}

@MainActor
final class BillingSaleClosureRecorder {
    let gate: RecoveryOperationGate?
    var failsFirst = false
    private(set) var requests: [SaleClosureRequest] = []
    private(set) var clockReads = 0

    init(gate: RecoveryOperationGate? = nil) {
        self.gate = gate
    }

    func nextTime() -> Date {
        clockReads += 1
        return Date(timeIntervalSince1970: 1_790_010_000 + Double(clockReads))
    }

    func accept(_ request: SaleClosureRequest) async throws -> Sale {
        requests.append(request)
        await gate?.enter()
        if failsFirst {
            failsFirst = false
            throw SaleClosureError.persistenceUnavailable
        }
        var sale = request.expected
        try sale.close(
            documentID: BillingDocumentID(rawValue: UUID(uuid: (
                19, 128, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 5
            ))),
            closedAt: request.closedAt
        )
        return sale
    }
}

@MainActor
struct BillingSaleClosureRecoveryFixture {
    let container: ModelContainer
    let local: DefaultBillingDocumentLocalRepository
    let model: BillingViewModel<BillingMaterializationAuthority>
    let deliveries: [BillingDocumentDelivery]
    let availability: BillingFormAvailability
    let reads: BillingFamilyRecoveryReads
    let identities: BillingRecoveryIdentityCounter
    let authority: BillingMaterializationAuthority
    let renderer: BillingMaterializationRenderer

    static func make(
        kinds: [BillingDocumentKind] = [.ticket, .invoice]
    ) async throws -> BillingSaleClosureRecoveryFixture {
        let container = try BillingMaterializationPersistenceFixtures.container()
        let local = BillingMaterializationPipelineFixtures.local(container)
        var deliveries: [BillingDocumentDelivery] = []
        for kind in kinds {
            let source = try billingRenderingDocument(kind: kind)
            let request = try BillingDocumentRequest(
                id: BillingDocumentRequestID(rawValue: viewModelUUID(kind == .ticket ? 13_121 : 13_122)),
                documentID: BillingDocumentID(rawValue: viewModelUUID(kind == .ticket ? 13_123 : 13_124)),
                sale: source.request.sale,
                kind: kind,
                requestedAt: source.request.requestedAt,
                fiscalRecipient: source.request.fiscalRecipient
            )
            let document = try BillingDocument.numbered(
                request: request,
                number: source.number,
                issuedAt: source.issuedAt
            )
            deliveries.append(try await BillingMaterializationPersistenceFixtures.advance(
                local,
                to: .pdf,
                document: document,
                pdf: billingPDFTemplate()
            ))
        }
        let authority = BillingMaterializationAuthority()
        let renderer = BillingMaterializationRenderer()
        let reads = BillingFamilyRecoveryReads()
        let engine = BillingMaterializationPipelineFixtures.engine(
            local: BillingFamilyRecoveryRepository(base: local, reads: reads),
            authority: authority,
            renderer: renderer,
            storage: UnavailableBillingDocumentPDFStorageRepository()
        )
        let availability = BillingFormAvailability()
        let identities = BillingRecoveryIdentityCounter()
        let model = BillingViewModel(
            sale: try #require(deliveries.first).request.sale,
            reserve: ReserveBillingDocumentUseCase(repository: authority),
            prepare: PrepareBillingDocumentRequestUseCase(
                makeRequestID: {
                    identities.record()
                    return BillingDocumentRequestID(rawValue: viewModelUUID(13_125))
                },
                makeDocumentID: {
                    identities.record()
                    return BillingDocumentID(rawValue: viewModelUUID(13_126))
                }
            ),
            materialize: engine,
            closeSale: { _, _ in
                throw SaleClosureError.persistenceUnavailable
            },
            canPrepare: { availability.value }
        )
        return BillingSaleClosureRecoveryFixture(
            container: container,
            local: local,
            model: model,
            deliveries: deliveries,
            availability: availability,
            reads: reads,
            identities: identities,
            authority: authority,
            renderer: renderer
        )
    }

    func delivery(kind: BillingDocumentKind) throws -> BillingDocumentDelivery {
        try #require(deliveries.first { $0.request.kind == kind })
    }

    func expectUnchangedBilling() async throws {
        let persisted = try BillingMaterializationPersistenceFixtures.persisted(container)
        #expect(persisted.count == deliveries.count)
        #expect(persisted.allSatisfy { deliveries.contains($0) })
        #expect(identities.count == 0)
        #expect(await reads.writes == 0)
        #expect(await authority.requests.isEmpty)
        #expect(await renderer.calls == 0)
    }
}

enum BillingRecoveryReadOutcome {
    case retained, empty, unavailable
}

actor BillingFamilyRecoveryReads {
    private var nextOutcome = BillingRecoveryReadOutcome.retained
    private var nextGate: RecoveryOperationGate?
    private(set) var writes = 0

    func respondNext(with outcome: BillingRecoveryReadOutcome) {
        nextOutcome = outcome
    }

    func pauseNext(with gate: RecoveryOperationGate) {
        nextGate = gate
    }

    func read() async throws -> Bool {
        let outcome = nextOutcome
        let gate = nextGate
        nextOutcome = .retained
        nextGate = nil
        await gate?.enter()
        guard outcome != .unavailable else { throw BillingDocumentPersistenceError.persistenceUnavailable }
        return outcome != .empty
    }

    func recordWrite() {
        writes += 1
    }
}

final class BillingRecoveryIdentityCounter: Sendable {
    private let created = Mutex(0)
    var count: Int { created.withLock { $0 } }

    func record() {
        created.withLock { $0 += 1 }
    }
}

private struct BillingFamilyRecoveryRepository: BillingDocumentLocalRepository {
    let base: DefaultBillingDocumentLocalRepository
    let reads: BillingFamilyRecoveryReads
    var principalID: String { base.principalID }

    func deliveries(saleID: SaleID) async throws -> [BillingDocumentDelivery] {
        guard try await reads.read() else { return [] }
        return try await base.deliveries(saleID: saleID)
    }

    func delivery(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery? {
        try await base.delivery(id: id)
    }

    func prepare(_ request: BillingDocumentRequest) async throws -> BillingDocumentDelivery {
        await reads.recordWrite()
        return try await base.prepare(request)
    }

    func accept(_ document: BillingDocument) async throws -> BillingDocumentDelivery {
        await reads.recordWrite()
        return try await base.accept(document)
    }

    func acceptPDF(id: BillingDocumentRequestID, pdf: Data) async throws -> BillingDocumentDelivery {
        await reads.recordWrite()
        return try await base.acceptPDF(id: id, pdf: pdf)
    }

    func beginUpload(id: BillingDocumentRequestID) async throws -> BillingDocumentDelivery {
        await reads.recordWrite()
        return try await base.beginUpload(id: id)
    }

    func completeUpload(
        id: BillingDocumentRequestID,
        receipt: BillingPDFUploadReceipt
    ) async throws -> BillingDocumentDelivery {
        await reads.recordWrite()
        return try await base.completeUpload(id: id, receipt: receipt)
    }

    func recordFailure(
        id: BillingDocumentRequestID,
        phase: BillingDocumentDeliveryPhase,
        reason: BillingDocumentFailure,
        attempt: Int?
    ) async throws {
        await reads.recordWrite()
        try await base.recordFailure(
            id: id,
            phase: phase,
            reason: reason,
            attempt: attempt
        )
    }
}
