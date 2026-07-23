/// Persists validated sale snapshots through the local-first boundary.
struct SaveSaleUseCase {
    private let saleRepository: any SaleRepository

    /// Saves a sale locally without waiting for remote synchronization.
    ///
    /// - Parameter sale: The validated sale snapshot to persist.
    /// - Throws: An error when local persistence cannot accept the snapshot.
    func callAsFunction(_ sale: Sale) async throws {
        try await saleRepository.saveSale(sale)
    }
}

extension SaveSaleUseCase {
    /// Creates the use case with its feature-owned repository boundary.
    ///
    /// - Parameter repository: The repository that persists sale snapshots.
    init(repository: any SaleRepository) {
        self.init(saleRepository: repository)
    }
}
