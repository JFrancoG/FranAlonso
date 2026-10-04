import Foundation

/// The concrete App boundary that selects an unavailable real authority or the isolated Develop demonstration.
enum AppBillingDocumentReservationRepository: BillingDocumentReservationRepository {
    case unavailable
#if FRANALONSO_AUTH_FIXTURE
    case demonstration(DevelopDemoBillingReservationRepository)
#endif

    var isDemonstration: Bool {
        switch self {
        case .unavailable: false
#if FRANALONSO_AUTH_FIXTURE
        case .demonstration: true
#endif
        }
    }

    func reserve(_ request: BillingDocumentRequest) async throws -> BillingDocument {
        switch self {
        case .unavailable:
            try await UnavailableBillingDocumentReservationRepository().reserve(request)
#if FRANALONSO_AUTH_FIXTURE
        case let .demonstration(repository):
            try await repository.reserve(request)
#endif
        }
    }
}
