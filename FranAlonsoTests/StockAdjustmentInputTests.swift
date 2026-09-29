import Foundation
import Testing
@testable import FranAlonso

@Suite("Stock adjustment input")
struct StockAdjustmentInputTests {
    @Test(arguments: ["1", " 0002\n", String(Int.max)], [StockAdjustmentDirection.entry, .withdrawal])
    func `positive ASCII units become an exact signed delta`(
        input: String,
        direction: StockAdjustmentDirection
    ) throws {
        let magnitude = input == "1" ? 1 : input == " 0002\n" ? 2 : Int.max
        let expected = direction == .entry ? magnitude : -magnitude
        #expect(try StockAdjustmentQuantity(unitsText: input, direction: direction).delta == expected)
    }

    @Test(arguments: ["", " \n", "0", "000", "-1", "+1", "1.0", "1,000", "1 2", "١", "１", "9223372036854775808"])
    func `invalid units fail before a movement can be prepared`(_ input: String) {
        #expect(throws: StockError.invalidQuantity) {
            try StockAdjustmentQuantity(unitsText: input, direction: .entry)
        }
    }

    @Test
    func `manual preparation normalizes reason and preserves signed extremes`() throws {
        let product = try stockTestProduct()
        let id = StockMovementID(rawValue: UUID())
        let date = Date(timeIntervalSinceReferenceDate: 42)
        let movement = try PrepareStockAdjustmentUseCase()(
            id: id,
            productID: product.id,
            quantityDelta: Int.min,
            reason: "  Initial count \n",
            occurredAt: date
        )
        #expect(movement.reason == "Initial count")
        #expect(movement.quantityDelta == Int.min)
        #expect(movement.origin == .manual(reference: id))
        #expect(movement.occurredAt == date)
        #expect(throws: StockError.invalidReason) {
            try PrepareStockAdjustmentUseCase()(
                id: id,
                productID: product.id,
                quantityDelta: 1,
                reason: " \n",
                occurredAt: date
            )
        }
    }
}
