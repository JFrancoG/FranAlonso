import Foundation
import SwiftData
import Synchronization
import Testing
@testable import FranAlonso

actor BillingMaterializationAuthority: BillingDocumentReservationRepository {
    private var accepted: BillingDocument?
    private var loseFirstResponse: Bool
    private let pause: BillingStoragePause?
    private(set) var requests: [BillingDocumentRequest] = []

    init(loseFirstResponse: Bool = false, pause: BillingStoragePause? = nil) {
        self.loseFirstResponse = loseFirstResponse
        self.pause = pause
    }

    func reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument {
        requests.append(request)
        if let pause {
            await pause.wait()
        }
        if let accepted {
            guard accepted.request == request else { throw BillingDocumentReservationError.conflict }
            return accepted
        }
        let document = try BillingDocument.numbered(
            request: request,
            number: BillingDocumentNumber(series: request.kind.series, value: 731),
            issuedAt: Date(timeIntervalSince1970: 1_790_000_000)
        )
        accepted = document
        if loseFirstResponse {
            loseFirstResponse = false
            throw BillingDocumentReservationError.unavailable
        }
        return document
    }
}

actor BillingMaterializationRenderer: BillingPDFRenderer {
    private let renderer = CoreGraphicsBillingPDFRenderer()
    private(set) var calls = 0
    private(set) var output: Data?

    func render(_ request: BillingPDFRenderRequest) async throws -> Data {
        calls += 1
        let pdf = try await renderer.render(request)
        output = pdf
        return pdf
    }
}

struct BillingMaterializationSignatures: BillingBusinessSignatureRepository {
    func loadSignature() async throws -> Data? { nil }
    func importSignature(_ data: Data) async throws { throw BillingAssetError.unauthorized }
}

struct BillingMaterializationPipelineFixtures {
    static func engine(
        local: any BillingDocumentLocalRepository,
        authority: BillingMaterializationAuthority,
        renderer: BillingMaterializationRenderer,
        storage: any BillingDocumentPDFStorageRepository,
        access: BillingAssetAccess = billingStorageAccess(principalID: "principal-A")
    ) -> MaterializeBillingDocumentUseCase<BillingMaterializationAuthority> {
        MaterializeBillingDocumentUseCase(
            local: local,
            reserve: ReserveBillingDocumentUseCase(repository: authority),
            render: RenderBillingDocumentUseCase(
                templates: BundleBillingDocumentTemplateRepository(bundle: .main),
                signatures: BillingMaterializationSignatures(),
                composer: TemplateBillingDocumentPDFComposer(bundle: .main),
                renderer: renderer
            ),
            upload: UploadBillingDocumentPDFUseCase(repository: storage),
            access: access
        )
    }

    static func local(_ container: ModelContainer) -> DefaultBillingDocumentLocalRepository {
        DefaultBillingDocumentLocalRepository(
            persistence: BillingDocumentPersistenceActor(modelContainer: container),
            access: billingStorageAccess(principalID: "principal-A")
        )
    }
}

final class BillingMaterializationSaveGate: Sendable {
    private let calls = Mutex(0)
    private let failingSave: Int

    init(failingSave: Int) {
        self.failingSave = failingSave
    }

    func save(_ context: ModelContext) throws {
        let count = calls.withLock { value in
            value += 1
            return value
        }
        guard count != failingSave else { throw BillingDocumentPersistenceError.persistenceUnavailable }
        try context.save()
    }
}

extension BillingMaterializationPipelineFixtures {
    static func interruptedCheckpoint(
        at url: URL,
        save: Int,
        request: BillingDocumentRequest,
        authority: BillingMaterializationAuthority,
        renderer: BillingMaterializationRenderer,
        remote: InMemoryBillingDocumentPDFStorageRepository.RemoteStore
    ) async throws -> BillingDocumentDelivery? {
        let container = try BillingMaterializationPersistenceFixtures.container(at: url)
        let gate = BillingMaterializationSaveGate(failingSave: save)
        let local = DefaultBillingDocumentLocalRepository(
            persistence: BillingDocumentPersistenceActor(
                modelContainer: container,
                saveChanges: {
                    try gate.save($0)
                }
            ),
            access: billingStorageAccess(principalID: "principal-A")
        )
        let engine = engine(
            local: local,
            authority: authority,
            renderer: renderer,
            storage: InMemoryBillingDocumentPDFStorageRepository(remote: remote)
        )
        await #expect(throws: BillingDocumentPersistenceError.persistenceUnavailable) {
            _ = try await engine.prepare(request)
            _ = try await engine(request.id)
        }
        return try await local.delivery(id: request.id)
    }
}
