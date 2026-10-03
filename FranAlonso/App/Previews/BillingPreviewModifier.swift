import SwiftData
import SwiftUI

/// Shares deterministic in-memory persistence while keeping fiscal reservation unavailable.
struct BillingPreviewModifier: PreviewModifier {
    static func makeSharedContext() throws -> AppPreviewModifier.Context {
        try AppPreviewModifier.makeSharedContext()
    }

    func body(content: Content, context: AppPreviewModifier.Context) -> some View {
        content
            .modelContainer(context.modelContainer)
            .environment(\.appDependencies, context.dependencies)
    }
}
