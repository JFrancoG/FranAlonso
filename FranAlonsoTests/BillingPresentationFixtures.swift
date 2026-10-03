import Foundation
@testable import FranAlonso

enum BillingPresentationResponse {
    case success
    case failure(BillingDocumentReservationError)
    case unknownFailure
    case mismatchedRequest
}

enum BillingPresentationClosureStage {
    case selection, pending, failed, numbered
}

struct BillingPresentationReply {
    let gate: RecoveryOperationGate?
    let response: BillingPresentationResponse
}

actor BillingPresentationRepository: BillingDocumentReservationRepository {
    private var replies: [BillingPresentationReply]
    private(set) var received: [BillingDocumentRequest] = []

    func reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument {
        received.append(request)
        let reply = replies.isEmpty
            ? BillingPresentationReply(gate: nil, response: .success)
            : replies.removeFirst()
        if let gate = reply.gate {
            await gate.enter()
        }
        switch reply.response {
        case .success:
            return try billingPresentationDocument(request)
        case let .failure(error):
            throw error
        case .unknownFailure:
            throw BillingPresentationPrivateError.providerDetail
        case .mismatchedRequest:
            return try billingPresentationDocument(billingTransactionRequest(index: 99))
        }
    }

    init(replies: [BillingPresentationReply] = []) {
        self.replies = replies
    }
}

private enum BillingPresentationPrivateError: Error {
    case providerDetail
}

func billingPresentationDocument(_ request: BillingDocumentRequest) throws -> BillingDocument {
    try BillingDocument.numbered(
        request: request,
        number: BillingDocumentNumber(series: request.kind.series, value: 41),
        issuedAt: Date(timeIntervalSince1970: 190)
    )
}
