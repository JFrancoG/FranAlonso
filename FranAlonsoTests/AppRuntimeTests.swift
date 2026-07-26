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
        #expect(await remote.mutationCount == 0)
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
    private var mutationCalls = 0

    var fetchCount: Int { fetchCalls }
    var mutationCount: Int { mutationCalls }

    func fetchChanges(
        after cursor: ClientSyncCursor?
    ) async throws -> ClientRemoteChangeBatch {
        fetchCalls += 1
        return ClientRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? ClientSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ClientPendingOperation
    ) async throws -> ClientRemoteMutationResult {
        mutationCalls += 1
        guard case .upsert(let upsert) = operation else {
            throw ClientRemoteDataSourceError.unexpected
        }
        return .applied(
            ClientRemoteRecord(
                client: upsert.client,
                version: .versioned(
                    revision: 1,
                    lastOperationID: upsert.operationID
                ),
                changeSequence: 1
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
