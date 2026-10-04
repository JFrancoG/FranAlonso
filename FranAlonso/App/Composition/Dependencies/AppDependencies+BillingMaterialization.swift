import Foundation

extension AppDependencies {
    /// Composes an inactive durable motor with the caller's one shared persistence owner and captured capability.
    /// Construction performs no reads or writes and grants no live activation, email or sale closure.
    static func materializeBillingDocumentUseCase<Repository: BillingDocumentReservationRepository>(
        persistence: BillingDocumentPersistenceActor,
        access: BillingAssetAccess,
        reserve: ReserveBillingDocumentUseCase<Repository>,
        render: RenderBillingDocumentUseCase,
        upload: UploadBillingDocumentPDFUseCase
    ) -> MaterializeBillingDocumentUseCase<Repository> {
        MaterializeBillingDocumentUseCase(
            local: DefaultBillingDocumentLocalRepository(persistence: persistence, access: access),
            reserve: reserve,
            render: render,
            upload: upload,
            access: access
        )
    }
}
