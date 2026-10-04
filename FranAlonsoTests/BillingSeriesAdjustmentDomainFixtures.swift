import Foundation
@testable import FranAlonso

struct BillingSeriesAdjustmentDomainFixtures {
    static let operationID = UUID(uuid: (19, 19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1))
    static let alternateID = UUID(uuid: (19, 19, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2))
    static let principalID = "synthetic-billing-administrator"
    static let adjustedAt = Date(timeIntervalSince1970: 400)

    static func request(
        series: BillingDocumentSeries = .ticket,
        expected: Int64 = 40,
        target: Int64 = 90
    ) throws -> BillingSeriesAdjustmentRequest {
        try BillingSeriesAdjustmentRequest(
            operationID: operationID,
            series: series,
            expectedLastNumber: expected,
            targetLastNumber: target
        )
    }

    static func receipt(_ request: BillingSeriesAdjustmentRequest) throws -> BillingSeriesAdjustmentReceipt {
        try BillingSeriesAdjustmentReceipt(request: request, principalID: principalID, adjustedAt: adjustedAt)
    }

    static func requestPayload(expected: Int64, target: Int64) -> Data {
        Data("""
        {
          "operationID": "13130000-0000-0000-0000-000000000001",
          "series": "ticket",
          "expectedLastNumber": \(expected),
          "targetLastNumber": \(target),
          "reason": "seriesAlignment"
        }
        """.utf8)
    }

    static func receiptPayload(principalJSON: String, adjustedAtJSON: String = "400") -> Data {
        Data("""
        {
          "request": {
            "operationID": "13130000-0000-0000-0000-000000000001",
            "series": "ticket",
            "expectedLastNumber": 40,
            "targetLastNumber": 90,
            "reason": "seriesAlignment"
          },
          "principalID": \(principalJSON),
          "adjustedAt": \(adjustedAtJSON)
        }
        """.utf8)
    }

    static func differingRequest(
        _ request: BillingSeriesAdjustmentRequest,
        difference: BillingSeriesAdjustmentDomainDifference
    ) throws -> BillingSeriesAdjustmentRequest {
        var operationID = request.id
        var series = request.series
        var expected = request.expectedLastNumber
        var target = request.targetLastNumber
        switch difference {
        case .operationIdentity:
            operationID = alternateID
        case .series:
            series = .invoice
        case .expectedHead:
            expected = 41
        case .targetHead:
            target = 91
        }
        return try BillingSeriesAdjustmentRequest(
            operationID: operationID,
            series: series,
            expectedLastNumber: expected,
            targetLastNumber: target
        )
    }
}

struct BillingSeriesAdjustmentDomainBounds {
    let expected: Int64
    let target: Int64
}

struct BillingSeriesAdjustmentDomainAdvance {
    let series: BillingDocumentSeries
    let expected: Int64
    let target: Int64
}

enum BillingSeriesAdjustmentDomainDifference {
    case operationIdentity, series, expectedHead, targetHead
}

enum BillingSeriesAdjustmentDomainProviderFailure: Error {
    case privateFailure
}

enum BillingSeriesAdjustmentDomainLateOutcome {
    case receipt, providerFailure
}

actor BillingSeriesAdjustmentDomainRepositorySpy: BillingSeriesAdjustmentRepository {
    private let response: BillingSeriesAdjustmentReceipt?
    private let error: (any Error)?
    private let responseGate: RecoveryOperationGate?
    private(set) var received: [BillingSeriesAdjustmentRequest] = []

    init(
        response: BillingSeriesAdjustmentReceipt? = nil,
        error: (any Error)? = nil,
        responseGate: RecoveryOperationGate? = nil
    ) {
        self.response = response
        self.error = error
        self.responseGate = responseGate
    }

    func adjust(_ request: BillingSeriesAdjustmentRequest) async throws -> BillingSeriesAdjustmentReceipt {
        received.append(request)
        if let responseGate {
            await responseGate.enter()
        }
        if let error {
            throw error
        }
        guard let response else { throw BillingSeriesAdjustmentDomainProviderFailure.privateFailure }
        return response
    }
}
