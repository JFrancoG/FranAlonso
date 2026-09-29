import Foundation
import Testing
@testable import FranAlonso

struct ServiceFormDraftTests {
    @Test(arguments: [
        ("es_ES", " 00012,34500\n", "12.35", "21,125", "21.125", "05,50", "5.5"),
        ("en_US", "\n00012.34500 ", "12.35", "21.125", "21.125", "05.50", "5.5"),
        ("es_ES", "-0,004", "0", "-0,00", "0", "100,000", "100"),
        ("en_US", "0.005", "0.01", "100.0", "100", "0.000", "0")
    ])
    func `localized fields form exact commercial values before domain rounding`(
        localeID: String,
        price: String,
        expectedPrice: String,
        tax: String,
        expectedTax: String,
        discount: String,
        expectedDiscount: String
    ) throws {
        var draft = validDraft()
        draft.name = "  Sesión comercial\n"
        draft.priceText = price
        draft.taxText = tax
        draft.discountText = discount
        draft.currency = .usd

        let profile = try draft.prepareProfile(locale: Locale(identifier: localeID))

        #expect(profile.name == "Sesión comercial")
        #expect(profile.price.amount == decimal(expectedPrice))
        #expect(profile.price.currency == .usd)
        #expect(profile.taxRate.percentage == decimal(expectedTax))
        #expect(profile.discount?.percentage == decimal(expectedDiscount))
    }

    @Test(arguments: [
        ("es_ES", ""), ("es_ES", " "), ("es_ES", "12.5"), ("es_ES", "1.234,50"),
        ("es_ES", "12,5resto"), ("es_ES", "12,"), ("es_ES", ",5"), ("es_ES", "1 2"),
        ("es_ES", "+12"), ("es_ES", "--12"), ("es_ES", "1e2"), ("es_ES", "12 €"),
        ("es_ES", "NaN"), ("es_ES", "∞"), ("es_ES", "١٢"), ("es_ES", "−12"),
        ("en_US", "12,5"), ("en_US", "1,234.50"), ("en_US", "12.5garbage"), ("en_US", "12."),
        ("en_US", ".5"), ("en_US", "-"), ("en_US", "1E2"), ("en_US", "12%")
    ])
    func `price rejects partial input separators and non decimal grammar`(localeID: String, input: String) {
        var draft = validDraft()
        draft.priceText = input

        #expect(throws: ServiceFormError.invalidPriceInput) {
            try draft.prepareProfile(locale: Locale(identifier: localeID))
        }
    }

    @Test(arguments: [
        "123456789012345678901234567890123456789",
        String(repeating: "9", count: 200),
        "0." + String(repeating: "0", count: 200) + "1"
    ])
    func `price rejects precision loss overflow and underflow`(input: String) {
        var draft = validDraft()
        draft.priceText = input

        #expect(throws: ServiceFormError.invalidPriceInput) {
            try draft.prepareProfile(locale: Locale(identifier: "en_US"))
        }
    }

    @Test(arguments: ["", "21%", "12.5trailing", "100.0001", "-0.001", "NaN"])
    func `tax syntax and range failures identify the tax field`(input: String) {
        var draft = validDraft()
        draft.taxText = input

        #expect(throws: ServiceFormError.invalidTaxInput) {
            try draft.prepareProfile(locale: Locale(identifier: "en_US"))
        }
    }

    @Test(arguments: ["12%", "2.5trailing", "100.0001", "-0.001", "NaN"])
    func `discount syntax and range failures identify the discount field`(input: String) {
        var draft = validDraft()
        draft.discountText = input

        #expect(throws: ServiceFormError.invalidDiscountInput) {
            try draft.prepareProfile(locale: Locale(identifier: "en_US"))
        }
    }

    @Test
    func `blank discount is absent while zero remains explicit`() throws {
        var draft = validDraft()
        draft.discountText = " \n "
        let absent = try draft.prepareProfile(locale: Locale(identifier: "en_US"))
        #expect(absent.discount == nil)

        draft.discountText = "0"
        let zero = try draft.prepareProfile(locale: Locale(identifier: "en_US"))
        #expect(zero.discount?.percentage == 0)
    }

    @Test
    func `commercial validation preserves domain errors without removing a product link`() {
        let locale = Locale(identifier: "en_US")
        var draft = validDraft()
        draft.name = " \n "
        #expect(throws: ServiceFormError.service(.invalidName)) {
            try draft.prepareProfile(locale: locale)
        }

        draft = validDraft()
        draft.priceText = "-0.005"
        #expect(throws: ServiceFormError.service(.invalidPrice)) {
            try draft.prepareProfile(locale: locale)
        }

        draft = validDraft()
        draft.type = .product
        #expect(throws: ServiceFormError.service(.linkedProductRequired)) {
            try draft.prepareProfile(locale: locale)
        }

        draft = validDraft()
        draft.linkedProductID = linkedID
        #expect(throws: ServiceFormError.service(.linkedProductNotAllowed)) {
            try draft.prepareProfile(locale: locale)
        }
    }

    @Test(arguments: ["es_ES", "en_US"])
    func `loading and saving preserves high precision percentages and historical product linkage`(
        localeID: String
    ) throws {
        let locale = Locale(identifier: localeID)
        let tax = try #require(decimal("21.123456789012345678901234567890123456"))
        let discount = try #require(decimal("0.12345678901234567890123456789012345678"))
        let service = try Service(
            id: ServiceID(rawValue: UUID()),
            name: "Producto histórico",
            type: .product,
            linkedProductID: linkedID,
            price: Money(amount: 87.65, currency: .usd),
            taxRate: TaxRate(percentage: tax),
            discount: Discount(percentage: discount),
            status: .inactive
        )

        let draft = ServiceFormDraft(service: service, locale: locale)
        let profile = try draft.prepareProfile(locale: locale)

        #expect(profile.name == "Producto histórico")
        #expect(profile.type == .product)
        #expect(profile.linkedProductID == linkedID)
        #expect(profile.price.amount == decimal("87.65"))
        #expect(profile.price.currency == .usd)
        #expect(profile.taxRate.percentage == tax)
        #expect(profile.discount?.percentage == discount)
        let separator = localeID == "es_ES" ? "," : "."
        #expect(draft.priceText == "87" + separator + "65")
        #expect(draft.taxText == "21" + separator + "123456789012345678901234567890123456")
        #expect(draft.discountText == "0" + separator + "12345678901234567890123456789012345678")
    }

    @Test(arguments: ["es_ES", "en_US"])
    func `loading without discount keeps absence on subsequent save`(localeID: String) throws {
        let service = try Service(
            id: ServiceID(rawValue: UUID()),
            name: "Servicio",
            type: .professional,
            price: Money(amount: 10, currency: .eur),
            taxRate: TaxRate(percentage: 0),
            discount: nil,
            status: .active
        )

        let locale = Locale(identifier: localeID)
        let profile = try ServiceFormDraft(service: service, locale: locale).prepareProfile(locale: locale)

        #expect(profile.discount == nil)
        #expect(profile.taxRate.percentage == 0)
    }

    private var linkedID: ProductID {
        ProductID(rawValue: UUID(uuid: (0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 4)))
    }

    private func validDraft() -> ServiceFormDraft {
        ServiceFormDraft(name: "Servicio", priceText: "10", taxText: "21")
    }

    private func decimal(_ string: String) -> Decimal? {
        Decimal(string: string, locale: Locale(identifier: "en_US_POSIX"))
    }
}
