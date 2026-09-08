import Foundation

/// Converts editable text into a writable client profile without adding fiscal or address requirements.
struct PrepareClientProfileUseCase {
    /// Trims fields, removes absent optional content and retains partially entered addresses.
    /// - Throws: `ClientError.invalidDisplayName` when the normalized name is empty.
    func callAsFunction(
        displayName: String,
        taxIdentifier: String,
        streetLine: String,
        postalCode: String,
        city: String,
        province: String
    ) throws -> ClientProfile {
        let fiscal = taxIdentifier.trimmingCharacters(in: .whitespacesAndNewlines)
        let address = BillingAddress(
            streetLine: streetLine.trimmingCharacters(in: .whitespacesAndNewlines),
            postalCode: postalCode.trimmingCharacters(in: .whitespacesAndNewlines),
            city: city.trimmingCharacters(in: .whitespacesAndNewlines),
            province: province.trimmingCharacters(in: .whitespacesAndNewlines)
        )
        let hasAddress = [address.streetLine, address.postalCode, address.city, address.province]
            .contains { !$0.isEmpty }
        return try ClientProfile(
            displayName: displayName,
            taxIdentifier: fiscal.isEmpty ? nil : fiscal,
            billingAddress: hasAddress ? address : nil
        )
    }
}
