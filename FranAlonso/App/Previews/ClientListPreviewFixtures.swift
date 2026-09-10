import Foundation

extension AppPreviewFixtures {
    /// Pure snapshots never seed the shared preview container with competing list scenarios.
    static let clientListEighty = (1...80).map { index in
        Client.draft(
            id: ClientID(
                rawValue: UUID(
                    uuid: (
                        0x08, 0x03, 0, 0,
                        0, 0,
                        0, 0,
                        0, 0,
                        0, 0, 0, 0, 0, UInt8(index)
                    )
                )
            ),
            displayName: "Cliente de muestra \(index)"
        )
    }

    static let clientListLongName = Client.draft(
        id: ClientID(
            rawValue: UUID(
                uuid: (
                    0x08, 0x03, 0, 0,
                    0, 0,
                    0, 0,
                    0, 0,
                    0, 0, 0, 0, 1, 0
                )
            )
        ),
        displayName: "María de los Ángeles Fernández de la Vega y Alonso"
    )
}
