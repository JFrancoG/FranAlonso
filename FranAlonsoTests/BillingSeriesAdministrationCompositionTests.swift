import Foundation
import Testing
@testable import FranAlonso

struct BillingSeriesAdministrationCompositionTests {
    @MainActor
    @Test("App composition cannot acquire administrative numbering authority")
    func administrativeFactoryRemainsUnavailable() async throws {
        let request = try BillingSeriesAdjustmentRequest(
            operationID: try #require(UUID(uuidString: "E5D41B34-78E7-47F5-907D-5A4D8DCC7111")),
            series: .ticket,
            expectedLastNumber: 0,
            targetLastNumber: 100,
            reason: .seriesAlignment
        )
        let adjust = AppDependencies.billingSeriesAdjustment()
        await #expect(throws: BillingSeriesAdjustmentError.unavailable) {
            try await adjust(request)
        }
    }
}
