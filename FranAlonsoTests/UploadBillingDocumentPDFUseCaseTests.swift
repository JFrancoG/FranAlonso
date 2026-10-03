import Foundation
import Testing
@testable import FranAlonso

@Suite("Authorized confirmed PDF upload attempt")
struct UploadBillingDocumentPDFUseCaseTests {
    @Test
    func `the confirmed document and exact prepared bytes reach the port once`() async throws {
        let probe = BillingStorageProbe()
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()
        let upload = AppDependencies.uploadBillingDocumentPDFUseCase(repository: probe)

        #expect(await probe.uploadCount == 0)
        let receipt = try await upload(document, pdf: pdf, access: billingStorageAccess())

        #expect(receipt.matches(documentID: document.id, principalID: "principal-A"))
        #expect(await probe.uploadCount == 1)
        #expect(await probe.receivedDocument == document)
        #expect(await probe.receivedPDF == pdf)
    }

    @Test
    func `empty bytes do not invoke a provider`() async throws {
        let probe = BillingStorageProbe()
        let document = try billingRenderingDocument()

        await #expect(throws: BillingPDFStorageError.invalidPDF) {
            try await UploadBillingDocumentPDFUseCase(repository: probe)(
                document,
                pdf: Data(),
                access: billingStorageAccess()
            )
        }

        #expect(await probe.uploadCount == 0)
    }

    @Test(arguments: BillingStorageReceiptMutation.allCases)
    func `a foreign acknowledgement cannot publish upload success`(
        _ mutation: BillingStorageReceiptMutation
    ) async throws {
        let probe = BillingStorageProbe(alteration: mutation)
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: BillingPDFStorageError.invalidReceipt) {
            try await UploadBillingDocumentPDFUseCase(repository: probe)(
                document,
                pdf: pdf,
                access: billingStorageAccess()
            )
        }

        #expect(await probe.uploadCount == 1)
    }

    @Test(arguments: [
        BillingPDFStorageError.unavailable,
        .permissionDenied,
        .conflict,
        .invalidPDF,
        .invalidReceipt
    ])
    func `neutral failures escape unchanged without automatic retry`(_ expected: BillingPDFStorageError) async throws {
        let probe = BillingStorageProbe(failure: expected)
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: expected) {
            try await UploadBillingDocumentPDFUseCase(repository: probe)(
                document,
                pdf: pdf,
                access: billingStorageAccess()
            )
        }

        #expect(await probe.uploadCount == 1)
    }

    @Test
    func `unknown provider errors become neutral unavailable failures`() async throws {
        let probe = BillingStorageProbe(failure: BillingStorageProviderFailure.detailedProviderFailure)
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: BillingPDFStorageError.unavailable) {
            try await UploadBillingDocumentPDFUseCase(repository: probe)(
                document,
                pdf: pdf,
                access: billingStorageAccess()
            )
        }

        #expect(await probe.uploadCount == 1)
    }

    @Test
    func `a revoked capability stops the upload before provider access`() async throws {
        let permit = BillingStoragePermit()
        let access = BillingAssetAccess(principalID: "principal-A") {
            try await permit.validate()
        }
        await permit.revoke()
        let probe = BillingStorageProbe()
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: BillingPDFStorageError.permissionDenied) {
            try await UploadBillingDocumentPDFUseCase(repository: probe)(document, pdf: pdf, access: access)
        }

        #expect(await probe.uploadCount == 0)
    }

    @Test
    func `revocation during upload prevents publication of a late receipt`() async throws {
        let permit = BillingStoragePermit()
        let access = BillingAssetAccess(principalID: "principal-A") {
            try await permit.validate()
        }
        let pause = BillingStoragePause()
        let probe = BillingStorageProbe(pause: pause)
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()
        let upload = UploadBillingDocumentPDFUseCase(repository: probe)
        let task = Task {
            do {
                let receipt = try await upload(document, pdf: pdf, access: access)
                await pause.complete()
                return receipt
            } catch {
                await pause.complete()
                throw error
            }
        }

        #expect(await pause.waitUntilPausedOrCompleted())
        await permit.revoke()
        await pause.release()

        await #expect(throws: BillingPDFStorageError.permissionDenied) {
            try await task.value
        }

        #expect(await probe.uploadCount == 1)
    }

    @Test(arguments: [false, true])
    func `cancellation prevails over late success and provider failure`(_ failAfterPause: Bool) async throws {
        let pause = BillingStoragePause()
        let probe = BillingStorageProbe(
            failure: failAfterPause ? BillingStorageProviderFailure.detailedProviderFailure : nil,
            pause: pause
        )
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()
        let upload = UploadBillingDocumentPDFUseCase(repository: probe)
        let task = Task {
            do {
                let receipt = try await upload(document, pdf: pdf, access: billingStorageAccess())
                await pause.complete()
                return receipt
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

        #expect(await probe.uploadCount == 1)
    }

    @Test
    func `an already cancelled task invokes no provider`() async throws {
        let probe = BillingStorageProbe()
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: CancellationError.self) {
            try await withThrowingTaskGroup(of: BillingPDFUploadReceipt.self) { group in
                group.cancelAll()
                group.addTask {
                    try await UploadBillingDocumentPDFUseCase(repository: probe)(
                        document,
                        pdf: pdf,
                        access: billingStorageAccess()
                    )
                }
                try await group.waitForAll()
            }
        }

        #expect(await probe.uploadCount == 0)
    }

    @Test
    func `normal composition remains unavailable until a repository is injected`() async throws {
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: BillingPDFStorageError.unavailable) {
            try await AppDependencies.uploadBillingDocumentPDFUseCase()(
                document,
                pdf: pdf,
                access: billingStorageAccess()
            )
        }
    }
}
