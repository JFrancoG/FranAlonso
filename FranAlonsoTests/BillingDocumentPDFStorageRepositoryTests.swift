import Foundation
import Testing
@testable import FranAlonso

@Suite("Immutable confirmed billing PDF Storage")
struct BillingDocumentPDFStorageRepositoryTests {
    @Test
    func `prepared bytes and the stable private path survive repository recreation`() async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()
        let access = billingStorageAccess()
        let first = try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
            document,
            pdf: pdf,
            access: access
        )
        let recovered = try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
            document,
            pdf: pdf,
            access: access
        )

        #expect(recovered == first)
        #expect(first.objectPath ==
            "billing-pdfs/12d8cd447310d5f744d3d5feb462a9e1dbf27851f98091f709fc32fb4ce61141/" +
            "13800000-0000-0000-0000-000000020005.pdf")
        #expect(await remote.documentCount == 1)
        #expect(await remote.document(documentID: document.id, principalID: "principal-A") == document)
        #expect(await remote.pdf(documentID: document.id, principalID: "principal-A") == pdf)
    }

    @Test
    func `concurrent identical uploads accept one object and one receipt`() async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()
        let access = billingStorageAccess()
        let receipts = try await withThrowingTaskGroup(of: BillingPDFUploadReceipt.self) { group in
            for _ in 0..<8 {
                group.addTask {
                    try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
                        document,
                        pdf: pdf,
                        access: access
                    )
                }
            }
            var receipts: [BillingPDFUploadReceipt] = []
            for try await receipt in group {
                receipts.append(receipt)
            }
            return receipts
        }

        let first = try #require(receipts.first)
        #expect(receipts.count == 8)
        #expect(receipts.allSatisfy { $0 == first })
        #expect(await remote.documentCount == 1)
        #expect(await remote.pdf(documentID: document.id, principalID: "principal-A") == pdf)
    }

    @Test(arguments: BillingStorageBindingMutation.allCases)
    func `every different bound field conflicts and retains the original PDF`(
        _ mutation: BillingStorageBindingMutation
    ) async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let repository = InMemoryBillingDocumentPDFStorageRepository(remote: remote)
        let original = try billingRenderingDocument(kind: .invoice)
        let pdf = try billingPDFTemplate()
        let changedPDF = mutation == .pdf ? try billingPDFTemplate(pageCount: 2) : pdf
        let changed = try mutation.document(original)
        let access = billingStorageAccess()
        let receipt = try await repository.upload(original, pdf: pdf, access: access)

        await #expect(throws: BillingPDFStorageError.conflict) {
            try await repository.upload(changed, pdf: changedPDF, access: access)
        }

        #expect(await remote.documentCount == 1)
        #expect(await remote.document(documentID: original.id, principalID: "principal-A") == original)
        #expect(await remote.pdf(documentID: original.id, principalID: "principal-A") == pdf)
        #expect(try await repository.upload(original, pdf: pdf, access: access) == receipt)
    }

    @Test
    func `competing different PDFs cannot overwrite one another`() async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let document = try billingRenderingDocument()
        let first = try billingPDFTemplate()
        let second = try billingPDFTemplate(pageCount: 2)
        let access = billingStorageAccess()
        let results = await withTaskGroup(of: Result<BillingPDFUploadReceipt, BillingPDFStorageError>.self) { group in
            for pdf in [first, second] {
                group.addTask {
                    do {
                        return .success(try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
                            document,
                            pdf: pdf,
                            access: access
                        ))
                    } catch let error as BillingPDFStorageError {
                        return .failure(error)
                    } catch {
                        Issue.record(error)
                        return .failure(.unavailable)
                    }
                }
            }
            var results: [Result<BillingPDFUploadReceipt, BillingPDFStorageError>] = []
            for await result in group {
                results.append(result)
            }
            return results
        }

        #expect(results.filter {
            if case .success = $0 {
                true
            } else {
                false
            }
        }.count == 1)
        #expect(results.filter {
            if case .failure(.conflict) = $0 {
                true
            } else {
                false
            }
        }.count == 1)
        let accepted = try #require(await remote.pdf(documentID: document.id, principalID: "principal-A"))
        #expect(accepted == first || accepted == second)
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `the same document identity remains isolated between principals`() async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let repository = InMemoryBillingDocumentPDFStorageRepository(remote: remote)
        let document = try billingRenderingDocument()
        let firstPDF = try billingPDFTemplate()
        let secondPDF = try billingPDFTemplate(pageCount: 2)
        let first = try await repository.upload(document, pdf: firstPDF, access: billingStorageAccess())
        let second = try await repository.upload(
            document,
            pdf: secondPDF,
            access: billingStorageAccess(principalID: "principal-B")
        )

        #expect(first.objectPath != second.objectPath)
        #expect(await remote.pdf(documentID: document.id, principalID: "principal-A") == firstPDF)
        #expect(await remote.pdf(documentID: document.id, principalID: "principal-B") == secondPDF)
        #expect(await remote.documentCount == 2)
    }

    @Test(arguments: [
        (InMemoryBillingDocumentPDFStorageRepository.Failure.unavailable, BillingPDFStorageError.unavailable),
        (.permissionDenied, .permissionDenied)
    ])
    func `offline and permission failures retain no object and allow an explicit retry`(
        failure: InMemoryBillingDocumentPDFStorageRepository.Failure,
        expected: BillingPDFStorageError
    ) async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let repository = InMemoryBillingDocumentPDFStorageRepository(remote: remote, failures: [failure])
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: expected) {
            try await repository.upload(document, pdf: pdf, access: billingStorageAccess())
        }
        #expect(await remote.documentCount == 0)

        _ = try await repository.upload(document, pdf: pdf, access: billingStorageAccess())
        #expect(await remote.documentCount == 1)
        #expect(await remote.pdf(documentID: document.id, principalID: "principal-A") == pdf)
    }

    @Test(arguments: [
        InMemoryBillingDocumentPDFStorageRepository.Failure.responseLost,
        .cancelledAfterAcceptance
    ])
    func `lost responses and late cancellation recover the original acceptance`(
        failure: InMemoryBillingDocumentPDFStorageRepository.Failure
    ) async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let repository = InMemoryBillingDocumentPDFStorageRepository(remote: remote, failures: [failure])
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()
        if failure == .responseLost {
            await #expect(throws: BillingPDFStorageError.unavailable) {
                try await repository.upload(document, pdf: pdf, access: billingStorageAccess())
            }
        } else {
            await #expect(throws: CancellationError.self) {
                try await repository.upload(document, pdf: pdf, access: billingStorageAccess())
            }
        }
        let accepted = try #require(await remote.receipt(documentID: document.id, principalID: "principal-A"))

        let recovered = try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
            document,
            pdf: pdf,
            access: billingStorageAccess()
        )

        #expect(recovered == accepted)
        #expect(await remote.documentCount == 1)
        #expect(await remote.pdf(documentID: document.id, principalID: "principal-A") == pdf)
    }

    @Test
    func `cancellation before acceptance creates no remote value`() async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let repository = InMemoryBillingDocumentPDFStorageRepository(
            remote: remote,
            failures: [.cancelledBeforeAcceptance]
        )
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: CancellationError.self) {
            try await repository.upload(document, pdf: pdf, access: billingStorageAccess())
        }

        #expect(await remote.documentCount == 0)
        _ = try await repository.upload(document, pdf: pdf, access: billingStorageAccess())
        #expect(await remote.documentCount == 1)
    }

    @Test(arguments: BillingStorageInvalidPDF.allCases)
    func `invalid or over budget prepared PDFs are rejected before remote acceptance`(
        _ scenario: BillingStorageInvalidPDF
    ) async throws {
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let document = try billingRenderingDocument()
        let pdf = try scenario.bytes()

        await #expect(throws: BillingPDFStorageError.invalidPDF) {
            try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
                document,
                pdf: pdf,
                access: billingStorageAccess()
            )
        }

        #expect(await remote.documentCount == 0)
    }

    @Test(arguments: BillingStorageAcceptedBudget.allCases)
    func `PDFs exactly at each resource budget remain accepted unchanged`(
        _ budget: BillingStorageAcceptedBudget
    ) async throws {
        let document = try billingRenderingDocument()
        let pdf = try budget.preparedPDF()
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()

        _ = try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
            document,
            pdf: pdf,
            access: billingStorageAccess()
        )

        #expect(await remote.pdf(documentID: document.id, principalID: "principal-A") == pdf)
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `actual multipage renderer bytes are accepted and retained unchanged`() async throws {
        let document = try billingRenderingDocument()
        let request = try billingPDFRequest(
            pages: [billingPDFPage(["First"]), billingPDFPage(["Second"]), billingPDFPage(["Third"])],
            document: document
        )
        let pdf = try await AppDependencies.billingPDFRenderer().render(request)
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()

        _ = try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
            document,
            pdf: pdf,
            access: billingStorageAccess()
        )

        #expect(try billingPDFSnapshot(pdf).texts.count == 3)
        #expect(await remote.pdf(documentID: document.id, principalID: "principal-A") == pdf)
        #expect(await remote.documentCount == 1)
    }

    @Test
    func `a revoked capability cannot accept a PDF directly through the repository`() async throws {
        let permit = BillingStoragePermit()
        let access = BillingAssetAccess(principalID: "principal-A") {
            try await permit.validate()
        }
        await permit.revoke()
        let remote = InMemoryBillingDocumentPDFStorageRepository.RemoteStore()
        let document = try billingRenderingDocument()
        let pdf = try billingPDFTemplate()

        await #expect(throws: BillingPDFStorageError.permissionDenied) {
            try await InMemoryBillingDocumentPDFStorageRepository(remote: remote).upload(
                document,
                pdf: pdf,
                access: access
            )
        }

        #expect(await remote.documentCount == 0)
    }
}
