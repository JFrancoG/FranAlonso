import Foundation

extension ClientFormFields {
    /// Provides a long synthetic profile for layout previews without inserting another persisted client.
    static var longPreview: ClientFormFields {
        var fields = ClientFormFields(AppPreviewFixtures.standard.secondaryClient)
        fields.taxIdentifier = "IDENTIFICADOR-DE-EJEMPLO"
        fields.streetLine = "Avenida de los Ejemplos, número 123, edificio de demostración, segunda planta"
        fields.postalCode = "12345"
        fields.city = "Localidad de demostración con nombre largo"
        fields.province = "Provincia de ejemplo"
        return fields
    }
}

/// Owns deterministic form destinations and layout values shared by previews.
struct ClientFormPreviewFixtures {
    let creating: ClientFormDestination
    let editing: ClientFormDestination

    static let standard = ClientFormPreviewFixtures(
        creating: ClientFormDestination(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000801")!,
            clientID: ClientID(rawValue: UUID(uuidString: "00000000-0000-0000-0000-000000000802")!),
            mode: .create
        ),
        editing: ClientFormDestination(
            id: UUID(uuidString: "00000000-0000-0000-0000-000000000803")!,
            clientID: AppPreviewFixtures.standard.secondaryClient.id,
            mode: .edit
        )
    )

}
