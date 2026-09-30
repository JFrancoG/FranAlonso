#if FRANALONSO_AUTH_FIXTURE
import Foundation
import SwiftData

/// Synthetic draft profiles recreated for each isolated demo launch, with stable causal identities.
struct DevelopDemoScenario {
    private struct Profile {
        let id: ClientID
        let operationID: UUID
        let displayName: String
    }

    private let profiles: [Profile]

    static let clients = DevelopDemoScenario(profiles: [
        Profile(
            id: ClientID(rawValue: UUID(uuid: (0x08, 0x8A, 0, 0, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, 1))),
            operationID: UUID(uuid: (0x08, 0x8A, 0, 0, 0, 0, 0x40, 0, 0x90, 0, 0, 0, 0, 0, 0, 1)),
            displayName: "Cliente DEMO Alba"
        ),
        Profile(
            id: ClientID(rawValue: UUID(uuid: (0x08, 0x8A, 0, 0, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, 2))),
            operationID: UUID(uuid: (0x08, 0x8A, 0, 0, 0, 0, 0x40, 0, 0x90, 0, 0, 0, 0, 0, 0, 2)),
            displayName: "Cliente DEMO Bruno"
        )
    ])

    /// Uses the normal validated draft creation boundary before actors or observers receive the container.
    /// The caller must discard the unpublished container if any write fails; no partial scenario is exposed.
    @MainActor
    func seed(in container: ModelContainer) throws {
        let context = ModelContext(container)
        let dataSource = ClientLocalDataSource()
        for profile in profiles {
            _ = try dataSource.createClient(
                id: profile.id,
                profile: ClientProfile(displayName: profile.displayName),
                operationID: profile.operationID,
                in: context
            )
        }
    }
}
#endif
