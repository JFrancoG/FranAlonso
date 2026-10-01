import Foundation
import Testing
@testable import FranAlonso

struct ServiceDraftExtractionTests {
    @Test
    func `Spanish description proposes only the evidenced name and price`() throws {
        let output = ServiceDraftExtractionDTO(name: "corte y peinado", priceEvidence: "precio 35 euros")

        let proposal = try output.toDomain(
            source: "Servicio profesional de corte y peinado, precio 35 euros",
            locale: Locale(identifier: "es_ES")
        )

        #expect(proposal.name == "corte y peinado")
        #expect(proposal.price?.amount == 35)
        #expect(proposal.price?.currency == .eur)
        #expect(proposal.taxRate == nil)
        #expect(proposal.discount == nil)
    }

    @Test
    func `English evidence preserves exact currency and distinct percentages`() throws {
        let output = ServiceDraftExtractionDTO(
            name: "haircut and styling",
            priceEvidence: "price 35.25 USD",
            taxEvidence: "tax 10%",
            discountEvidence: "discount 5%"
        )

        let proposal = try output.toDomain(
            source: "Professional haircut and styling, price 35.25 USD, tax 10%, discount 5%",
            locale: Locale(identifier: "en_US")
        )

        #expect(proposal.name == "haircut and styling")
        #expect(proposal.price?.amount == Decimal(string: "35.25"))
        #expect(proposal.price?.currency == .usd)
        #expect(proposal.taxRate?.percentage == 10)
        #expect(proposal.discount?.percentage == 5)
    }

    @Test
    func `name only input leaves all commercial fields unproposed`() throws {
        let output = ServiceDraftExtractionDTO(name: "Corte")
        let proposal = try output.toDomain(source: "Corte", locale: Locale(identifier: "es_ES"))

        #expect(proposal.price == nil)
        #expect(proposal.taxRate == nil)
        #expect(proposal.discount == nil)
    }

    @Test
    func `explicit zero tax and discount remain proposed values`() throws {
        let output = ServiceDraftExtractionDTO(
            priceEvidence: "precio: 0 EUR",
            taxEvidence: "IVA 0%",
            discountEvidence: "descuento 0%"
        )
        let proposal = try output.toDomain(
            source: "Corte, precio: 0 EUR, IVA 0%, descuento 0%",
            locale: Locale(identifier: "es_ES")
        )

        #expect(proposal.name == nil)
        #expect(proposal.price?.amount == 0)
        #expect(proposal.taxRate?.percentage == 0)
        #expect(proposal.discount?.percentage == 0)
    }

    @Test(arguments: [
        ("es_ES", "precio 12,30 €", "12.30"),
        ("en_US", "price: 12.30 EUR", "12.30"),
        ("es_ES", "precio 0012,3000 euros", "12.30")
    ])
    func `localized price evidence preserves cents without implicit rounding`(
        localeID: String,
        evidence: String,
        expected: String
    ) throws {
        let output = ServiceDraftExtractionDTO(priceEvidence: evidence)
        let proposal = try output.toDomain(source: evidence, locale: Locale(identifier: localeID))

        #expect(proposal.price?.amount == Decimal(string: expected))
        #expect(proposal.price?.currency == .eur)
    }

    @Test(arguments: [
        ("es_ES", "precio 10,005 EUR"), ("en_US", "price 10.005 USD"),
        ("es_ES", "precio -1 EUR"), ("en_US", "price -0.001 EUR"),
        ("es_ES", "precio 1.000,00 EUR"), ("en_US", "price 1,000.00 USD"),
        ("es_ES", "precio 1e2 EUR"), ("en_US", "price 1E2 USD"),
        ("es_ES", "precio 10 EUR resto"), ("en_US", "price 12. USD"),
        ("es_ES", "precio 35"), ("en_US", "price 35 dollars"),
        ("es_ES", "precio 35 GBP"), ("en_US", "price NaN EUR"),
        ("es_ES", "precio 1 2 EUR"), ("en_US", "price +12 USD"),
        ("es_ES", "precio 12.30 EUR"), ("en_US", "price 12,30 EUR"),
        ("en_US", "price 123456789012345678901234567890123456789 USD")
    ])
    func `invalid or lossy price evidence requires clarification`(localeID: String, evidence: String) {
        let output = ServiceDraftExtractionDTO(priceEvidence: evidence)

        #expect(throws: ServiceDraftAssistantError.clarification) {
            try output.toDomain(source: evidence, locale: Locale(identifier: localeID))
        }
    }

    @Test(arguments: [
        "IVA -1%", "IVA 100,001%", "IVA 10", "IVA 1e2%", "descuento 10%", "precio 10 EUR"
    ])
    func `tax requires its own explicit label unit and valid range`(evidence: String) {
        let output = ServiceDraftExtractionDTO(taxEvidence: evidence)

        #expect(throws: ServiceDraftAssistantError.clarification) {
            try output.toDomain(source: evidence, locale: Locale(identifier: "es_ES"))
        }
    }

    @Test(arguments: [
        "discount -1%", "discount 101%", "discount 10", "discount 1E2%", "tax 10%", "price 10 USD"
    ])
    func `discount cannot use a tax or price number`(evidence: String) {
        let output = ServiceDraftExtractionDTO(discountEvidence: evidence)

        #expect(throws: ServiceDraftAssistantError.clarification) {
            try output.toDomain(source: evidence, locale: Locale(identifier: "en_US"))
        }
    }

    @Test(arguments: ["35 EUR", "IVA 21%", "precio 21 EUR"])
    func `a number elsewhere in the source cannot justify a price`(evidence: String) {
        let output = ServiceDraftExtractionDTO(priceEvidence: evidence)

        #expect(throws: ServiceDraftAssistantError.clarification) {
            try output.toDomain(source: "Corte, precio 35 EUR, IVA 21%", locale: Locale(identifier: "es_ES"))
        }
    }

    @Test(arguments: [
        ("sobreprecio 35 EUR", "precio 35 EUR"),
        ("precio 35 EURXYZ", "precio 35 EUR"),
        ("precio 35 EUR0", "precio 35 EUR"),
        ("precio 135 EUR", "precio 35 EUR"),
        ("precio 35 EUR", "precio 99 EUR")
    ])
    func `literal evidence cannot be invented or cut from another token`(source: String, evidence: String) {
        let output = ServiceDraftExtractionDTO(priceEvidence: evidence)

        #expect(throws: ServiceDraftAssistantError.clarification) {
            try output.toDomain(source: source, locale: Locale(identifier: "es_ES"))
        }
    }

    @Test(arguments: ["Corte inventado", " ", "Recorte"])
    func `unjustified names reject the proposal instead of keeping plausible numeric fields`(name: String) {
        let output = ServiceDraftExtractionDTO(name: name, priceEvidence: "precio 35 EUR")

        #expect(throws: ServiceDraftAssistantError.clarification) {
            try output.toDomain(source: "Corte, precio 35 EUR", locale: Locale(identifier: "es_ES"))
        }
    }

    @Test
    func `empty proposal does not create an approximate service`() {
        let output = ServiceDraftExtractionDTO()

        #expect(throws: ServiceDraftAssistantError.clarification) {
            try output.toDomain(source: "un servicio", locale: Locale(identifier: "es_ES"))
        }
    }

    @Test
    func `oversized description is rejected before contacting the real model`() async {
        let interpreter = FoundationModelsServiceDraftInterpreter()

        await #expect(throws: ServiceDraftAssistantError.inputTooLong) {
            try await interpreter.interpret(String(repeating: "a", count: 1001), locale: Locale(identifier: "es_ES"))
        }
    }

    @Test(arguments: [
        #"{}"#,
        #"{"name":"  "}"#,
        #"{"price":{"amount":-1,"currency":"EUR"}}"#
    ])
    func `decoded proposals cannot bypass nonempty and nonnegative invariants`(json: String) {
        #expect(throws: ServiceDraftAssistantError.clarification) {
            try JSONDecoder().decode(ServiceDraftProposal.self, from: Data(json.utf8))
        }
    }
}
