import Foundation
import Testing
@testable import FranAlonso

@Suite("Client")
struct ClientTests {
    @Test("Preserves stable identity through a Codable round trip")
    func preservesStableIdentityThroughCodableRoundTrip() throws {
        let client = Client(
            id: ClientID(
                rawValue: UUID(
                    uuidString: "AAAAAAAA-BBBB-CCCC-DDDD-EEEEEEEEEEEE"
                )!
            ),
            displayName: "Ana Alonso"
        )

        let data = try JSONEncoder().encode(client)
        let decodedClient = try JSONDecoder().decode(Client.self, from: data)

        #expect(decodedClient == client)
        #expect(identifiableID(of: decodedClient) == client.id)
    }

    private func identifiableID<Model: Identifiable>(of model: Model) -> Model.ID {
        model.id
    }
}
