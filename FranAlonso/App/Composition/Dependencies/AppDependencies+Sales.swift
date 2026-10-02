import Foundation

extension AppDependencies {
    /// Applies an editor's frozen percentage through the parent's retained draft acceptance capability.
    /// Ending either presentation revokes the capability without creating another sale Store.
    @MainActor
    func makeSaleDiscount(
        for draft: SaleDraftViewModel,
        destination: SaleDiscountDestination,
        locale: Locale
    ) -> SaleDiscountViewModel {
        let target: SaleDiscountViewModel.Target
        let discount: Discount?
        switch destination.target {
        case let .line(id):
            let line = draft.sale?.lines.first { $0.id == id }
            target = .line(serviceName: line?.serviceName ?? "")
            discount = line?.discount
        case .global:
            target = .global
            discount = draft.sale?.globalDiscount?.discount
        }
        return SaleDiscountViewModel(
            target: target,
            discount: discount,
            locale: locale,
            canEdit: {
                guard draft.discountDestination?.id == destination.id else { return false }
                switch destination.target {
                case let .line(id): return draft.canEditDiscount(for: id)
                case .global: return draft.canEditGlobalDiscount
                }
            },
            apply: { discount in
                switch destination.target {
                case let .line(id):
                    _ = try await draft.setDiscount(discount, for: id)
                case .global:
                    _ = try await draft.setGlobalDiscount(discount)
                }
            }
        )
    }

    /// Shares the local catalogue and accepts captured lines through the parent's single retained Store.
    /// Closing the selector invalidates only its presentation; it never closes or discards the parent draft.
    @MainActor
    func makeSaleServicePicker(for draft: SaleDraftViewModel) -> SaleServicePickerViewModel {
        SaleServicePickerViewModel(
            picker: makeServicePicker(),
            canAdd: { draft.canAddServices },
            addLine: { line in
                _ = try await draft.addLine(line)
            }
        )
    }

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
