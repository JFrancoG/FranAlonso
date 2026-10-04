import Foundation

extension BillingViewModel {
    var progressMessage: LocalizedStringResource {
        if closedSale != nil {
            return "billing.closure.accepted"
        }
        if case .materialization(_, .closing) = state {
            return "billing.closure.working"
        }
        if isWorking {
            return "billing.document.working"
        }
        if recoveryFailed {
            return "billing.document.recover.failed"
        }
        if requiresDocumentSelection {
            return "billing.document.recover.choose"
        }
        guard let delivery else { return "billing.document.recovering" }
        if delivery.document == nil {
            return "billing.document.pending.number"
        }
        if delivery.pdf == nil {
            return "billing.document.pending.pdf"
        }
        return delivery.isFinal ? "billing.document.ready" : "billing.document.pending.upload"
    }

    var generationActionTitle: LocalizedStringResource {
        failure != nil || operationFailed ? "billing.document.retry" : "billing.document.generate"
    }

    var operationAnnouncement: LocalizedStringResource {
        operationFailed && !recoveryFailed ? "billing.document.error.message" : progressMessage
    }
}
