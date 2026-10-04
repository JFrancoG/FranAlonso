import Foundation

extension AppDependencies {
    /// Exposes no administrative privilege or SDK client until a separate live authority is approved.
    /// Both normal and isolated demo compositions retain this explicit unavailable boundary.
    static func billingSeriesAdjustment() -> AdjustBillingSeriesUseCase<UnavailableBillingSeriesAdjustmentRepository> {
        AdjustBillingSeriesUseCase(repository: UnavailableBillingSeriesAdjustmentRepository())
    }

    typealias BillingFormFactory = @MainActor @Sendable (
        SaleDraftViewModel,
        BillingDocumentDestination
    ) -> BillingViewModel<AppBillingDocumentReservationRepository>

    /// Prepares fiscal input from the parent's paid snapshot while reservation remains explicitly unavailable.
    /// Closing or replacing the parent session revokes preparation; the local client profile is only a prefill source.
    static func billingFormFactory(
        clientRepository: any ClientRepository,
        composition: BillingDocumentComposition? = nil
    ) -> BillingFormFactory {
        { draft, destination in
            if let composition {
                return composition.model(draft: draft, destination: destination, clients: clientRepository)
            }
            let sale = draft.sale
            return BillingViewModel(
                sale: sale,
                reserve: ReserveBillingDocumentUseCase(repository: AppBillingDocumentReservationRepository.unavailable),
                getClient: GetClientUseCase(repository: clientRepository),
                canPrepare: {
                    draft.billingDestination?.id == destination.id && draft.sale?.id == destination.saleID &&
                        draft.sale == sale && draft.canSelectBilling
                }
            )
        }
    }
}
