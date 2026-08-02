import Foundation
import Testing
@testable import FranAlonso

@Suite("Keychain local principal data source")
struct KeychainLocalPrincipalDataSourceTests {
    @Test("A matching binding authorizes without inspecting or claiming the store")
    func matchingBindingAuthorizesWithoutInspectingOrClaimingStore() async throws {
        let operations = KeychainOperationsFake(reads: [.found(Data("principal-a".utf8))])
        let dataSource = makeDataSource(operations: operations, isStorePristine: false)

        try await dataSource.authorize(principalID: "principal-a")

        #expect(await operations.readCount == 1)
        #expect(await operations.addedValues.isEmpty)
        #expect(await operations.storeInspectionCount == 0)
    }

    @Test("A different binding fails closed")
    func differentBindingFailsClosed() async {
        let operations = KeychainOperationsFake(reads: [.found(Data("principal-a".utf8))])
        let dataSource = makeDataSource(operations: operations, isStorePristine: true)

        await #expect(throws: LocalPrincipalAuthorizationError.differentPrincipal) {
            try await dataSource.authorize(principalID: "principal-b")
        }

        #expect(await operations.addedValues.isEmpty)
        #expect(await operations.storeInspectionCount == 0)
    }

    @Test("A missing binding claims only a pristine store")
    func missingBindingClaimsOnlyPristineStore() async throws {
        let operations = KeychainOperationsFake(reads: [.missing], addResult: .stored)
        let dataSource = makeDataSource(operations: operations, isStorePristine: true)

        try await dataSource.authorize(principalID: "principal-first")

        #expect(await operations.addedValues == [Data("principal-first".utf8)])
        #expect(await operations.storeInspectionCount == 1)
    }

    @Test("A missing binding rejects a populated store")
    func missingBindingRejectsPopulatedStore() async {
        let operations = KeychainOperationsFake(reads: [.missing])
        let dataSource = makeDataSource(operations: operations, isStorePristine: false)

        await #expect(throws: LocalPrincipalAuthorizationError.localStoreNotPristine) {
            try await dataSource.authorize(principalID: "principal-first")
        }

        #expect(await operations.addedValues.isEmpty)
    }

    @Test("A duplicate claim authorizes only after rereading the same principal")
    func duplicateClaimAuthorizesOnlyAfterRereadingSamePrincipal() async throws {
        let operations = KeychainOperationsFake(
            reads: [.missing, .found(Data("principal-race".utf8))],
            addResult: .duplicate
        )
        let dataSource = makeDataSource(operations: operations, isStorePristine: true)

        try await dataSource.authorize(principalID: "principal-race")

        #expect(await operations.readCount == 2)
        #expect(await operations.addedValues == [Data("principal-race".utf8)])
    }

    @Test("A duplicate claim fails closed when another principal won the race")
    func duplicateClaimFailsClosedWhenAnotherPrincipalWonRace() async {
        let operations = KeychainOperationsFake(
            reads: [.missing, .found(Data("principal-other".utf8))],
            addResult: .duplicate
        )
        let dataSource = makeDataSource(operations: operations, isStorePristine: true)

        await #expect(throws: LocalPrincipalAuthorizationError.differentPrincipal) {
            try await dataSource.authorize(principalID: "principal-race")
        }

        #expect(await operations.readCount == 2)
    }

    @Test("A failed binding write remains a secure-storage failure")
    func failedBindingWriteRemainsSecureStorageFailure() async {
        let operations = KeychainOperationsFake(reads: [.missing], addResult: .failed)
        let dataSource = makeDataSource(operations: operations, isStorePristine: true)

        await #expect(throws: LocalPrincipalAuthorizationError.secureStorageUnavailable) {
            try await dataSource.authorize(principalID: "principal-first")
        }

        #expect(await operations.addedValues == [Data("principal-first".utf8)])
    }

    @Test("Keychain and SwiftData read failures remain distinct and fail closed")
    func keychainAndSwiftDataReadFailuresRemainDistinct() async {
        let keychainFailure = KeychainOperationsFake(reads: [.failed])
        let keychainDataSource = makeDataSource(operations: keychainFailure, isStorePristine: true)

        await #expect(throws: LocalPrincipalAuthorizationError.secureStorageUnavailable) {
            try await keychainDataSource.authorize(principalID: "principal")
        }

        let storeFailure = KeychainOperationsFake(reads: [.missing], storeInspectionFails: true)
        let storeDataSource = makeDataSource(operations: storeFailure, isStorePristine: true)

        await #expect(throws: LocalPrincipalAuthorizationError.localStoreUnavailable) {
            try await storeDataSource.authorize(principalID: "principal")
        }
    }
}

private actor KeychainOperationsFake {
    private var reads: [KeychainLocalPrincipalDataSource.ReadResult]
    private let addResult: KeychainLocalPrincipalDataSource.AddResult
    private let storeInspectionFails: Bool
    private(set) var readCount = 0
    private(set) var addedValues: [Data] = []
    private(set) var storeInspectionCount = 0

    init(
        reads: [KeychainLocalPrincipalDataSource.ReadResult],
        addResult: KeychainLocalPrincipalDataSource.AddResult = .stored,
        storeInspectionFails: Bool = false
    ) {
        self.reads = reads
        self.addResult = addResult
        self.storeInspectionFails = storeInspectionFails
    }

    func read() -> KeychainLocalPrincipalDataSource.ReadResult {
        readCount += 1
        return reads.isEmpty ? .failed : reads.removeFirst()
    }

    func add(_ value: Data) -> KeychainLocalPrincipalDataSource.AddResult {
        addedValues.append(value)
        return addResult
    }

    func inspectStore(returning pristine: Bool) throws -> Bool {
        storeInspectionCount += 1
        if storeInspectionFails {
            throw LocalStoreInspectionFailure.expected
        }
        return pristine
    }
}

private enum LocalStoreInspectionFailure: Error {
    case expected
}

private func makeDataSource(
    operations: KeychainOperationsFake,
    isStorePristine: Bool
) -> KeychainLocalPrincipalDataSource {
    KeychainLocalPrincipalDataSource(
        readBinding: {
            await operations.read()
        },
        addBinding: { value in
            await operations.add(value)
        },
        isStorePristine: {
            try await operations.inspectStore(returning: isStorePristine)
        }
    )
}
