import Foundation
import Testing
@testable import FranAlonso

@Suite("Confirmed billing document rendering pipeline")
struct RenderBillingDocumentUseCaseTests {
    @Test(arguments: [BillingDocumentKind.ticket, .invoice], [false, true])
    func `a confirmed snapshot and captured assets reach the renderer unchanged`(
        kind: BillingDocumentKind,
        includeSignature: Bool
    ) async throws {
        let signature = includeSignature ? Data([4, 5, 6]) : nil
        let probe = RenderingPipelineProbe(signature: signature)
        let document = try billingRenderingDocument(
            kind: kind,
            lines: [billingRenderingLine(lineDiscount: "10")],
            globalDiscount: "20"
        )
        let render = renderingUseCase(probe)

        let result = try await render(document)

        #expect(result == Data([9, 8, 7]))
        #expect(await probe.stages == [.template, .signature, .compose, .render])
        let projection = try #require(await probe.receivedProjection)
        #expect(projection.calculation.total.amount == 72)
        #expect(projection.document.request.sale.lines.first?.serviceName == "Servicio histórico de muestra")
        #expect(projection.document.request.sale.globalDiscount?.discount.percentage == 20)
        let request = try #require(await probe.receivedRequest)
        #expect(request.document == document)
        #expect(request.template == Data([1, 2, 3]))
        #expect(request.signature?.data == signature)
        #expect(await probe.requestedKind == kind)
    }

    @Test(arguments: RenderingInvalidSnapshot.allCases)
    private func `invalid captured snapshots cannot trigger asset reads`(
        _ scenario: RenderingInvalidSnapshot
    ) async throws {
        let probe = RenderingPipelineProbe()
        let document: BillingDocument
        let expected: BillingDocumentProjectionError
        switch scenario {
        case .currency:
            document = try billingRenderingDocument(lines: [billingRenderingLine(currency: .usd)])
            expected = .unsupportedCurrency(.usd)
        case .recipient:
            document = try billingRenderingDocument(kind: .invoice, includeFiscalRecipient: false)
            expected = .missingFiscalRecipient
        case .name:
            document = try billingRenderingDocument(name: " \n ")
            expected = .missingServiceName
        }

        await #expect(throws: expected) {
            try await renderingUseCase(probe)(document)
        }

        #expect(await probe.stages.isEmpty)
    }

    @Test(arguments: RenderingPipelineStage.allCases)
    private func `provider failures stop the pipeline and remain recoverable`(
        _ stage: RenderingPipelineStage
    ) async throws {
        let probe = RenderingPipelineProbe(failureStage: stage)
        let document = try billingRenderingDocument()

        await #expect(throws: RenderingProbeFailure.unavailable) {
            try await renderingUseCase(probe)(document)
        }

        #expect(await probe.stages == renderingExpectedStages(through: stage))
    }

    @Test
    func `a renderer cannot publish an empty PDF as success`() async throws {
        let probe = RenderingPipelineProbe(output: Data())
        let document = try billingRenderingDocument()

        await #expect(throws: BillingPDFRenderError.renderingFailed) {
            try await renderingUseCase(probe)(document)
        }

        #expect(await probe.stages == [.template, .signature, .compose, .render])
    }

    @Test(arguments: RenderingAlteration.allCases)
    private func `a composer cannot substitute captured document or resource bytes`(
        _ alteration: RenderingAlteration
    ) async throws {
        let probe = RenderingPipelineProbe(alteration: alteration)
        let document = try billingRenderingDocument()

        switch alteration {
        case .document:
            await #expect(throws: BillingDocumentError.conflictingDocument) {
                try await renderingUseCase(probe)(document)
            }
        case .template, .signature:
            await #expect(throws: BillingPDFRenderError.renderingFailed) {
                try await renderingUseCase(probe)(document)
            }
        }

        #expect(await probe.stages == [.template, .signature, .compose])
        #expect(await probe.receivedRequest == nil)
    }

    @Test
    func `an already cancelled task reads no document resources`() async throws {
        let pause = RenderingPause()
        let probe = RenderingPipelineProbe()
        let document = try billingRenderingDocument()
        let render = renderingUseCase(probe)
        let task = Task {
            await pause.wait()
            return try await render(document)
        }
        #expect(await pause.waitUntilPausedOrCompleted())
        task.cancel()
        await pause.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }

        #expect(await probe.stages.isEmpty)
    }

    @Test(arguments: RenderingPipelineStage.allCases, [false, true])
    private func `cancellation prevails over each late success or provider failure`(
        stage: RenderingPipelineStage,
        failAfterPause: Bool
    ) async throws {
        let pause = RenderingPause()
        let probe = RenderingPipelineProbe(failureStage: failAfterPause ? stage : nil, pause: pause, pausedStage: stage)
        let document = try billingRenderingDocument()
        let render = renderingUseCase(probe)
        let task = Task {
            do {
                let result = try await render(document)
                await pause.complete()
                return result
            } catch {
                await pause.complete()
                throw error
            }
        }
        #expect(await pause.waitUntilPausedOrCompleted())
        task.cancel()
        await pause.release()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }

        #expect(await probe.stages == renderingExpectedStages(through: stage))
    }
}

private enum RenderingPipelineStage: CaseIterable, Equatable {
    case template, signature, compose, render
}

private enum RenderingInvalidSnapshot: CaseIterable {
    case currency, recipient, name
}

private enum RenderingAlteration: CaseIterable {
    case document, template, signature
}

private enum RenderingProbeFailure: Error, Equatable {
    case unavailable
}

private func renderingUseCase(_ probe: RenderingPipelineProbe) -> RenderBillingDocumentUseCase {
    RenderBillingDocumentUseCase(
        templates: probe,
        signatures: probe,
        composer: probe,
        renderer: probe
    )
}

private func renderingExpectedStages(through stage: RenderingPipelineStage) -> [RenderingPipelineStage] {
    switch stage {
    case .template: [.template]
    case .signature: [.template, .signature]
    case .compose: [.template, .signature, .compose]
    case .render: [.template, .signature, .compose, .render]
    }
}

private actor RenderingPipelineProbe:
    BillingDocumentTemplateRepository,
    BillingBusinessSignatureRepository,
    BillingDocumentPDFComposer,
    BillingPDFRenderer {
    private let signature: Data?
    private let failureStage: RenderingPipelineStage?
    private let output: Data
    private let alteration: RenderingAlteration?
    private let pause: RenderingPause?
    private let pausedStage: RenderingPipelineStage?
    private(set) var stages: [RenderingPipelineStage] = []
    private(set) var receivedProjection: BillingDocumentProjection?
    private(set) var receivedRequest: BillingPDFRenderRequest?
    private(set) var requestedKind: BillingDocumentKind?

    init(
        signature: Data? = Data([4, 5, 6]),
        failureStage: RenderingPipelineStage? = nil,
        output: Data = Data([9, 8, 7]),
        alteration: RenderingAlteration? = nil,
        pause: RenderingPause? = nil,
        pausedStage: RenderingPipelineStage? = nil
    ) {
        self.signature = signature
        self.failureStage = failureStage
        self.output = output
        self.alteration = alteration
        self.pause = pause
        self.pausedStage = pausedStage
    }

    func loadTemplate(for kind: BillingDocumentKind) async throws -> Data {
        requestedKind = kind
        stages.append(.template)
        try await finish(.template)
        return Data([1, 2, 3])
    }

    func loadSignature() async throws -> Data? {
        stages.append(.signature)
        try await finish(.signature)
        return signature
    }

    func importSignature(_ data: Data) async throws {}

    func compose(
        _ projection: BillingDocumentProjection,
        template: Data,
        signature: Data?
    ) async throws -> BillingPDFRenderRequest {
        stages.append(.compose)
        receivedProjection = projection
        try await finish(.compose)
        var document = projection.document
        var capturedTemplate = template
        var capturedSignature = signature
        switch alteration {
        case .document:
            document = try BillingDocument.numbered(
                request: document.request,
                number: document.number,
                issuedAt: document.issuedAt.addingTimeInterval(1)
            )
        case .template:
            capturedTemplate = Data([3, 2, 1])
        case .signature:
            capturedSignature = Data([6, 5, 4])
        case nil:
            break
        }
        let numberFrame = try BillingPDFRectangle(
            x: 40,
            y: 700,
            width: 100,
            height: 30
        )
        let dateFrame = try BillingPDFRectangle(
            x: 200,
            y: 700,
            width: 100,
            height: 30
        )
        let textFrame = try BillingPDFRectangle(
            x: 40,
            y: 500,
            width: 500,
            height: 40
        )
        let fields = [
            try BillingPDFTextField(text: "Complete synthetic pipeline output", frame: textFrame)
        ]
        let capturedImage = try capturedSignature.map {
            BillingPDFSignature(
                data: $0,
                frame: try BillingPDFRectangle(
                    x: 40,
                    y: 200,
                    width: 100,
                    height: 40
                )
            )
        }
        return try BillingPDFRenderRequest(
            document: document,
            template: capturedTemplate,
            title: "Synthetic billing pipeline",
            numberFrame: numberFrame,
            dateFrame: dateFrame,
            pages: [BillingPDFPage(fields: fields)],
            signature: capturedImage
        )
    }

    func render(_ request: BillingPDFRenderRequest) async throws -> Data {
        stages.append(.render)
        receivedRequest = request
        try await finish(.render)
        return output
    }

    private func finish(_ stage: RenderingPipelineStage) async throws {
        if pausedStage == stage, let pause {
            await pause.wait()
        }
        if failureStage == stage {
            throw RenderingProbeFailure.unavailable
        }
    }
}

private actor RenderingPause {
    private var pending: CheckedContinuation<Void, Never>?
    private var arrivals: [CheckedContinuation<Bool, Never>] = []
    private var completed = false

    func wait() async {
        await withCheckedContinuation { continuation in
            pending = continuation
            for arrival in arrivals {
                arrival.resume(returning: true)
            }
            arrivals.removeAll()
        }
    }

    func waitUntilPausedOrCompleted() async -> Bool {
        if pending != nil {
            return true
        }
        if completed {
            return false
        }
        return await withCheckedContinuation { continuation in
            arrivals.append(continuation)
        }
    }

    func release() {
        pending?.resume()
        pending = nil
    }

    func complete() {
        completed = true
        for arrival in arrivals {
            arrival.resume(returning: false)
        }
        arrivals.removeAll()
    }
}
