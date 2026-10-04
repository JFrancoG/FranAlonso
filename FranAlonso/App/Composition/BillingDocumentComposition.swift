import Foundation
import SwiftData

/// Owns local document serialization and binds each form to one authenticated shell capability.
/// Normal composition keeps external numbering and Storage unavailable; construction performs no effects.
@MainActor
final class BillingDocumentComposition {
    weak var authenticationRoot: AuthenticationRootViewModel?
    private let persistence: BillingDocumentPersistenceActor
    private let adapter: SaleContextualPersistenceAdapter
    private let reservation: AppBillingDocumentReservationRepository
    private let storage: any BillingDocumentPDFStorageRepository
    private let composer: any BillingDocumentPDFComposer

    init(
        modelContainer: ModelContainer,
        observationSignal: SaleObservationSignal,
        reservation: AppBillingDocumentReservationRepository = .unavailable,
        storage: any BillingDocumentPDFStorageRepository = UnavailableBillingDocumentPDFStorageRepository(),
        composer: any BillingDocumentPDFComposer = TemplateBillingDocumentPDFComposer(bundle: .main)
    ) {
        persistence = BillingDocumentPersistenceActor(modelContainer: modelContainer)
        adapter = SaleContextualPersistenceAdapter(observationSignal: observationSignal)
        self.reservation = reservation
        self.storage = storage
        self.composer = composer
    }

    /// Recovers and generates only through the supplied capability; a missing shell remains recoverably unavailable.
    func model(
        draft: SaleDraftViewModel,
        destination: BillingDocumentDestination,
        clients: any ClientRepository
    ) -> BillingViewModel<AppBillingDocumentReservationRepository> {
        let sale = draft.sale
        let reserve = ReserveBillingDocumentUseCase(repository: reservation)
        guard let access = try? authenticationRoot?.makeBillingAssetAccess() else {
            return BillingViewModel(sale: sale, reserve: reserve, canPrepare: { false })
        }
        let render = RenderBillingDocumentUseCase(
            templates: BundleBillingDocumentTemplateRepository(bundle: .main),
            signatures: BillingNoPrivateSignatureRepository(),
            composer: composer,
            renderer: CoreGraphicsBillingPDFRenderer()
        )
        let engine = AppDependencies.materializeBillingDocumentUseCase(
            persistence: persistence,
            access: access,
            reserve: reserve,
            render: render,
            upload: AppDependencies.uploadBillingDocumentPDFUseCase(repository: storage)
        )
        return BillingViewModel(
            sale: sale,
            reserve: reserve,
            getClient: GetClientUseCase(repository: clients),
            materialize: engine,
            closeSale: { [adapter] request, context in
                try await access.validate()
                let accepted = try await adapter.closeSale(request, principalID: access.principalID, in: context)
                try await access.validate()
                return accepted
            },
            isDemonstration: reservation.isDemonstration,
            startsWithRecovery: true,
            canPrepare: {
                draft.billingDestination?.id == destination.id && draft.sale?.id == destination.saleID &&
                    draft.sale == sale && draft.canSelectBilling
            }
        )
    }
}

/// The active local form does not import or read a private business signature; absence is permitted by spec13.
private struct BillingNoPrivateSignatureRepository: BillingBusinessSignatureRepository {
    func loadSignature() async throws -> Data? { nil }
    func importSignature(_ data: Data) async throws { throw BillingAssetError.unauthorized }
}
