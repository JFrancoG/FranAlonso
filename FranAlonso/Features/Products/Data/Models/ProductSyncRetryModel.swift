import Foundation
import SwiftData

/// The single durable backoff row owned by one Products retry scope.
@Model
final class ProductSyncRetryModel {
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

extension ProductSyncRetryModel {
    /// Creates a durable row from previously validated retry state.
    convenience init(_ state: ProductSyncRetryState) {
        self.init(
            scopeID: state.scope.storageID,
            backoffStep: state.backoffStep,
            notBefore: state.notBefore,
            lastRecoverableCategoryRawValue: state
                .lastRecoverableCategory.rawValue
        )
    }

    /// Replaces this scope's schedule without changing its durable identity.
    func update(with state: ProductSyncRetryState) throws {
        guard scopeID == state.scope.storageID else {
            throw ProductSyncRetryPolicyError.scopeMismatch
        }
        backoffStep = state.backoffStep
        notBefore = state.notBefore
        lastRecoverableCategoryRawValue = state
            .lastRecoverableCategory.rawValue
    }

    /// Reconstructs and validates the schedule requested for this exact scope.
    func decodeState(
        for scope: ProductSyncRetryScope
    ) throws -> ProductSyncRetryState {
        guard scopeID == scope.storageID else {
            throw ProductSyncRetryPolicyError.scopeMismatch
        }
        guard let category = ProductSyncRetryCategory(
            rawValue: lastRecoverableCategoryRawValue
        ) else {
            throw ProductSyncRetryPolicyError.invalidStoredCategory(
                lastRecoverableCategoryRawValue
            )
        }
        return try ProductSyncRetryState(
            scope: scope,
            backoffStep: backoffStep,
            notBefore: notBefore,
            lastRecoverableCategory: category
        )
    }
}
