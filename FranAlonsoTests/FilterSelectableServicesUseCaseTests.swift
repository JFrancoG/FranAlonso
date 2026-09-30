import Foundation
import Testing
@testable import FranAlonso

@Suite("Selectable service filtering")
struct FilterSelectableServicesUseCaseTests {
    @Test(arguments: [
        (FilterSelectableServicesUseCase.Filter.all, [0, 2, 3]),
        (.professional, [0, 3]),
        (.product, [2])
    ])
    func `eligibility type and normalized name search preserve catalogue order`(
        filter: FilterSelectableServicesUseCase.Filter,
        expectedIndices: [Int]
    ) throws {
        let services = try [
            makeService(id: UUID(), name: "Corté especial"),
            makeService(id: UUID(), name: "Corte retirado", status: .inactive),
            makeService(
                id: UUID(),
                name: "Corte kit",
                type: .product,
                linkedProductID: UUID()
            ),
            makeService(id: UUID(), name: "Corte breve"),
            makeService(id: UUID(), name: "Color"),
            makeService(
                id: UUID(),
                name: "Corte viejo",
                type: .product,
                linkedProductID: UUID(),
                status: .inactive
            )
        ]
        let result = FilterSelectableServicesUseCase()(services, query: "  CORTE\n", filter: filter)
        #expect(result == expectedIndices.map { services[$0] })
    }

    @Test
    func `blank search keeps both active types and leaves administrative search unchanged`() throws {
        let professional = try makeService(id: UUID(), name: "Professional")
        let product = try makeService(
            id: UUID(),
            name: "Product",
            type: .product,
            linkedProductID: UUID()
        )
        let inactive = try makeService(id: UUID(), name: "Retired", status: .inactive)
        let services = [product, inactive, professional]
        #expect(FilterSelectableServicesUseCase()(services, query: " \n ", filter: .all) == [product, professional])
        #expect(FilterSelectableServicesUseCase()(services, query: "missing", filter: .all).isEmpty)
        #expect(SearchServicesUseCase()(services, query: "") == services)
    }
}
