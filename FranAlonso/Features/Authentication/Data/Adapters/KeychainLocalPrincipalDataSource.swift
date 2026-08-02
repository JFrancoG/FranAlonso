import Foundation
import Security
import SwiftData

/// Binds one opaque provider principal to the current SwiftData store through Keychain.
///
/// A missing binding can be claimed only after the complete published SwiftData schema is proven
/// empty. Existing bindings are never updated or removed by this adapter.
struct KeychainLocalPrincipalDataSource {
    enum ReadResult: Equatable {
        case found(Data)
        case missing
        case failed
    }

    enum AddResult: Equatable {
        case stored
        case duplicate
        case failed
    }

    private let readBindingOperation: @Sendable () async -> ReadResult
    private let addBindingOperation: @Sendable (Data) async -> AddResult
    private let isStorePristineOperation: @Sendable () async throws -> Bool

    /// Authorizes a principal by matching or atomically claiming the durable local binding.
    ///
    /// The blocking live Keychain operations execute outside the caller actor. A duplicate add is
    /// resolved by rereading and comparing the exact UTF-8 UID bytes.
    ///
    /// - Parameter principalID: The opaque UID published by the authentication session stream.
    /// - Throws: `CancellationError` or a fail-closed `LocalPrincipalAuthorizationError`.
    @concurrent
    func authorize(principalID: String) async throws {
        try Task.checkCancellation()
        let principalData = Data(principalID.utf8)

        switch await readBindingOperation() {
        case let .found(storedData):
            try Self.requireMatch(storedData, principalData: principalData)
        case .missing:
            try await claimMissingBinding(principalData)
        case .failed:
            throw LocalPrincipalAuthorizationError.secureStorageUnavailable
        }

        try Task.checkCancellation()
    }

    private func claimMissingBinding(_ principalData: Data) async throws {
        let isPristine: Bool
        do {
            isPristine = try await isStorePristineOperation()
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw LocalPrincipalAuthorizationError.localStoreUnavailable
        }

        guard isPristine else { throw LocalPrincipalAuthorizationError.localStoreNotPristine }
        try Task.checkCancellation()

        switch await addBindingOperation(principalData) {
        case .stored:
            return
        case .duplicate:
            switch await readBindingOperation() {
            case let .found(storedData):
                try Self.requireMatch(storedData, principalData: principalData)
            case .missing, .failed:
                throw LocalPrincipalAuthorizationError.secureStorageUnavailable
            }
        case .failed:
            throw LocalPrincipalAuthorizationError.secureStorageUnavailable
        }
    }

    private static func requireMatch(_ storedData: Data, principalData: Data) throws {
        guard storedData == principalData else { throw LocalPrincipalAuthorizationError.differentPrincipal }
    }
}

extension KeychainLocalPrincipalDataSource {
    /// Creates the live adapter for the current model container and application Keychain group.
    @MainActor
    init(modelContainer: ModelContainer) {
        let storeInspector = SwiftDataStorePristineDataSource(modelContainer: modelContainer)

        self.init(
            readBinding: {
                Self.readLiveBinding()
            },
            addBinding: { principalData in
                Self.addLiveBinding(principalData)
            },
            isStorePristine: {
                try await storeInspector.isPristine()
            }
        )
    }

    init(
        readBinding: @escaping @Sendable () async -> ReadResult,
        addBinding: @escaping @Sendable (Data) async -> AddResult,
        isStorePristine: @escaping @Sendable () async throws -> Bool
    ) {
        readBindingOperation = readBinding
        addBindingOperation = addBinding
        isStorePristineOperation = isStorePristine
    }
}

private extension KeychainLocalPrincipalDataSource {
    static let service = "com.plusprojects.FranAlonso.local-principal"
    static let account = "swiftdata-owner"

    static func readLiveBinding() -> ReadResult {
        var query = bindingQuery
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne

        var result: CFTypeRef?
        switch SecItemCopyMatching(query as CFDictionary, &result) {
        case errSecSuccess:
            guard let data = result as? Data else { return .failed }
            return .found(data)
        case errSecItemNotFound:
            return .missing
        default:
            return .failed
        }
    }

    static func addLiveBinding(_ principalData: Data) -> AddResult {
        var query = bindingQuery
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked
        query[kSecValueData as String] = principalData

        switch SecItemAdd(query as CFDictionary, nil) {
        case errSecSuccess:
            return .stored
        case errSecDuplicateItem:
            return .duplicate
        default:
            return .failed
        }
    }

    static var bindingQuery: [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: account,
            kSecAttrSynchronizable as String: false
        ]
    }
}
