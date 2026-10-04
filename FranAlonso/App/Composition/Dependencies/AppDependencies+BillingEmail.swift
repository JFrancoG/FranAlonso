import Foundation
import UIKit

extension AppDependencies {
    /// Composes an inactive reader from the caller's shared persistence owner and revocable capability.
    /// Construction performs no document writes, numbering, uploading or journey activation.
    static func prepareBillingEmailDraftUseCase(
        persistence: BillingDocumentPersistenceActor,
        access: BillingAssetAccess,
        bundle: Bundle,
        locale: Locale
    ) -> PrepareBillingEmailDraftUseCase {
        PrepareBillingEmailDraftUseCase(
            local: DefaultBillingDocumentLocalRepository(persistence: persistence, access: access),
            content: LocalizedBillingEmailContentBuilder(bundle: bundle, locale: locale),
            access: access
        )
    }

    /// Creates an inactive manual Mail adapter. The caller supplies an attached presentation owner.
    /// No native controller is created until authorized composition is requested and Mail is available.
    @MainActor
    static func billingEmailComposer(
        access: BillingAssetAccess,
        presenter: UIViewController
    ) -> AppleBillingEmailComposer {
        AppleBillingEmailComposer(driver: MessageUIMailCompositionDriver(presenter: presenter), access: access)
    }
}
