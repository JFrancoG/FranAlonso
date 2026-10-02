import Foundation
import SwiftData

/// Stable local snapshots for operational previews and the isolated Develop workday scenario.
struct SalesPreviewFixtures {
    let sales: [Sale]

    @MainActor
    func seed(in context: ModelContext) throws {
        let source = SaleLocalDataSource()
        for sale in sales {
            if try source.sale(id: sale.id, in: context) == nil {
                try source.upsert(sale, in: context)
            }
        }
    }
}

extension SalesPreviewFixtures {
    static let albaID = ClientID(rawValue: UUID(uuid: (8, 138, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 1)))
    static let brunoID = ClientID(rawValue: UUID(uuid: (8, 138, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, 2)))

    static let workday: SalesPreviewFixtures = {
        do {
            var sales: [Sale] = []
            for index in UInt8(1)...6 {
                let line = try SaleLine.upcoming(
                    id: SaleLineID(rawValue: uuid(index + 20)),
                    serviceID: ServiceID(rawValue: uuid(90)),
                    serviceName: index == 3 ? "Tratamiento de hidratación intensiva y peinado para ocasión especial" :
                        "Corte y peinado DEMO",
                    quantity: 1,
                    unitPrice: Money(amount: Decimal(string: "24.20")!, currency: .eur),
                    taxRate: TaxRate(percentage: 21),
                    discount: [3, 4].contains(index) ? Discount(percentage: 10) : nil,
                    linkedProductID: nil
                )
                var sale = try Sale.draft(
                    id: SaleID(rawValue: uuid(index)),
                    clientID: [1, 4].contains(index) ? nil : (index == 3 ? brunoID : albaID),
                    createdAt: Date(timeIntervalSince1970: 1_790_000_000 + Double(index) * 60),
                    lines: [line],
                    globalDiscount: [3, 4].contains(index) ?
                        SaleGlobalDiscount(discount: Discount(percentage: 20), policy: .lineThenGlobalV1) : nil
                )
                if index >= 4 {
                    try sale.start()
                    try sale.startLine(id: line.id)
                }
                if index >= 5 {
                    try sale.completeLine(id: line.id)
                }
                if index == 6 {
                    try sale.registerPayment(
                        id: PaymentID(rawValue: uuid(80)),
                        method: .card,
                        paidAt: Date(timeIntervalSince1970: 1_790_001_000)
                    )
                }
                sales.append(sale)
            }
            return SalesPreviewFixtures(sales: sales)
        } catch {
            preconditionFailure("Fixed workday snapshots must satisfy Domain invariants")
        }
    }()

    static func destination(index: Int, mode: SaleDraftDestination.Mode) -> SaleDraftDestination {
        SaleDraftDestination(id: uuid(UInt8(index + 40)), saleID: workday.sales[index].id, mode: mode)
    }

    static func calculation(for sale: Sale) -> SaleCalculation {
        do {
            return try SaleCalculator().calculate(sale: sale, currency: .eur)
        } catch {
            preconditionFailure("Fixed workday amounts must satisfy Domain invariants")
        }
    }

    @MainActor
    static func seedPreviewClients(in context: ModelContext) throws {
        let source = ClientLocalDataSource()
        for (id, name) in [(albaID, "Alba DEMO"), (brunoID, "Bruno DEMO")] {
            if try source.client(id: id, in: context) == nil {
                _ = try source.createClient(
                    id: id,
                    profile: ClientProfile(displayName: name),
                    operationID: id.rawValue,
                    in: context
                )
            }
        }
    }

    private static func uuid(_ value: UInt8) -> UUID {
        UUID(uuid: (11, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, value))
    }
}
