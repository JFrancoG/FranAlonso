import Foundation
import Testing
@testable import FranAlonso

#if FRANALONSO_AUTH_FIXTURE
@Suite("Develop Clients error repository")
struct DevelopClientErrorRepositoryTests {
    @Test("Client observation fails immediately with unavailable")
    func observationFailsImmediately() async {
        let repository = DevelopClientErrorRepository()
        let stream = await repository.observeClients()
        var iterator = stream.makeAsyncIterator()

        await #expect(throws: DevelopClientErrorRepository.Failure.unavailable) {
            _ = try await iterator.next()
        }
    }

    @Test("Client saving fails with the same unavailable error")
    func savingFailsWithUnavailable() async {
        let repository = DevelopClientErrorRepository()
        let client = Client.draft(
            id: ClientID(
                rawValue: UUID(
                    uuidString: "ABCDEFAB-CDEF-ABCD-EFAB-CDEFABCDEFAB"
                )!
            ),
            displayName: "Fixture error"
        )

        await #expect(throws: DevelopClientErrorRepository.Failure.unavailable) {
            try await repository.saveClient(client)
        }
    }
}
#endif
