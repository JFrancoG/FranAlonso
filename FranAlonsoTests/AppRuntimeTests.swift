import SwiftData
import Testing
@testable import FranAlonso

@Suite("Application runtime")
@MainActor
struct AppRuntimeTests {
    @Test("Sync remains uncomposed until Firebase is configured")
    func syncRemainsUncomposedUntilFirebaseIsConfigured() throws {
        let clientFactory = AppRuntimeRemoteFactory()
        let productFactory = AppRuntimeProductRemoteFactory()
        let runtime = try makeAppRuntime(
            clientFactory: clientFactory,
            productFactory: productFactory
        )

        runtime.activateClientSync(firebaseIsConfigured: false)
        runtime.activateProductSync(firebaseIsConfigured: false)

        #expect(clientFactory.environments.isEmpty)
        #expect(productFactory.environments.isEmpty)
        #expect(runtime.clientSyncEngine == nil)
        #expect(runtime.productSyncEngine == nil)
    }

    @Test("Configured Firebase composes one inactive environment-specific engine")
    func configuredFirebaseComposesOneInactiveEnvironmentSpecificEngine() async throws {
        let clientRemote = AppRuntimeRemoteFake()
        let productRemote = AppRuntimeProductRemoteFake()
        let clientFactory = AppRuntimeRemoteFactory(remote: clientRemote)
        let productFactory = AppRuntimeProductRemoteFactory(remote: productRemote)
        let runtime = try makeAppRuntime(
            clientFactory: clientFactory,
            productFactory: productFactory
        )

        runtime.activateClientSync(firebaseIsConfigured: true)
        runtime.activateClientSync(firebaseIsConfigured: true)
        runtime.activateProductSync(firebaseIsConfigured: true)
        runtime.activateProductSync(firebaseIsConfigured: true)

        #expect(clientFactory.environments == [.develop])
        #expect(productFactory.environments == [.develop])
        #expect(runtime.clientSyncEngine != nil)
        #expect(runtime.productSyncEngine != nil)
        #expect(await clientRemote.fetchCount == 0)
        #expect(await clientRemote.mutationCount == 0)
        #expect(await productRemote.fetchCount == 0)
        #expect(await productRemote.mutationCount == 0)
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
private final class AppRuntimeProductRemoteFactory {
    private(set) var environments: [FirestoreEnvironment] = []
    private let remote: AppRuntimeProductRemoteFake

    init(remote: AppRuntimeProductRemoteFake = AppRuntimeProductRemoteFake()) {
        self.remote = remote
    }

    func make(environment: FirestoreEnvironment) -> any ProductRemoteDataSource {
        environments.append(environment)
        return remote
    }
}

private actor AppRuntimeProductRemoteFake: ProductRemoteDataSource {
    private var fetchCalls = 0
    private var mutationCalls = 0

    var fetchCount: Int { fetchCalls }
    var mutationCount: Int { mutationCalls }

    func fetchChanges(
        after cursor: ProductSyncCursor?
    ) async throws -> ProductRemoteChangeBatch {
        fetchCalls += 1
        return ProductRemoteChangeBatch(
            records: [],
            nextCursor: cursor ?? ProductSyncCursor(changeSequence: 0)
        )
    }

    func apply(
        _ operation: ProductPendingOperation
    ) async throws -> ProductRemoteMutationResult {
        mutationCalls += 1
        guard case .upsert(let upsert) = operation else {
            throw ProductRemoteDataSourceError.unexpected
        }
        return .applied(
            ProductRemoteRecord(
                product: upsert.product,
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
    clientFactory: AppRuntimeRemoteFactory,
    productFactory: AppRuntimeProductRemoteFactory
) throws -> AppRuntime {
    let container = try ModelContainer.inMemory(for: Schema.franAlonso)
    return AppRuntime(
        modelContainer: container,
        environment: .develop,
        makeClientRemoteDataSource: clientFactory.make(environment:),
        makeProductRemoteDataSource: productFactory.make(environment:)
    )
}
