import Testing
@testable import FranAlonso

@Suite("Client form profile preparation")
struct PrepareClientProfileUseCaseTests {
    @Test
    func `blank optional fields become absent without requiring an address`() throws {
        let profile = try PrepareClientProfileUseCase()(
            displayName: "  Ana Alonso\n",
            taxIdentifier: " \n",
            streetLine: " ",
            postalCode: "\n",
            city: "",
            province: " "
        )

        #expect(profile.displayName == "Ana Alonso")
        #expect(profile.taxIdentifier == nil)
        #expect(profile.billingAddress == nil)
    }

    @Test
    func `partial addresses and nonstandard fiscal identifiers remain editable`() throws {
        let profile = try PrepareClientProfileUseCase()(
            displayName: "Ana",
            taxIdentifier: "  SYNTHETIC-ID  ",
            streetLine: "",
            postalCode: " ",
            city: "  Sevilla\n",
            province: ""
        )

        #expect(profile.taxIdentifier == "SYNTHETIC-ID")
        #expect(profile.billingAddress == BillingAddress(
            streetLine: "",
            postalCode: "",
            city: "Sevilla",
            province: ""
        ))
    }

    @Test(arguments: ["", "   ", "\n\t"])
    func `blank names cannot become a writable profile`(name: String) {
        #expect(throws: ClientError.invalidDisplayName) {
            try PrepareClientProfileUseCase()(
                displayName: name,
                taxIdentifier: "",
                streetLine: "",
                postalCode: "",
                city: "",
                province: ""
            )
        }
    }
}
