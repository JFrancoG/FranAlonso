import Foundation

extension StockError {
    var stockAdjustmentMessage: LocalizedStringResource {
        switch self {
        case .invalidQuantity, .invalidDelta: .stockAdjustmentErrorQuantity
        case .invalidReason: .stockAdjustmentErrorReason
        case .invalidDate: .stockAdjustmentErrorDate
        case .productNotFound: .stockAdjustmentErrorMissing
        case .productConflict: .stockAdjustmentErrorConflict
        case .identityConflict: .stockAdjustmentErrorIdentity
        case .quantityOverflow: .stockAdjustmentErrorOverflow
        case .storageFailure: .stockAdjustmentErrorStorage
        }
    }
}

extension StockAdjustmentViewModel.State {
    var stockError: StockError? {
        if case .failed(_, let error) = self { error } else { nil }
    }
}

extension StockAdjustmentViewModel.BalanceState {
    var isLoaded: Bool {
        if case .loaded = self { true } else { false }
    }
}
