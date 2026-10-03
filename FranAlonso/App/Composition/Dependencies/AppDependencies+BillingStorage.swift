extension AppDependencies {
    /// Creates an inactive upload operation; construction starts no reads, uploads or live services.
    static func uploadBillingDocumentPDFUseCase(
        repository: any BillingDocumentPDFStorageRepository = UnavailableBillingDocumentPDFStorageRepository()
    ) -> UploadBillingDocumentPDFUseCase {
        UploadBillingDocumentPDFUseCase(repository: repository)
    }
}
