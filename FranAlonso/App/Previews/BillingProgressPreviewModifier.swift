import Foundation
import SwiftData
import SwiftUI

/// Supplies independent deterministic in-memory checkpoints; preview acceptance is a controlled snapshot port.
struct BillingProgressPreviewModifier: PreviewModifier {
    enum Stage: CaseIterable {
        case recovery, pending, generating, closable, accepted, choosingFamily
    }

    struct Scenario {
        let container: ModelContainer
        let model: BillingViewModel<UnavailableBillingDocumentReservationRepository>
    }

    struct Context {
        let scenarios: [Stage: Scenario]
    }

    let stage: Stage

    static func makeSharedContext() async throws -> Context {
        var scenarios: [Stage: Scenario] = [:]
        for stage in Stage.allCases {
            scenarios[stage] = try await scenario(stage)
        }
        return Context(scenarios: scenarios)
    }

    func body(content: Content, context: Context) -> some View {
        if let scenario = context.scenarios[stage] {
            content
                .modelContainer(scenario.container)
                .environment(\.billingProgressPreviewModel, scenario.model)
        }
    }

    private static func scenario(_ stage: Stage) async throws -> Scenario {
        let container = try ModelContainer.inMemory(for: Schema.franAlonso)
        let sale = SalesPreviewFixtures.workday.sales[5]
        let request = try BillingDocumentRequest(
            id: BillingDocumentRequestID(rawValue: UUID(uuid: (13, 12, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 1))),
            documentID: BillingDocumentID(rawValue: UUID(uuid: (13, 12, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 2))),
            sale: sale,
            kind: .invoice,
            requestedAt: Date(timeIntervalSince1970: 1_790_001_200),
            fiscalRecipient: BillingFiscalRecipient(BillingPreviewFixtures.standard.input)
        )
        let access = BillingAssetAccess(principalID: "DEMO-preview-13-12") {
            if stage == .recovery {
                throw BillingAssetError.unauthorized
            }
        }
        let local = DefaultBillingDocumentLocalRepository(
            persistence: BillingDocumentPersistenceActor(modelContainer: container),
            access: access
        )
        let reserve = ReserveBillingDocumentUseCase(repository: UnavailableBillingDocumentReservationRepository())
        let render = AppDependencies.renderBillingDocumentUseCase(
            templates: BundleBillingDocumentTemplateRepository(bundle: .main),
            signatures: BillingPreviewSignatureRepository()
        )
        let engine = MaterializeBillingDocumentUseCase(
            local: local,
            reserve: reserve,
            render: render,
            upload: AppDependencies.uploadBillingDocumentPDFUseCase(),
            access: access
        )
        let model = BillingViewModel(
            sale: sale,
            reserve: reserve,
            materialize: engine,
            closeSale: { command, _ in
                var accepted = command.expected
                try accepted.close(documentID: request.documentID, closedAt: command.closedAt)
                return accepted
            },
            now: { Date(timeIntervalSince1970: 1_790_002_000) },
            isDemonstration: true
        )
        if stage == .recovery {
            model.requestLoad()
            await model.performRequestedOperation(in: container.mainContext)
        } else {
            _ = try await local.prepare(request)
            if stage == .choosingFamily {
                let ticket = try BillingDocumentRequest(
                    id: BillingDocumentRequestID(rawValue: UUID(uuid: (13, 12, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 3))),
                    documentID: BillingDocumentID(rawValue: UUID(uuid: (13, 12, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 4))),
                    sale: sale,
                    kind: .ticket,
                    requestedAt: request.requestedAt
                )
                _ = try await local.prepare(ticket)
            } else if stage == .pending {
                try await local.recordFailure(
                    id: request.id,
                    phase: .numbering,
                    reason: .unavailable,
                    attempt: nil
                )
            } else {
                let document = try BillingDocument.numbered(
                    request: request,
                    number: BillingDocumentNumber(series: .invoice, value: 950_001),
                    issuedAt: Date(timeIntervalSince1970: 1_790_001_200)
                )
                _ = try await local.accept(document)
                _ = try await local.acceptPDF(id: request.id, pdf: render(document))
            }
            try await model.load()
            if stage == .generating {
                model.requestGeneration()
            } else if stage == .accepted {
                _ = try await model.closeSale(in: container.mainContext)
            }
        }
        return Scenario(container: container, model: model)
    }
}

private struct BillingPreviewSignatureRepository: BillingBusinessSignatureRepository {
    func loadSignature() async throws -> Data? { nil }
    func importSignature(_ data: Data) async throws { throw BillingAssetError.unauthorized }
}

extension EnvironmentValues {
    @Entry var billingProgressPreviewModel: BillingViewModel<UnavailableBillingDocumentReservationRepository>? = nil
}
