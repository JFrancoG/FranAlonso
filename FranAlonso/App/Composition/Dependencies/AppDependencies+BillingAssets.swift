import Foundation

extension AppDependencies {
    /// Composes inactive asset adapters; construction neither reads nor imports a private image.
    @MainActor
    static func billingAssets(
        root: AuthenticationRootViewModel,
        bundle: Bundle = .main,
        privateDirectory: URL? = nil
    ) throws -> (
        templates: BundleBillingDocumentTemplateRepository,
        signature: ProtectedLocalBillingSignatureRepository
    ) {
        let access = try root.makeBillingAssetAccess()
        let directory: URL
        if let privateDirectory {
            directory = privateDirectory
        } else {
            directory = try FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: false
            ).appending(path: "BillingPrivateAssets", directoryHint: .isDirectory)
        }
        return (
            BundleBillingDocumentTemplateRepository(bundle: bundle),
            ProtectedLocalBillingSignatureRepository(access: access, directory: directory)
        )
    }
}
