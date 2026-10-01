import Testing
@testable import FranAlonso

struct GetSaleUseCaseTests {
    @Test(arguments: [ViewModelSaleStage.draft, .inProgress, .awaitingPayment, .awaitingDocument, .closed, .voided])
    func `neutral local reads preserve every lifecycle snapshot without writing`(
        stage: ViewModelSaleStage
    ) async throws {
        let original = try viewModelSale(stage: stage)
        let repository = ViewModelSaleRepository(sales: [original])

        let recovered = try await GetSaleUseCase(repository: repository)(id: original.id)

        #expect(recovered == original)
        #expect(await repository.readCount == 1)
        #expect(await repository.writeCount == 0)
    }

    @Test
    func `neutral absence does not manufacture a draft`() async throws {
        let repository = ViewModelSaleRepository()

        let recovered = try await GetSaleUseCase(repository: repository)(id: SaleID(rawValue: viewModelUUID(1)))

        #expect(recovered == nil)
        #expect(await repository.writeCount == 0)
    }
}
