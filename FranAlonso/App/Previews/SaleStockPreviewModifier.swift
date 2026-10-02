import SwiftData
import SwiftUI

/// Prepares one isolated draft with exact exhaustion, a repeated-product deficit and a professional line.
struct SaleStockPreviewModifier: PreviewModifier {
    struct Context {
        let base: AppPreviewModifier.Context
        let model: SaleDraftViewModel
    }

    static func makeSharedContext() async throws -> Context {
        let base = try AppPreviewModifier.makeSharedContext()
        let productID = ProductPreviewFixtures.standard.primaryProduct.id
        let movementID = StockMovementID(rawValue: identifier(1))
        let movement = try StockMovement(
            id: movementID,
            productID: productID,
            quantityDelta: 1,
            reason: "Synthetic preview opening stock",
            occurredAt: Date(timeIntervalSinceReferenceDate: 100),
            origin: .manual(reference: movementID)
        )
        _ = try StockLocalDataSource().append(movement, in: base.modelContainer.mainContext)
        let lines = try [
            line(
                2,
                name: "Tratamiento físico con agotamiento exacto del producto de demostración",
                quantity: 1,
                productID: productID
            ),
            line(
                3,
                name: "Tratamiento de hidratación intensiva y peinado para una ocasión especial de demostración",
                quantity: 2,
                productID: productID
            ),
            line(
                4,
                name: "Asesoramiento profesional sin consumo de producto",
                quantity: 1,
                productID: nil
            )
        ]
        let sale = try Sale.draft(
            id: SaleID(rawValue: identifier(5)),
            clientID: nil,
            createdAt: Date(timeIntervalSinceReferenceDate: 100),
            lines: lines
        )
        try SaleLocalDataSource().upsert(sale, in: base.modelContainer.mainContext)
        let model = base.dependencies.makeSaleDraft(
            SaleDraftDestination(id: identifier(6), saleID: sale.id, mode: .editDraft)
        )
        _ = try await model.load()
        return Context(base: base, model: model)
    }

    func body(content: Content, context: Context) -> some View {
        content
            .modelContainer(context.base.modelContainer)
            .environment(\.appDependencies, context.base.dependencies)
            .environment(\.saleStockPreviewModel, context.model)
    }

    private static func line(
        _ index: UInt8,
        name: String,
        quantity: Int,
        productID: ProductID?
    ) throws -> SaleLine {
        try SaleLine.upcoming(
            id: SaleLineID(rawValue: identifier(index)),
            serviceID: ServiceID(rawValue: identifier(7)),
            serviceName: name,
            quantity: quantity,
            unitPrice: Money(amount: 10, currency: .eur),
            taxRate: TaxRate(percentage: 21),
            discount: nil,
            linkedProductID: productID
        )
    }

    private static func identifier(_ index: UInt8) -> UUID {
        UUID(uuid: (12, 3, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, index))
    }
}

extension EnvironmentValues {
    @Entry var saleStockPreviewModel: SaleDraftViewModel? = nil
}
