import Foundation
import SwiftData

/// The single durable backoff row owned by one Clients retry scope.
@Model
final class ClientSyncRetryModel {
    @Attribute(.unique) private(set) var scopeID: String
    private(set) var backoffStep: Int
    private(set) var notBefore: Date
    private(set) var lastRecoverableCategoryRawValue: String

    init(
        scopeID: String,
        backoffStep: Int,
        notBefore: Date,
        lastRecoverableCategoryRawValue: String
    ) {
        self.scopeID = scopeID
        self.backoffStep = backoffStep
        self.notBefore = notBefore
        self.lastRecoverableCategoryRawValue = lastRecoverableCategoryRawValue
    }
}

extension ClientSyncRetryModel {
    /// Creates a durable row from previously validated retry state.
    convenience init(_ state: ClientSyncRetryState) {
        self.init(
            scopeID: state.scope.storageID,
            backoffStep: state.backoffStep,
            notBefore: state.notBefore,
            lastRecoverableCategoryRawValue: state
                .lastRecoverableCategory.rawValue
        )
    }

    /// Replaces this scope's schedule without changing its durable identity.
    func update(with state: ClientSyncRetryState) throws {
        guard scopeID == state.scope.storageID else {
            throw ClientSyncRetryPolicyError.scopeMismatch
        }
        backoffStep = state.backoffStep
        notBefore = state.notBefore
        lastRecoverableCategoryRawValue = state
            .lastRecoverableCategory.rawValue
    }

    /// Reconstructs and validates the schedule requested for this exact scope.
    func decodeState(
        for scope: ClientSyncRetryScope
    ) throws -> ClientSyncRetryState {
        guard scopeID == scope.storageID else {
            throw ClientSyncRetryPolicyError.scopeMismatch
        }
        guard let category = ClientSyncRetryCategory(
            rawValue: lastRecoverableCategoryRawValue
        ) else {
            throw ClientSyncRetryPolicyError.invalidStoredCategory(
                lastRecoverableCategoryRawValue
            )
        }
        return try ClientSyncRetryState(
            scope: scope,
            backoffStep: backoffStep,
            notBefore: notBefore,
            lastRecoverableCategory: category
        )
    }
}
