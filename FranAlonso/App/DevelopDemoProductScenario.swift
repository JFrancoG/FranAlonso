#if FRANALONSO_AUTH_FIXTURE
import Foundation
import SwiftData

/// Adds validated synthetic products before the isolated launch exposes its container.
struct DevelopDemoProductScenario {
    /// The unpublished container must be discarded if any seed write fails.
    @MainActor
    static func seed(in container: ModelContainer) throws {
        let context = ModelContext(container)
        let source = ProductLocalDataSource()
        for (index, name) in ["Champú DEMO hidratante", "Mascarilla DEMO nutritiva"].enumerated() {
            let suffix = UInt8(index + 1)
            _ = try source.createProduct(
                id: ProductID(rawValue: UUID(uuid: (9, 4, 0, 0, 0, 0, 64, 0, 128, 0, 0, 0, 0, 0, 0, suffix))),
                profile: ProductProfile(name: name),
                operationID: UUID(uuid: (9, 4, 0, 0, 0, 0, 64, 0, 144, 0, 0, 0, 0, 0, 0, suffix)),
                in: context
            )
        }
    }
}
#endif
