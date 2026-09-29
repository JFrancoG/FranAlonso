import Foundation

/// Editable text retains incomplete input until the user submits a complete commercial profile.
struct ServiceFormDraft: Equatable {
    var name = ""
    var type: ServiceType = .professional
    var linkedProductID: ProductID? = nil
    var priceText = ""
    var currency: Currency = .eur
    var taxText = ""
    var discountText = ""

    /// Prepares a validated Domain profile using the locale captured for this form session.
    /// Empty discount text means absence; a numeric zero is an explicit zero discount.
    func prepareProfile(locale: Locale) throws -> ServiceProfile {
        let input = ServiceDecimalInput(locale: locale)
        guard let amount = input.parse(priceText) else { throw ServiceFormError.invalidPriceInput }
        let price: Money
        do {
            price = try Money(amount: amount, currency: currency)
        } catch MoneyError.invalidAmount {
            throw ServiceFormError.invalidPriceInput
        }

        guard let percentage = input.parse(taxText) else { throw ServiceFormError.invalidTaxInput }
        let taxRate: TaxRate
        do {
            taxRate = try TaxRate(percentage: percentage)
        } catch TaxRateError.outOfRange {
            throw ServiceFormError.invalidTaxInput
        }

        let discount: Discount?
        if discountText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            discount = nil
        } else {
            guard let percentage = input.parse(discountText) else { throw ServiceFormError.invalidDiscountInput }
            do {
                discount = try Discount(percentage: percentage)
            } catch DiscountError.outOfRange {
                throw ServiceFormError.invalidDiscountInput
            }
        }

        do {
            return try PrepareServiceProfileUseCase()(
                name: name,
                type: type,
                linkedProductID: linkedProductID,
                price: price,
                taxRate: taxRate,
                discount: discount
            )
        } catch let error as ServiceError {
            throw ServiceFormError.service(error)
        }
    }
}

extension ServiceFormDraft {
    /// Loads commercial fields without querying the availability of a historical product link.
    init(service: Service, locale: Locale) {
        let input = ServiceDecimalInput(locale: locale)
        self.init(
            name: service.name,
            type: service.type,
            linkedProductID: service.linkedProductID,
            priceText: input.format(service.price.amount),
            currency: service.price.currency,
            taxText: input.format(service.taxRate.percentage),
            discountText: service.discount.map { input.format($0.percentage) } ?? ""
        )
    }
}
