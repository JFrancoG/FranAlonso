import SwiftData
import Testing
@testable import FranAlonso

@Suite("Application runtime")
@MainActor
struct AppRuntimeTests {
    @Test("Sync remains uncomposed until Firebase is configured")
    func syncRemainsUncomposedUntilFirebaseIsConfigured() throws {
        let factory = AppRuntimeRemoteFactory()
        let runtime = try makeAppRuntime(factory: factory)

        runtime.activateClientSync(firebaseIsConfigured: false)

        #expect(factory.environments.isEmpty)
        #expect(runtime.clientSyncEngine == nil)
    }

    @Test("Configured Firebase composes one inactive environment-specific engine")
    func configuredFirebaseComposesOneInactiveEnvironmentSpecificEngine() async throws {
        let remote = AppRuntimeRemoteFake()
        let factory = AppRuntimeRemoteFactory(remote: remote)
        let runtime = try makeAppRuntime(factory: factory)

        runtime.activateClientSync(firebaseIsConfigured: true)
        runtime.activateClientSync(firebaseIsConfigured: true)

        #expect(factory.environments == [.develop])
        #expect(runtime.clientSyncEngine != nil)
        #expect(await remote.fetchCount == 0)
        #expect(await remote.upsertCount == 0)
    }
}

@MainActor
private final class AppRuntimeRemoteFactory {
    private(set) var environments: [FirestoreEnvironment] = []
    private let remote: AppRuntimeRemoteFake

    init(remote: AppRuntimeRemoteFake = AppRuntimeRemoteFake()) {
        self.remote = remote
    }

    func make(environment: FirestoreEnvironment) -> any ClientRemoteDataSource {
        environments.append(environment)
        return remote
    }
}

private actor AppRuntimeRemoteFake: ClientRemoteDataSource {
    private var fetchCalls = 0
    private var upsertCalls = 0

    var fetchCount: Int { fetchCalls }
    var upsertCount: Int { upsertCalls }

    func fetchAll() async throws -> [ClientRemoteRecord] {
        fetchCalls += 1
        return []
    }

    func upsert(
        _ operation: ClientPendingUpsert
    ) async throws -> ClientRemoteUpsertResult {
        upsertCalls += 1
        return .applied(
            ClientRemoteRecord(
                client: operation.client,
                version: .versioned(
                    revision: 1,
                    lastOperationID: operation.operationID
                )
            )
        )
    }
}

@MainActor
private func makeAppRuntime(
    factory: AppRuntimeRemoteFactory
) throws -> AppRuntime {
    let container = try ModelContainer.inMemory(for: Schema.franAlonso)
    return AppRuntime(
        modelContainer: container,
        environment: .develop,
        makeRemoteDataSource: factory.make(environment:)
    )
}
