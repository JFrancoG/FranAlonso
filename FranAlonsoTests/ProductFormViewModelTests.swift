import Foundation
import SwiftData
import Testing
@testable import FranAlonso

@Suite("Product form state and local intentions")
@MainActor
struct ProductFormViewModelTests {
    @Test
    func `creation validates before writing and retries with the same identity`() async throws {
        let fixture = try ProductFormFixture(mode: .create)
        let model = fixture.model
        model.name = " \n "
        await model.save(in: fixture.context)
        #expect(model.state == .failed(.save, .invalidName))
        #expect(fixture.writes.profiles.isEmpty)

        model.name = "  Accepted product  "
        #expect(model.state == .editing)
        fixture.writes.failure = ProductError.conflict
        await model.save(in: fixture.context)
        #expect(model.state == .failed(.save, .conflict))
        #expect(model.name == "  Accepted product  ")

        fixture.writes.failure = nil
        await model.save(in: fixture.context)
        let expected = Product(id: model.destination.productID, name: "Accepted product", status: .active)
        #expect(model.state == .saved(expected))
        #expect(model.loadedProduct == expected)
        #expect(fixture.writes.identities == [expected.id, expected.id])
        #expect(fixture.writes.profiles.map(\.name) == ["Accepted product", "Accepted product"])
        await model.save(in: fixture.context)
        #expect(fixture.writes.identities.count == 2)
    }

    @Test
    func `missing edits cannot write a blank form and a later retry can load`() async throws {
        let fixture = try ProductFormFixture(mode: .edit)
        await fixture.model.load()
        #expect(fixture.model.state == .failed(.load, .notFound))
        #expect(!fixture.model.canEdit)
        fixture.model.name = "Must not create"
        await fixture.model.save(in: fixture.context)
        await fixture.model.deactivate(in: fixture.context)
        #expect(fixture.writes.identities.isEmpty)
        #expect(fixture.writes.deactivatedIDs.isEmpty)

        let product = Product(id: fixture.model.destination.productID, name: "Recovered", status: .inactive)
        await fixture.repository.set(product)
        await fixture.model.load()
        #expect(fixture.model.state == .editing)
        #expect(fixture.model.name == "Recovered")
        #expect(!fixture.model.canDeactivate)
        fixture.model.name = "Draft remains"
        await fixture.model.load()
        #expect(fixture.model.name == "Draft remains")
    }

    @Test
    func `read failures stay noneditable and unknown mutation failures are neutral`() async throws {
        let fixture = try ProductFormFixture(mode: .edit)
        await fixture.repository.setFailure(ProductFormFailure.expected)
        await fixture.model.load()
        #expect(fixture.model.state == .failed(.load, .persistenceUnavailable))
        #expect(!fixture.model.canEdit)
        await fixture.repository.setFailure(nil)
        await fixture.repository.set(Product(id: fixture.model.destination.productID, name: "Before", status: .active))
        await fixture.model.load()
        fixture.model.name = "Changed"
        fixture.writes.failure = ProductFormFailure.expected
        await fixture.model.save(in: fixture.context)
        #expect(fixture.model.state == .failed(.save, .persistenceUnavailable))
        #expect(fixture.model.name == "Changed")
        #expect(fixture.model.canEdit)
    }

    @Test
    func `deactivation is contextual and repeated actions after success are ignored`() async throws {
        let fixture = try ProductFormFixture(mode: .edit)
        let id = fixture.model.destination.productID
        await fixture.repository.set(Product(id: id, name: "Active", status: .active))
        await fixture.model.load()
        #expect(fixture.model.canDeactivate)
        fixture.writes.failure = ProductError.conflict
        await fixture.model.deactivate(in: fixture.context)
        #expect(fixture.model.state == .failed(.deactivate, .conflict))
        fixture.writes.failure = nil
        await fixture.model.deactivate(in: fixture.context)
        #expect(fixture.model.state == .deactivated)
        await fixture.model.deactivate(in: fixture.context)
        await fixture.model.save(in: fixture.context)
        #expect(fixture.writes.deactivatedIDs == [id, id])
        #expect(fixture.writes.identities.isEmpty)
    }

    @Test
    func `a suspended save captures its name and excludes overlapping actions`() async throws {
        let fixture = try ProductFormFixture(mode: .edit)
        let id = fixture.model.destination.productID
        await fixture.repository.set(Product(id: id, name: "Before", status: .active))
        await fixture.model.load()
        let gate = ProductFormGate()
        fixture.writes.gate = gate
        fixture.model.name = "  Submitted  "
        let saving = Task {
            await fixture.model.save(in: fixture.context)
        }
        await gate.waitUntilBlocked()
        #expect(fixture.model.state == .saving)
        fixture.model.name = "Later text"
        await fixture.model.save(in: fixture.context)
        await fixture.model.deactivate(in: fixture.context)
        gate.release()
        await saving.value

        #expect(fixture.writes.profiles.map(\.name) == ["Submitted"])
        #expect(fixture.writes.deactivatedIDs.isEmpty)
        #expect(fixture.model.state == .saved(Product(id: id, name: "Submitted", status: .active)))
        #expect(fixture.model.loadedProduct?.name == "Submitted")
    }

    @Test
    func `cancellation before submission neither saves nor deactivates`() async throws {
        let fixture = try ProductFormFixture(mode: .edit)
        await fixture.repository.set(Product(id: fixture.model.destination.productID, name: "Before", status: .active))
        await fixture.model.load()
        let submitting = Task {
            await fixture.model.save(in: fixture.context)
            await fixture.model.deactivate(in: fixture.context)
        }
        submitting.cancel()
        await submitting.value

        #expect(fixture.writes.identities.isEmpty)
        #expect(fixture.writes.deactivatedIDs.isEmpty)
        #expect(fixture.model.state == .editing)
    }

    @Test(arguments: [WriteInterruption.cancelled, .cooperative, .closed], [false, true])
    func `write interruption preserves accepted outcomes and closed sessions`(
        interruption: WriteInterruption,
        deactivating: Bool
    ) async throws {
        let fixture = try ProductFormFixture(mode: .edit)
        let id = fixture.model.destination.productID
        await fixture.repository.set(Product(id: id, name: "Accepted", status: .active))
        await fixture.model.load()
        let gate = ProductFormGate()
        fixture.writes.gate = gate
        let writing = Task {
            if deactivating {
                await fixture.model.deactivate(in: fixture.context)
            } else {
                await fixture.model.save(in: fixture.context)
            }
        }
        await gate.waitUntilBlocked()
        if interruption == .closed {
            fixture.model.close()
        } else {
            writing.cancel()
            if interruption == .cooperative {
                fixture.writes.failure = CancellationError()
            }
        }
        gate.release()
        await writing.value

        switch interruption {
        case .cancelled:
            let accepted = Product(id: id, name: "Accepted", status: .active)
            #expect(fixture.model.state == (deactivating ? .deactivated : .saved(accepted)))
        case .cooperative:
            #expect(fixture.model.state == .editing)
            #expect(fixture.model.name == "Accepted")
        case .closed:
            #expect(fixture.model.state == .closed)
            #expect(fixture.model.name.isEmpty)
            #expect(fixture.model.loadedProduct == nil)
            await fixture.model.load()
            await fixture.model.save(in: fixture.context)
            #expect(fixture.model.state == .closed)
        }
        #expect(fixture.writes.identities.count + fixture.writes.deactivatedIDs.count == 1)
    }

    @Test(arguments: [ReadInterruption.replaced, .cancelled, .closed])
    func `late reads cannot overwrite a newer load or revive a closed form`(
        interruption: ReadInterruption
    ) async throws {
        let fixture = try ProductFormFixture(mode: .edit)
        let id = fixture.model.destination.productID
        let old = Product(id: id, name: "Old snapshot", status: .active)
        let current = Product(id: id, name: "Current snapshot", status: .inactive)
        await fixture.repository.set(old)
        let gate = ProductFormGate()
        await fixture.repository.holdNextRead(gate)
        let loading = Task {
            await fixture.model.load()
        }
        await gate.waitUntilBlocked()
        #expect(fixture.model.state == .loading)
        switch interruption {
        case .replaced:
            await fixture.repository.set(current)
            await fixture.model.load()
        case .cancelled:
            loading.cancel()
        case .closed:
            fixture.model.close()
        }
        gate.release()
        await loading.value

        switch interruption {
        case .replaced:
            #expect(fixture.model.state == .editing)
            #expect(fixture.model.loadedProduct == current)
            #expect(fixture.model.name == "Current snapshot")
        case .cancelled:
            #expect(fixture.model.state == .idle)
            #expect(fixture.model.loadedProduct == nil)
        case .closed:
            #expect(fixture.model.state == .closed)
            #expect(fixture.model.name.isEmpty)
            #expect(fixture.model.loadedProduct == nil)
        }
    }
}

enum WriteInterruption {
    case cancelled
    case cooperative
    case closed
}

enum ReadInterruption {
    case replaced
    case cancelled
    case closed
}

private enum ProductFormFailure: Error {
    case expected
}

@MainActor
private struct ProductFormFixture {
    let container: ModelContainer
    let repository: ProductFormReadRepository
    let writes: ProductFormWrites
    let model: ProductFormViewModel

    var context: ModelContext { container.mainContext }
}

private extension ProductFormFixture {
    init(mode: ProductFormDestination.Mode) throws {
        let container = try ModelContainer.inMemory(for: .franAlonso)
        let repository = ProductFormReadRepository()
        let writes = ProductFormWrites()
        let destination = ProductFormDestination(id: UUID(), productID: ProductID(rawValue: UUID()), mode: mode)
        self.init(
            container: container,
            repository: repository,
            writes: writes,
            model: ProductFormViewModel(
                destination: destination,
                getProduct: GetProductUseCase(repository: repository),
                create: { id, profile, context in
                    try await writes.save(id, profile: profile, in: context)
                },
                update: { id, profile, context in
                    try await writes.save(id, profile: profile, in: context)
                },
                deactivate: { id, context in
                    try await writes.deactivate(id, in: context)
                }
            )
        )
    }
}

@MainActor
private final class ProductFormWrites {
    var failure: (any Error)?
    var status: ProductStatus = .active
    var gate: ProductFormGate?
    private(set) var identities: [ProductID] = []
    private(set) var profiles: [ProductProfile] = []
    private(set) var deactivatedIDs: [ProductID] = []

    func save(_ id: ProductID, profile: ProductProfile, in context: ModelContext) async throws -> Product {
        identities.append(id)
        profiles.append(profile)
        await gate?.block()
        if let failure {
            throw failure
        }
        return Product(id: id, name: profile.name, status: status)
    }

    func deactivate(_ id: ProductID, in context: ModelContext) async throws {
        deactivatedIDs.append(id)
        await gate?.block()
        if let failure {
            throw failure
        }
    }
}

private actor ProductFormReadRepository: ProductRepository {
    private var stored: Product?
    private var failure: (any Error)?
    private var gate: ProductFormGate?

    func set(_ product: Product) {
        stored = product
    }

    func setFailure(_ error: (any Error)?) {
        failure = error
    }

    func holdNextRead(_ gate: ProductFormGate) {
        self.gate = gate
    }

    func product(id: ProductID) async throws -> Product? {
        let snapshot = stored
        let gate = gate
        self.gate = nil
        await gate?.block()
        if let failure {
            throw failure
        }
        return snapshot
    }

    func observeProducts() async -> AsyncThrowingStream<[Product], any Error> {
        AsyncThrowingStream {
            $0.finish()
        }
    }

    func saveProduct(_ product: Product) async throws {
        throw ProductError.persistenceUnavailable
    }

    func createProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        throw ProductError.persistenceUnavailable
    }

    func updateProduct(id: ProductID, profile: ProductProfile) async throws -> Product {
        throw ProductError.persistenceUnavailable
    }

    func deactivateProduct(_ id: ProductID) async throws {
        throw ProductError.persistenceUnavailable
    }
}

@MainActor
private final class ProductFormGate {
    private var blocked = false
    private var waiting: CheckedContinuation<Void, Never>?
    private var releaseContinuation: CheckedContinuation<Void, Never>?

    func block() async {
        blocked = true
        waiting?.resume()
        waiting = nil
        await withCheckedContinuation {
            releaseContinuation = $0
        }
    }

    func waitUntilBlocked() async {
        guard !blocked else { return }
        await withCheckedContinuation {
            waiting = $0
        }
    }

    func release() {
        releaseContinuation?.resume()
        releaseContinuation = nil
    }
}
