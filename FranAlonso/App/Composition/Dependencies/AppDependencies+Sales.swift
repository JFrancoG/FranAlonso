import Foundation

extension AppDependencies {
    /// Supplies caller-owned observations and client labels over the same local source as draft acceptance.
    static func workdayFactory(
        saleRepository: any SaleRepository,
        clientRepository: any ClientRepository
    ) -> WorkdayFactory {
        {
            WorkdayViewModel(
                observe: ObserveSalesUseCase(repository: saleRepository),
                getClient: GetClientUseCase(repository: clientRepository)
            )
        }
    }

    /// Creates one independent Store per presentation; identity and creation time stay fixed across retries.
    /// Inspection reads and accepted edits share the existing repository and observation signal.
    static func saleDraftFactory(
        saleRepository: any SaleRepository,
        clientRepository: any ClientRepository
    ) -> SaleDraftFactory {
        { destination in
            SaleDraftViewModel(
                destination: destination,
                createdAt: Date(),
                currency: .eur,
                create: CreateSaleDraftUseCase(repository: saleRepository),
                getDraft: GetSaleDraftUseCase(repository: saleRepository),
                update: UpdateSaleDraftUseCase(repository: saleRepository),
                discard: DiscardSaleDraftUseCase(repository: saleRepository),
                getSale: GetSaleUseCase(repository: saleRepository),
                getClient: GetClientUseCase(repository: clientRepository)
            )
        }
    }
}
