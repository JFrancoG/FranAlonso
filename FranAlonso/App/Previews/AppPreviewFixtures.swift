import Foundation
import SwiftData

/// Deterministic sample values shared by application previews.
struct AppPreviewFixtures {
    let primaryClient: Client
    let secondaryClient: Client

    var clients: [Client] {
        [primaryClient, secondaryClient]
    }

    /// Seeds the caller's context through the same idempotent local write primitive as the app.
    func seed(in context: ModelContext) throws {
        let dataSource = ClientLocalDataSource()

        for client in clients {
            try dataSource.upsert(client, in: context)
        }
    }
}

extension AppPreviewFixtures {
    /// The deterministic fixture set used by every application preview.
    static let standard = AppPreviewFixtures(
        primaryClient: Client.draft(
            id: ClientID(
                rawValue: UUID(
                    uuid: (
                        0xAA, 0xAA, 0xAA, 0xAA,
                        0xBB, 0xBB,
                        0xCC, 0xCC,
                        0xDD, 0xDD,
                        0xEE, 0xEE, 0xEE, 0xEE, 0xEE, 0xEE
                    )
                )
            ),
            displayName: "Ana Alonso"
        ),
        secondaryClient: Client.draft(
            id: ClientID(
                rawValue: UUID(
                    uuid: (
                        0x11, 0x11, 0x11, 0x11,
                        0x22, 0x22,
                        0x33, 0x33,
                        0x44, 0x44,
                        0x55, 0x55, 0x55, 0x55, 0x55, 0x55
                    )
                )
            ),
            displayName: "María de los Ángeles Fernández"
        )
    )
}
