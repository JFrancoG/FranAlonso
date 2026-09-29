#if FRANALONSO_AUTH_FIXTURE
import Foundation
import SwiftData

/// Adds validated synthetic commercial services after the demo product seed.
struct DevelopDemoServiceScenario {
    @MainActor
    static func seed(in container: ModelContainer) throws {
        let context = ModelContext(container)
        let source = ServiceLocalDataSource()
        for (index, name) in ["Corte y peinado DEMO", "Champú DEMO venta"].enumerated() {
            let suffix = UInt8(index + 1)
            let isProduct = index == 1
            _ = try source.createService(
                id: ServiceID(rawValue: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, suffix))),
                profile: ServiceProfile(
                    name: name,
                    type: isProduct ? .product : .professional,
                    linkedProductID: isProduct ? DevelopDemoProductScenario.primaryProductID : nil,
                    price: Money(amount: isProduct ? 20 : 35, currency: .eur),
                    taxRate: TaxRate(percentage: 21),
                    discount: nil
                ),
                operationID: UUID(uuid: (10, 5, 0, 0, 0, 0, 64, 0, 144, 0, 0, 0, 0, 0, 0, suffix)),
                in: context
            )
        }
    }
}
#endif
