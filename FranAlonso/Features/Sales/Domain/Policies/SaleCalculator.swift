import Foundation

/// Errors produced while calculating a sale's monetary breakdown.
enum SaleCalculatorError: Error, Equatable {
    /// A line uses a currency other than the one selected for the sale.
    case incompatibleCurrency(expected: Currency, actual: Currency)

    /// More than one line uses the same stable identity.
    case duplicateLineIdentity

    /// Rounded components do not satisfy the required monetary identities.
    case inconsistentBreakdown
}

/// The rounded monetary breakdown derived from one immutable sale-line snapshot.
///
/// This transient projection is intentionally not `Codable`; persisted line
/// snapshots must be recalculated instead of restoring untrusted derived totals.
struct SaleLineCalculation: Identifiable, Equatable {
    let id: SaleLineID
    private let storedSubtotal: Money
    private let storedDiscountAmount: Money
    private let storedTaxableBase: Money
    private let storedTaxAmount: Money
    private let storedTotal: Money

    var subtotal: Money {
        storedSubtotal
    }

    var discountAmount: Money {
        storedDiscountAmount
    }

    var taxableBase: Money {
        storedTaxableBase
    }

    var taxAmount: Money {
        storedTaxAmount
    }

    var total: Money {
        storedTotal
    }
}

/// The aggregate monetary breakdown derived from a collection of sale lines.
///
/// Values are transient projections. The original line snapshots remain the
/// persisted commercial source of truth, so this type is intentionally not
/// `Codable` and must be reconstructed through `SaleCalculator`.
struct SaleCalculation: Equatable {
    let lineCalculations: [SaleLineCalculation]
    private let storedSubtotal: Money
    private let storedDiscountAmount: Money
    private let storedTaxableBase: Money
    private let storedTaxAmount: Money
    private let storedTotal: Money

    var subtotal: Money {
        storedSubtotal
    }

    var discountAmount: Money {
        storedDiscountAmount
    }

    var taxableBase: Money {
        storedTaxableBase
    }

    var taxAmount: Money {
        storedTaxAmount
    }

    var total: Money {
        storedTotal
    }
}

extension SaleLineCalculation {
    /// Creates a line projection only when currencies and arithmetic identities agree.
    ///
    /// - Throws: `SaleCalculatorError.inconsistentBreakdown` when components use
    ///   different currencies, the discount does not reconcile with the total,
    ///   or taxable base plus tax does not equal the total.
    fileprivate init(
        id: SaleLineID,
        subtotal: Money,
        discountAmount: Money,
        taxableBase: Money,
        taxAmount: Money,
        total: Money
    ) throws {
        let currency = subtotal.currency
        guard discountAmount.currency == currency,
              taxableBase.currency == currency,
              taxAmount.currency == currency,
              total.currency == currency,
              subtotal.amount - discountAmount.amount == total.amount,
              taxableBase.amount + taxAmount.amount == total.amount else {
            throw SaleCalculatorError.inconsistentBreakdown
        }

        self.init(
            id: id,
            storedSubtotal: subtotal,
            storedDiscountAmount: discountAmount,
            storedTaxableBase: taxableBase,
            storedTaxAmount: taxAmount,
            storedTotal: total
        )
    }
}

extension SaleCalculation {
    /// Composes aggregate amounts exclusively from validated line projections.
    ///
    /// - Throws: `SaleCalculatorError.duplicateLineIdentity` for repeated line
    ///   IDs, `SaleCalculatorError.incompatibleCurrency` when a projection does
    ///   not use the requested currency, or `MoneyError.invalidAmount` when an
    ///   aggregate cannot be represented as a monetary value.
    fileprivate init(
        lineCalculations: [SaleLineCalculation],
        currency: Currency
    ) throws {
        guard Set(lineCalculations.map(\.id)).count == lineCalculations.count else {
            throw SaleCalculatorError.duplicateLineIdentity
        }

        let zero = try Money(amount: .zero, currency: currency)
        var subtotal = zero
        var discountAmount = zero
        var taxableBase = zero
        var taxAmount = zero
        var total = zero

        for lineCalculation in lineCalculations {
            guard lineCalculation.total.currency == currency else {
                throw SaleCalculatorError.incompatibleCurrency(
                    expected: currency,
                    actual: lineCalculation.total.currency
                )
            }

            subtotal = try subtotal.adding(lineCalculation.subtotal)
            discountAmount = try discountAmount.adding(lineCalculation.discountAmount)
            taxableBase = try taxableBase.adding(lineCalculation.taxableBase)
            taxAmount = try taxAmount.adding(lineCalculation.taxAmount)
            total = try total.adding(lineCalculation.total)
        }

        self.init(
            lineCalculations: lineCalculations,
            storedSubtotal: subtotal,
            storedDiscountAmount: discountAmount,
            storedTaxableBase: taxableBase,
            storedTaxAmount: taxAmount,
            storedTotal: total
        )
    }
}

/// A pure policy for deriving sale totals from tax-inclusive line snapshots.
struct SaleCalculator {
    /// Calculates discounted totals and extracts included tax for each line.
    ///
    /// Each line subtotal, discount, taxable base, and tax amount is normalized
    /// independently to the currency's minor units before aggregate values are
    /// summed. This keeps mixed tax rates and repeated calculations deterministic.
    ///
    /// - Parameters:
    ///   - lines: Immutable commercial snapshots in input display order.
    ///   - currency: The currency required for every line and for an empty result.
    /// - Returns: Per-line and aggregate monetary breakdowns in `currency`.
    /// - Throws: `SaleCalculatorError.incompatibleCurrency` when a line uses a
    ///   different currency, `SaleCalculatorError.duplicateLineIdentity` when
    ///   line IDs repeat, `SaleCalculatorError.inconsistentBreakdown` when
    ///   rounded components do not reconcile, or `MoneyError.invalidAmount` if
    ///   decimal arithmetic cannot be represented as a monetary value.
    func calculate(
        lines: [SaleLine],
        currency: Currency
    ) throws -> SaleCalculation {
        var lineCalculations: [SaleLineCalculation] = []

        lineCalculations.reserveCapacity(lines.count)

        for line in lines {
            guard line.unitPrice.currency == currency else {
                throw SaleCalculatorError.incompatibleCurrency(
                    expected: currency,
                    actual: line.unitPrice.currency
                )
            }

            let lineSubtotal = try Money(
                amount: line.unitPrice.amount * Decimal(line.quantity),
                currency: currency
            )
            let lineDiscount = try Money(
                amount: lineSubtotal.amount * (line.discount?.percentage ?? .zero) / 100,
                currency: currency
            )
            let lineTotal = try Money(
                amount: lineSubtotal.amount - lineDiscount.amount,
                currency: currency
            )
            let lineTaxableBase = try Money(
                amount: lineTotal.amount / (1 + line.taxRate.percentage / 100),
                currency: currency
            )
            let lineTax = try Money(
                amount: lineTotal.amount - lineTaxableBase.amount,
                currency: currency
            )

            lineCalculations.append(
                try SaleLineCalculation(
                    id: line.id,
                    subtotal: lineSubtotal,
                    discountAmount: lineDiscount,
                    taxableBase: lineTaxableBase,
                    taxAmount: lineTax,
                    total: lineTotal
                )
            )
        }

        return try SaleCalculation(
            lineCalculations: lineCalculations,
            currency: currency
        )
    }
}
