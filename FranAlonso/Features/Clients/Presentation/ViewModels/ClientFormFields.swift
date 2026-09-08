/// Editable text owned by one form session; it becomes Domain only after profile preparation.
struct ClientFormFields: Equatable {
    var displayName = ""
    var taxIdentifier = ""
    var streetLine = ""
    var postalCode = ""
    var city = ""
    var province = ""
}

extension ClientFormFields {
    init(_ client: Client) {
        self.init(
            displayName: client.displayName,
            taxIdentifier: client.taxIdentifier ?? "",
            streetLine: client.billingAddress?.streetLine ?? "",
            postalCode: client.billingAddress?.postalCode ?? "",
            city: client.billingAddress?.city ?? "",
            province: client.billingAddress?.province ?? ""
        )
    }
}
