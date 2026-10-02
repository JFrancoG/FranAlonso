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
    private let storedLineDiscountAmount: Money
    private let storedGlobalDiscountAmount: Money
    private let storedTaxableBase: Money
    private let storedTaxAmount: Money
    private let storedTotal: Money

    var subtotal: Money {
        storedSubtotal
    }

    var discountAmount: Money {
        storedDiscountAmount
    }

    var lineDiscountAmount: Money {
        storedLineDiscountAmount
    }

    var globalDiscountAmount: Money {
        storedGlobalDiscountAmount
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
    private let storedLineDiscountAmount: Money
    private let storedGlobalDiscountAmount: Money
    private let storedTaxableBase: Money
    private let storedTaxAmount: Money
    private let storedTotal: Money

    var subtotal: Money {
        storedSubtotal
    }

    var discountAmount: Money {
        storedDiscountAmount
    }

    var lineDiscountAmount: Money {
        storedLineDiscountAmount
    }

    var globalDiscountAmount: Money {
        storedGlobalDiscountAmount
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
    ///   different currencies, both discounts do not reconcile with the total,
    ///   or taxable base plus tax does not equal the total; `MoneyError.invalidAmount`
    ///   when an identity cannot be checked with exact decimal arithmetic.
    fileprivate init(
        id: SaleLineID,
        subtotal: Money,
        lineDiscountAmount: Money,
        globalDiscountAmount: Money,
        taxableBase: Money,
        taxAmount: Money,
        total: Money
    ) throws {
        let currency = subtotal.currency
        guard lineDiscountAmount.currency == currency,
              globalDiscountAmount.currency == currency,
              taxableBase.currency == currency,
              taxAmount.currency == currency,
              total.currency == currency else {
            throw SaleCalculatorError.inconsistentBreakdown
        }

        let discountAmount = try Money(
            amount: lineDiscountAmount.amount.addingExactly(globalDiscountAmount.amount),
            currency: currency
        )
        guard try subtotal.amount.subtractingExactly(discountAmount.amount) == total.amount,
              try taxableBase.amount.addingExactly(taxAmount.amount) == total.amount else {
            throw SaleCalculatorError.inconsistentBreakdown
        }

        self.init(
            id: id,
            storedSubtotal: subtotal,
            storedDiscountAmount: discountAmount,
            storedLineDiscountAmount: lineDiscountAmount,
            storedGlobalDiscountAmount: globalDiscountAmount,
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
    ///   not use the requested currency, `SaleCalculatorError.inconsistentBreakdown`
    ///   when aggregate identities do not reconcile, or `MoneyError.invalidAmount`
    ///   when aggregation or identity checks lose decimal precision.
    fileprivate init(lineCalculations: [SaleLineCalculation], currency: Currency) throws {
        guard Set(lineCalculations.map(\.id)).count == lineCalculations.count else {
            throw SaleCalculatorError.duplicateLineIdentity
        }

        let zero = try Money(amount: .zero, currency: currency)
        var subtotal = zero
        var discountAmount = zero
        var lineDiscountAmount = zero
        var globalDiscountAmount = zero
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

            subtotal = try Money(
                amount: subtotal.amount.addingExactly(lineCalculation.subtotal.amount),
                currency: currency
            )
            discountAmount = try Money(
                amount: discountAmount.amount.addingExactly(lineCalculation.discountAmount.amount),
                currency: currency
            )
            lineDiscountAmount = try Money(
                amount: lineDiscountAmount.amount.addingExactly(lineCalculation.lineDiscountAmount.amount),
                currency: currency
            )
            globalDiscountAmount = try Money(
                amount: globalDiscountAmount.amount.addingExactly(lineCalculation.globalDiscountAmount.amount),
                currency: currency
            )
            taxableBase = try Money(
                amount: taxableBase.amount.addingExactly(lineCalculation.taxableBase.amount),
                currency: currency
            )
            taxAmount = try Money(
                amount: taxAmount.amount.addingExactly(lineCalculation.taxAmount.amount),
                currency: currency
            )
            total = try Money(amount: total.amount.addingExactly(lineCalculation.total.amount), currency: currency)
        }

        guard try lineDiscountAmount.amount.addingExactly(globalDiscountAmount.amount) == discountAmount.amount,
              try subtotal.amount.subtractingExactly(discountAmount.amount) == total.amount,
              try taxableBase.amount.addingExactly(taxAmount.amount) == total.amount else {
            throw SaleCalculatorError.inconsistentBreakdown
        }

        self.init(
            lineCalculations: lineCalculations,
            storedSubtotal: subtotal,
            storedDiscountAmount: discountAmount,
            storedLineDiscountAmount: lineDiscountAmount,
            storedGlobalDiscountAmount: globalDiscountAmount,
            storedTaxableBase: taxableBase,
            storedTaxAmount: taxAmount,
            storedTotal: total
        )
    }
}

/// A pure policy for deriving sale totals from tax-inclusive line snapshots.
struct SaleCalculator {
    /// Reconstructs the monetary projection from the complete historical commercial snapshot.
    ///
    /// V1 rounds the captured line promotion, then the global discount on that line's
    /// residual, before extracting included tax. An absent global term adds no discount;
    /// the explicit currency also determines every zero amount in an empty result.
    /// - Throws: Currency, precision or monetary reconciliation errors from the calculation policy.
    func calculate(sale: Sale, currency: Currency) throws -> SaleCalculation {
        switch sale.globalDiscount?.policy {
        case .lineThenGlobalV1:
            return try calculate(
                lines: sale.lines,
                globalPercentage: sale.globalDiscount?.discount.percentage ?? .zero,
                currency: currency
            )
        case nil:
            return try calculate(lines: sale.lines, currency: currency)
        }
    }

    /// Calculates discounted totals and extracts included tax for each line.
    ///
    /// Each line subtotal, discount, taxable base, and tax amount is normalized
    /// independently to the currency's minor units before aggregate values are
    /// summed. This keeps mixed tax rates and repeated calculations deterministic.
    /// Quantity products and monetary sums or differences must be exact. Discount
    /// and tax rounding must be certified when their intermediate decimals lose
    /// precision; an ambiguous monetary result is rejected.
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
    func calculate(lines: [SaleLine], currency: Currency) throws -> SaleCalculation {
        try calculate(lines: lines, globalPercentage: .zero, currency: currency)
    }
}

private extension SaleCalculator {
    func calculate(lines: [SaleLine], globalPercentage: Decimal, currency: Currency) throws -> SaleCalculation {
        var lineCalculations: [SaleLineCalculation] = []

        lineCalculations.reserveCapacity(lines.count)

        for line in lines {
            guard line.unitPrice.currency == currency else {
                throw SaleCalculatorError.incompatibleCurrency(expected: currency, actual: line.unitPrice.currency)
            }

            let subtotalAmount = try line.unitPrice.amount.multipliedExactly(by: Decimal(line.quantity))
            let lineSubtotal = try Money(amount: subtotalAmount, currency: currency)
            let lineDiscount = try discountAmount(for: lineSubtotal, percentage: line.discount?.percentage ?? .zero)
            let residual = try Money(
                amount: lineSubtotal.amount.subtractingExactly(lineDiscount.amount),
                currency: currency
            )
            let globalDiscount = try discountAmount(for: residual, percentage: globalPercentage)
            let lineTotal = try Money(
                amount: residual.amount.subtractingExactly(globalDiscount.amount),
                currency: currency
            )
            let lineTaxableBase = try taxableBase(for: lineTotal, percentage: line.taxRate.percentage)
            let lineTax = try Money(
                amount: lineTotal.amount.subtractingExactly(lineTaxableBase.amount),
                currency: currency
            )

            lineCalculations.append(
                try SaleLineCalculation(
                    id: line.id,
                    subtotal: lineSubtotal,
                    lineDiscountAmount: lineDiscount,
                    globalDiscountAmount: globalDiscount,
                    taxableBase: lineTaxableBase,
                    taxAmount: lineTax,
                    total: lineTotal
                )
            )
        }

        return try SaleCalculation(lineCalculations: lineCalculations, currency: currency)
    }

    /// Certifies discount rounding after exact percentage scaling.
    ///
    /// Foundation's directed candidates must round to the same minor-unit amount,
    /// and an independent coefficient product must prove that rounded result.
    /// This includes negative historical prices and avoids overflowing an unscaled product.
    /// - Throws: `MoneyError.invalidAmount` for arithmetic failure or ambiguous rounding.
    func discountAmount(for subtotal: Money, percentage: Decimal) throws -> Money {
        var scaledSubtotal = try subtotal.amount.scaledExactly(powerOfTen: -2)
        var percentage = percentage
        var lowerBound = Decimal()
        var upperBound = Decimal()
        let lowerStatus = NSDecimalMultiply(
            &lowerBound,
            &scaledSubtotal,
            &percentage,
            .down
        )
        let upperStatus = NSDecimalMultiply(
            &upperBound,
            &scaledSubtotal,
            &percentage,
            .up
        )

        guard lowerStatus == .noError || lowerStatus == .lossOfPrecision,
              upperStatus == .noError || upperStatus == .lossOfPrecision,
              !lowerBound.isNaN,
              !upperBound.isNaN else {
            throw MoneyError.invalidAmount
        }

        let lowerAmount = try Money(amount: lowerBound, currency: subtotal.currency)
        let upperAmount = try Money(amount: upperBound, currency: subtotal.currency)
        guard lowerAmount == upperAmount else { throw MoneyError.invalidAmount }

        let exactProduct = try SaleDecimalCertificate.product(scaledSubtotal, percentage)
        let roundedProduct = try exactProduct.roundedToMinorUnits(currency: subtotal.currency)
        guard try roundedProduct.matches(lowerAmount.amount) else { throw MoneyError.invalidAmount }

        return lowerAmount
    }

    /// Extracts included tax only when the taxable base's monetary rounding is proven.
    ///
    /// An exact quotient is established by an exact product reproducing the total.
    /// Otherwise the total must lie within the rounded candidate's interval multiplied
    /// by the positive tax factor. Half-cent ties follow `Money`'s `.plain` rounding:
    /// the positive interval includes its lower edge, the negative interval includes
    /// its upper edge, and the zero interval excludes both edges.
    /// - Throws: `MoneyError.invalidAmount` when the factor, interval edges or their
    ///   products are inexact, division fails, or rounding cannot be certified.
    func taxableBase(for total: Money, percentage: Decimal) throws -> Money {
        guard total.amount != .zero else { return total }

        var factor = try Decimal(1).addingExactly(percentage.scaledExactly(powerOfTen: -2))
        guard factor > .zero else { throw MoneyError.invalidAmount }

        var totalAmount = total.amount
        var quotient = Decimal()
        let divisionStatus = NSDecimalDivide(
            &quotient,
            &totalAmount,
            &factor,
            .plain
        )
        guard divisionStatus == .noError || divisionStatus == .lossOfPrecision,
              !quotient.isNaN else {
            throw MoneyError.invalidAmount
        }

        let candidate = try Money(amount: quotient, currency: total.currency)
        var reproducedTotal = Decimal()
        let productStatus = NSDecimalMultiply(
            &reproducedTotal,
            &quotient,
            &factor,
            .plain
        )
        if productStatus == .noError,
           !reproducedTotal.isNaN,
           reproducedTotal == total.amount,
           try SaleDecimalCertificate.product(quotient, factor).matches(reproducedTotal) {
            return candidate
        }

        let halfMinorUnit: Decimal
        switch total.currency {
        case .eur, .usd:
            halfMinorUnit = Decimal(sign: .plus, exponent: -3, significand: 5)
        }

        let lowerEdge = try candidate.amount.subtractingExactly(halfMinorUnit).multipliedExactly(by: factor)
        let upperEdge = try candidate.amount.addingExactly(halfMinorUnit).multipliedExactly(by: factor)
        let includesLowerEdge = candidate.amount > .zero
        let includesUpperEdge = candidate.amount < .zero
        guard total.amount > lowerEdge || (includesLowerEdge && total.amount == lowerEdge),
              total.amount < upperEdge || (includesUpperEdge && total.amount == upperEdge) else {
            throw MoneyError.invalidAmount
        }

        return candidate
    }
}

/// Exact arithmetic primitives confined to the sale policy; none may silently round a monetary identity.
private extension Decimal {
    func addingExactly(_ other: Decimal) throws -> Decimal {
        var left = self
        var right = other
        var result = Decimal()
        let status = NSDecimalAdd(
            &result,
            &left,
            &right,
            .plain
        )
        guard status == .noError, !result.isNaN else { throw MoneyError.invalidAmount }
        guard try SaleDecimalCertificate.addition(self, other).matches(result) else { throw MoneyError.invalidAmount }

        return result
    }

    func subtractingExactly(_ other: Decimal) throws -> Decimal {
        var left = self
        var right = other
        var result = Decimal()
        let status = NSDecimalSubtract(
            &result,
            &left,
            &right,
            .plain
        )
        guard status == .noError, !result.isNaN else { throw MoneyError.invalidAmount }
        guard try SaleDecimalCertificate.subtraction(self, other).matches(result) else {
            throw MoneyError.invalidAmount
        }

        return result
    }

    func multipliedExactly(by other: Decimal) throws -> Decimal {
        var left = self
        var right = other
        var result = Decimal()
        let status = NSDecimalMultiply(
            &result,
            &left,
            &right,
            .plain
        )
        guard status == .noError, !result.isNaN else { throw MoneyError.invalidAmount }
        guard try SaleDecimalCertificate.product(self, other).matches(result) else { throw MoneyError.invalidAmount }

        return result
    }

    func scaledExactly(powerOfTen: Int16) throws -> Decimal {
        var source = self
        var result = Decimal()
        let status = NSDecimalMultiplyByPowerOf10(
            &result,
            &source,
            powerOfTen,
            .plain
        )
        guard status == .noError, !result.isNaN else { throw MoneyError.invalidAmount }
        let certificate = try SaleDecimalCertificate(self).scaled(powerOfTen: powerOfTen)
        guard try certificate.matches(result) else { throw MoneyError.invalidAmount }

        return result
    }
}

/// A bounded certificate of the sale policy's decimal coefficients, independent of Foundation arithmetic.
///
/// Two 128-bit coefficients have an exact product of at most 256 bits. The fixed
/// pair certifies products, aligned sums and monetary rounding; it never replaces
/// `Decimal` or exposes a general arithmetic API. Normalization removes decimal
/// trailing zeros and gives zero a canonical sign and exponent. The normalized
/// exponent is not restricted to the original Decimal storage's exponent range.
private struct SaleDecimalCertificate: Equatable {
    private var high: UInt128
    private var low: UInt128
    private var exponent: Int
    private var sign: FloatingPointSign
}

private extension SaleDecimalCertificate {
    /// Reads only public Decimal components, preserving every coefficient digit.
    /// - Throws: `MoneyError.invalidAmount` for NaN or an unreadable 128-bit coefficient.
    init(_ amount: Decimal) throws {
        guard !amount.isNaN else { throw MoneyError.invalidAmount }

        var significand = amount.significand
        let coefficientText = NSDecimalString(&significand, Locale(identifier: "en_US_POSIX"))
        guard let coefficient = UInt128(coefficientText) else { throw MoneyError.invalidAmount }

        self.init(
            normalizingHigh: 0,
            low: coefficient,
            exponent: amount.exponent,
            sign: amount.sign
        )
    }

    init(
        normalizingHigh: UInt128,
        low: UInt128,
        exponent: Int,
        sign: FloatingPointSign
    ) {
        self.init(
            high: normalizingHigh,
            low: low,
            exponent: exponent,
            sign: sign
        )
        normalize()
    }

    /// Certifies the complete coefficient product without dropping any digits.
    static func product(_ left: Decimal, _ right: Decimal) throws -> Self {
        let left = try Self(left)
        let right = try Self(right)
        let product = left.low.multipliedFullWidth(by: right.low)

        return Self(
            normalizingHigh: product.high,
            low: product.low,
            exponent: left.exponent + right.exponent,
            sign: left.sign == right.sign ? .plus : .minus
        )
    }

    static func addition(_ left: Decimal, _ right: Decimal) throws -> Self {
        try Self(left).combined(with: Self(right))
    }

    static func subtraction(_ left: Decimal, _ right: Decimal) throws -> Self {
        var right = try Self(right)
        right.sign = right.sign == .plus ? .minus : .plus

        return try Self(left).combined(with: right)
    }

    func scaled(powerOfTen: Int16) -> Self {
        Self(
            normalizingHigh: high,
            low: low,
            exponent: exponent + Int(powerOfTen),
            sign: sign
        )
    }

    func matches(_ amount: Decimal) throws -> Bool {
        try self == Self(amount)
    }

    /// Rounds the exact coefficient product with Money's half-away-from-zero rule.
    ///
    /// The last remainder is the first discarded decimal digit. Lower discarded
    /// digits cannot change `.plain` rounding; both signs increase magnitude at five.
    /// - Throws: `MoneyError.invalidAmount` if the checked fixed-width increment fails.
    func roundedToMinorUnits(currency: Currency) throws -> Self {
        let minorUnitExponent: Int
        switch currency {
        case .eur, .usd:
            minorUnitExponent = -2
        }

        var rounded = self
        var lastRemainder: UInt128 = 0
        while rounded.exponent < minorUnitExponent {
            lastRemainder = rounded.divideMagnitudeByTen()
            rounded.exponent += 1
        }

        if lastRemainder >= 5 {
            let lowIncrement = rounded.low.addingReportingOverflow(1)
            let highIncrement = rounded.high.addingReportingOverflow(lowIncrement.overflow ? 1 : 0)
            guard !highIncrement.overflow else { throw MoneyError.invalidAmount }

            rounded.low = lowIncrement.partialValue
            rounded.high = highIncrement.partialValue
        }

        rounded.normalize()
        return rounded
    }

    /// Aligns finite coefficients and combines signs without accepting carry or borrow loss.
    ///
    /// If alignment exceeds 256 bits, the other coefficient of at most 128 bits
    /// cannot cancel enough magnitude to produce an exact Decimal coefficient.
    /// Its normalized last digit also prevents removing trailing decimal zeros.
    /// - Throws: `MoneyError.invalidAmount` when alignment or checked combination overflows.
    func combined(with other: Self) throws -> Self {
        guard high != 0 || low != 0 else { return other.normalized() }
        guard other.high != 0 || other.low != 0 else { return self }

        let commonExponent = min(exponent, other.exponent)
        let left = try aligned(to: commonExponent)
        let right = try other.aligned(to: commonExponent)

        if left.sign == right.sign {
            let lowSum = left.low.addingReportingOverflow(right.low)
            let highSum = left.high.addingReportingOverflow(right.high)
            let highWithCarry = highSum.partialValue.addingReportingOverflow(lowSum.overflow ? 1 : 0)
            guard !highSum.overflow, !highWithCarry.overflow else { throw MoneyError.invalidAmount }

            return Self(
                normalizingHigh: highWithCarry.partialValue,
                low: lowSum.partialValue,
                exponent: commonExponent,
                sign: left.sign
            )
        }

        let leftIsLarger = left.high > right.high || (left.high == right.high && left.low >= right.low)
        let larger = leftIsLarger ? left : right
        let smaller = leftIsLarger ? right : left
        let lowDifference = larger.low.subtractingReportingOverflow(smaller.low)
        let highDifference = larger.high.subtractingReportingOverflow(smaller.high)
        let highWithBorrow = highDifference.partialValue.subtractingReportingOverflow(lowDifference.overflow ? 1 : 0)
        guard !highDifference.overflow, !highWithBorrow.overflow else { throw MoneyError.invalidAmount }

        return Self(
            normalizingHigh: highWithBorrow.partialValue,
            low: lowDifference.partialValue,
            exponent: commonExponent,
            sign: larger.sign
        )
    }

    func aligned(to targetExponent: Int) throws -> Self {
        var aligned = self
        while aligned.exponent > targetExponent {
            let lowProduct = aligned.low.multipliedFullWidth(by: 10)
            let highProduct = aligned.high.multipliedReportingOverflow(by: 10)
            let highWithCarry = highProduct.partialValue.addingReportingOverflow(lowProduct.high)
            guard !highProduct.overflow, !highWithCarry.overflow else { throw MoneyError.invalidAmount }

            aligned.low = lowProduct.low
            aligned.high = highWithCarry.partialValue
            aligned.exponent -= 1
        }

        return aligned
    }

    mutating func divideMagnitudeByTen() -> UInt128 {
        let highDivision = high.quotientAndRemainder(dividingBy: 10)
        let lowDivision = UInt128(10).dividingFullWidth((high: highDivision.remainder, low: low))
        high = highDivision.quotient
        low = lowDivision.quotient

        return lowDivision.remainder
    }

    func normalized() -> Self {
        var normalized = self
        normalized.normalize()
        return normalized
    }

    mutating func normalize() {
        guard high != 0 || low != 0 else {
            exponent = 0
            sign = .plus
            return
        }

        while true {
            var divided = self
            guard divided.divideMagnitudeByTen() == 0 else { return }

            high = divided.high
            low = divided.low
            exponent += 1
        }
    }
}
