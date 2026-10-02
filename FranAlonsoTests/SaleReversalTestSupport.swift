import Foundation
import SwiftData
import Testing
@testable import FranAlonso

let saleReversalTestID = SaleReversalID(rawValue: saleStockUUID(0xf2, 1))
let saleReversalTestDate = Date(timeIntervalSinceReferenceDate: 300.125)

func saleReversalClosedFixture(firstQuantity: Int = 2, professionalOnly: Bool = false) throws -> Sale {
    var sale = try saleStockFixture(firstQuantity: firstQuantity, professionalOnly: professionalOnly)
    try sale.close(
        documentID: BillingDocumentID(rawValue: saleStockUUID(0xe9, 1)),
        closedAt: Date(timeIntervalSinceReferenceDate: 200.125)
    )
    return sale
}

func saleReversalVoidedFixture(_ closed: Sale, id: SaleReversalID = saleReversalTestID) throws -> Sale {
    var sale = closed
    try sale.void(reversalID: id, voidedAt: saleReversalTestDate)
    return sale
}

@MainActor
func seedSaleReversal(_ sale: Sale, in container: ModelContainer) throws {
    _ = try saleStockRepository(in: container)
    let context = ModelContext(container)
    try SaleLocalDataSource().upsert(sale, in: context)
    for movement in try SaleStockMovementPolicy()(sale: sale, paymentID: saleStockPaymentID) {
        _ = try StockLocalDataSource().append(movement, in: context)
    }
}

func saleReversalSourceVoid(
    _ sale: Sale,
    source: SaleLocalDataSource = SaleLocalDataSource(),
    in context: ModelContext
) throws -> Sale {
    try source.voidSale(
        sale,
        reversalID: saleReversalTestID,
        voidedAt: saleReversalTestDate,
        operationID: saleStockUUID(0x98, 1),
        in: context
    )
}

func saleReversalDataSource(
    save: @escaping @Sendable (ModelContext) throws -> Void
) -> SaleLocalDataSource {
    SaleLocalDataSource(
        reversalSave: save,
        paymentSave: { try $0.save() }
    )
}
