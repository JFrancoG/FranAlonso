import Foundation

extension AppDependencies {
    typealias BillingFormFactory = @MainActor @Sendable (
        SaleDraftViewModel,
        BillingDocumentDestination
    ) -> BillingViewModel<UnavailableBillingDocumentReservationRepository>

    /// Prepares fiscal input from the parent's paid snapshot while reservation remains explicitly unavailable.
    /// Closing or replacing the parent session revokes preparation; the local client profile is only a prefill source.
    static func billingFormFactory(clientRepository: any ClientRepository) -> BillingFormFactory {
        { draft, destination in
            let sale = draft.sale
            return BillingViewModel(
                sale: sale,
                reserve: ReserveBillingDocumentUseCase(repository: UnavailableBillingDocumentReservationRepository()),
                getClient: GetClientUseCase(repository: clientRepository),
                canPrepare: {
                    draft.billingDestination?.id == destination.id && draft.sale?.id == destination.saleID &&
                        draft.sale == sale && draft.canSelectBilling
                }
            )
        }
    }
}
