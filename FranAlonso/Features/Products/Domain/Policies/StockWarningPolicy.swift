/// Errors produced while projecting sale-line stock consumption.
enum StockWarningPolicyError: Error, Equatable {
    /// More than one input line uses the same stable identity.
    case duplicateLineIdentity

    /// A product-linked line has no current stock value to project from.
    case missingAvailableQuantity(productID: ProductID)

    /// Subtracting a line quantity exceeds the range representable by `Int`.
    case quantityOverflow(productID: ProductID)
}

/// A transient stock projection for one product-linked sale line.
///
/// The projection identifies whether consuming the line would make stock
/// negative. It is intentionally not `Codable` because current inventory may
/// change and the impact must be recalculated before confirmation.
struct StockImpact: Identifiable, Equatable {
    let id: SaleLineID
    let productID: ProductID
    private let storedAvailableQuantity: Int
    private let storedConsumedQuantity: Int
    private let storedProjectedQuantity: Int

    var availableQuantity: Int {
        storedAvailableQuantity
    }

    var consumedQuantity: Int {
        storedConsumedQuantity
    }

    var projectedQuantity: Int {
        storedProjectedQuantity
    }

    var requiresWarning: Bool {
        projectedQuantity < 0
    }
}

extension StockImpact {
    /// Projects one validated sale line from its product's current stock.
    ///
    /// - Parameters:
    ///   - line: A sale-line snapshot with a strictly positive quantity.
    ///   - productID: The physical product consumed by the line.
    ///   - availableQuantity: Stock available immediately before this line.
    /// - Throws: `StockWarningPolicyError.quantityOverflow` when the projected
    ///   quantity cannot be represented by `Int`.
    fileprivate init(
        line: SaleLine,
        productID: ProductID,
        availableQuantity: Int
    ) throws {
        let (projectedQuantity, overflow) = availableQuantity
            .subtractingReportingOverflow(line.quantity)

        guard !overflow else {
            throw StockWarningPolicyError.quantityOverflow(
                productID: productID
            )
        }

        self.init(
            id: line.id,
            productID: productID,
            storedAvailableQuantity: availableQuantity,
            storedConsumedQuantity: line.quantity,
            storedProjectedQuantity: projectedQuantity
        )
    }
}

/// A pure policy that warns about, but never rejects, insufficient sale stock.
struct StockWarningPolicy {
    /// Projects product stock consumption for the supplied sale lines.
    ///
    /// Professional lines without a product link are omitted. Repeated product
    /// links consume cumulatively in input order, so each impact starts from the
    /// previous impact's projected quantity. A negative projection is returned
    /// with `requiresWarning`; insufficiency itself never throws.
    ///
    /// - Parameters:
    ///   - lines: Immutable sale-line snapshots in display order.
    ///   - availableQuantities: Current stock keyed by every linked product.
    /// - Returns: One impact per product-linked line, preserving input order.
    /// - Throws: `StockWarningPolicyError.duplicateLineIdentity` for repeated
    ///   line IDs, `StockWarningPolicyError.missingAvailableQuantity` when a
    ///   linked product has no input stock, or
    ///   `StockWarningPolicyError.quantityOverflow` when subtraction overflows.
    func analyze(
        lines: [SaleLine],
        availableQuantities: [ProductID: Int]
    ) throws -> [StockImpact] {
        guard Set(lines.map(\.id)).count == lines.count else {
            throw StockWarningPolicyError.duplicateLineIdentity
        }

        var remainingQuantities = availableQuantities
        var impacts: [StockImpact] = []

        impacts.reserveCapacity(lines.count)

        for line in lines {
            guard let productID = line.linkedProductID else {
                continue
            }

            guard let availableQuantity = remainingQuantities[productID] else {
                throw StockWarningPolicyError.missingAvailableQuantity(
                    productID: productID
                )
            }

            let impact = try StockImpact(
                line: line,
                productID: productID,
                availableQuantity: availableQuantity
            )

            impacts.append(impact)
            remainingQuantities[productID] = impact.projectedQuantity
        }

        return impacts
    }
}
