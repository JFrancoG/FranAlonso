extension AppDependencies {
    /// Shares the composition's ledger reader and accepts UI writes in the caller's ephemeral context.
    static func stockAdjustmentFactory(
        productRepository: any ProductRepository,
        stockRepository: any StockRepository,
        observationSignal: ProductObservationSignal
    ) -> StockAdjustmentFactory {
        { destination in
            let adapter = StockContextualPersistenceAdapter(observationSignal: observationSignal)
            return StockAdjustmentViewModel(
                destination: destination,
                getProduct: GetProductUseCase(repository: productRepository),
                getQuantity: { productID in
                    try await stockRepository.quantity(for: productID)
                },
                accept: { movement, context in
                    try await adapter.append(movement, in: context)
                }
            )
        }
    }

    /// Finite snapshots have no ledger; writes fail before touching the supplied context.
    static func readOnlyStockAdjustmentFactory(productRepository: any ProductRepository) -> StockAdjustmentFactory {
        { destination in
            StockAdjustmentViewModel(
                destination: destination,
                getProduct: GetProductUseCase(repository: productRepository),
                getQuantity: { _ in 0 },
                accept: { _, _ in throw StockError.storageFailure }
            )
        }
    }
}
