#if DEBUG
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Shared application preview modifier")
@MainActor
struct AppPreviewModifierTests {
    private let dataSource = ClientLocalDataSource()

    @Test("Shared context provides the same navigable clients to SwiftData and dependencies")
    func sharedContextProvidesTheSameNavigableClientsToSwiftDataAndDependencies() async throws {
        let context = try AppPreviewModifier.makeSharedContext()
        let persistedClients = try dataSource.fetchAll(
            in: ModelContext(context.modelContainer)
        )
        let stream = await context.dependencies.observeClients()
        var iterator = stream.makeAsyncIterator()

        #expect(persistedClients == AppPreviewFixtures.standard.clients)
        #expect(try await iterator.next() == AppPreviewFixtures.standard.clients)
        #expect(try await iterator.next() == nil)
    }

    @Test("Seeding the cached preview context repeatedly does not duplicate clients")
    func seedingTheCachedPreviewContextRepeatedlyDoesNotDuplicateClients() throws {
        let context = try AppPreviewModifier.makeSharedContext()

        try AppPreviewFixtures.standard.seed(in: context.modelContainer.mainContext)
        try AppPreviewFixtures.standard.seed(in: context.modelContainer.mainContext)

        let verificationContext = ModelContext(context.modelContainer)
        #expect(
            try verificationContext.fetchCount(FetchDescriptor<ClientModel>())
                == AppPreviewFixtures.standard.clients.count
        )
        #expect(
            try dataSource.fetchAll(in: verificationContext)
                == AppPreviewFixtures.standard.clients
        )
    }
}
#endif
