import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Authorized local sale closure", .timeLimit(.minutes(1)))
struct SaleClosureAuthorizationTests {
    @Test("authorized command reaches the specific repository capability without unrestricted save")
    func authorizedCommandReachesTheSpecificRepositoryCapabilityWithoutUnrestrictedSave() async throws {
        let document = try billingRenderingDocument()
        let accepted = try SaleClosureTestFixtures.closed(document)
        let repository = SaleClosureControlledRepository(accepted: accepted)
        let request = try SaleClosureTestFixtures.command(document)
        let useCase = CloseSaleUseCase(
            repository: repository,
            access: billingStorageAccess(principalID: SaleClosureTestFixtures.principalID)
        )
        #expect(try await useCase(request) == accepted)
        #expect(await repository.commands == [request])
        #expect(await repository.principals == [SaleClosureTestFixtures.principalID])
        #expect(await repository.freeSaveCount == 0)
    }

    @Test(
        "knowing a principal without a valid capability never contacts the repository",
        arguments: ["", "known-but-revoked-principal"]
    )
    func knowingAPrincipalWithoutAValidCapabilityNeverContactsTheRepository(_ principal: String) async throws {
        let document = try billingRenderingDocument()
        let repository = try SaleClosureControlledRepository(accepted: SaleClosureTestFixtures.closed(document))
        let access = BillingAssetAccess(principalID: principal, validateAuthorization: {
            throw BillingAssetError.unauthorized
        })
        await #expect(throws: SaleClosureError.unauthorized) {
            try await CloseSaleUseCase(repository: repository, access: access)(
                SaleClosureTestFixtures.command(document)
            )
        }
        #expect(await repository.commands.isEmpty)
        #expect(await repository.freeSaveCount == 0)
    }

    @Test(
        "revocation while the repository completes suppresses both success and provider details",
        arguments: [false, true]
    )
    func revocationWhileTheRepositoryCompletesSuppressesBothSuccessAndProviderDetails(_ fails: Bool) async throws {
        let document = try billingRenderingDocument()
        let pause = BillingStoragePause()
        let permit = BillingPersistencePermit()
        let repository = try SaleClosureControlledRepository(
            accepted: SaleClosureTestFixtures.closed(document),
            failure: fails ? SaleClosureCommitFailure.detailedFailure : nil,
            pause: pause
        )
        let useCase = CloseSaleUseCase(
            repository: repository,
            access: BillingAssetAccess(principalID: SaleClosureTestFixtures.principalID, validateAuthorization: {
                try await permit.validate()
            })
        )
        let request = try SaleClosureTestFixtures.command(document)
        let task = Task {
            do {
                let accepted = try await useCase(request)
                await pause.complete()
                return accepted
            } catch {
                await pause.complete()
                throw error
            }
        }
        #expect(await pause.waitUntilPausedOrCompleted())
        await permit.revoke()
        await pause.release()
        await #expect(throws: SaleClosureError.unauthorized) {
            try await task.value
        }
        #expect(await repository.commands == [request])
    }

    @Test("provider implementation details are replaced by a neutral local error")
    func providerImplementationDetailsAreReplacedByANeutralLocalError() async throws {
        let document = try billingRenderingDocument()
        let repository = try SaleClosureControlledRepository(
            accepted: SaleClosureTestFixtures.closed(document),
            failure: SaleClosureCommitFailure.detailedFailure
        )
        await #expect(throws: SaleClosureError.persistenceUnavailable) {
            try await CloseSaleUseCase(
                repository: repository,
                access: billingStorageAccess(principalID: SaleClosureTestFixtures.principalID)
            )(SaleClosureTestFixtures.command(document))
        }
        #expect(await repository.commands.count == 1)
    }

    @Test("repository without closure capability fails closed instead of using saveSale")
    func repositoryWithoutClosureCapabilityFailsClosedInsteadOfUsingSaveSale() async throws {
        let document = try billingRenderingDocument()
        let repository = InMemorySaleRepository(sales: [document.request.sale])
        await #expect(throws: SaleClosureError.persistenceUnavailable) {
            try await CloseSaleUseCase(
                repository: repository,
                access: billingStorageAccess(principalID: SaleClosureTestFixtures.principalID)
            )(SaleClosureTestFixtures.command(document))
        }
        #expect(try await repository.sale(id: document.saleID) == document.request.sale)
    }

    @Test("prior cancellation reaches neither closure capability nor unrestricted save")
    func priorCancellationReachesNeitherClosureCapabilityNorUnrestrictedSave() async throws {
        let document = try billingRenderingDocument()
        let repository = try SaleClosureControlledRepository(accepted: SaleClosureTestFixtures.closed(document))
        let useCase = CloseSaleUseCase(
            repository: repository,
            access: billingStorageAccess(principalID: SaleClosureTestFixtures.principalID)
        )
        let request = try SaleClosureTestFixtures.command(document)
        let gate = AsyncStream<Void>.makeStream()
        let task = Task {
            var iterator = gate.stream.makeAsyncIterator()
            _ = await iterator.next()
            return try await useCase(request)
        }
        task.cancel()
        gate.continuation.finish()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(await repository.commands.isEmpty)
        #expect(await repository.freeSaveCount == 0)
    }

    @Test("cancellation after local acceptance suppresses publication but never undoes the durable closure")
    @MainActor
    func cancellationAfterLocalAcceptanceSuppressesPublicationButNeverUndoesTheDurableClosure() async throws {
        let document = try billingRenderingDocument()
        let container = try SaleClosureTestFixtures.container()
        try SaleClosureTestFixtures.seed(document, in: ModelContext(container))
        let pause = BillingStoragePause()
        let accepted = try SaleClosureTestFixtures.closed(document)
        let repository = SaleClosureControlledRepository(
            accepted: accepted,
            pause: pause,
            local: SaleClosureTestFixtures.repository(container)
        )
        let useCase = CloseSaleUseCase(
            repository: repository,
            access: billingStorageAccess(principalID: SaleClosureTestFixtures.principalID)
        )
        let request = try SaleClosureTestFixtures.command(document)
        let task = Task {
            do {
                let value = try await useCase(request)
                await pause.complete()
                return value
            } catch {
                await pause.complete()
                throw error
            }
        }
        #expect(await pause.waitUntilPausedOrCompleted())
        #expect(try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container)) == accepted)
        task.cancel()
        await pause.release()
        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(try SaleLocalDataSource().sale(id: document.saleID, in: ModelContext(container)) == accepted)
        #expect(try SaleLocalDataSource().pendingOperations(in: ModelContext(container)).count == 1)
    }
}
