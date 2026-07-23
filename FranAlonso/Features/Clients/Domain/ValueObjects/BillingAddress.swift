/// A structured postal address captured for client billing.
struct BillingAddress: Codable, Equatable {
    let streetLine: String
    let postalCode: String
    let city: String
    let province: String
}
