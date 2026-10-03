extension AppDependencies {
    /// Creates an inactive PDF motor; no assets, identities or live services are accessed.
    static func billingPDFRenderer() -> CoreGraphicsBillingPDFRenderer {
        CoreGraphicsBillingPDFRenderer()
    }
}
