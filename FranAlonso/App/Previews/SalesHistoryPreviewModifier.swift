import SwiftData
import SwiftUI

/// Adds explicit materialized history samples to the shared isolated preview environment.
struct SalesHistoryPreviewModifier: PreviewModifier {
    static func makeSharedContext() async throws -> AppPreviewModifier.Context {
        let context = try AppPreviewModifier.makeSharedContext()
        try SalesPreviewFixtures.seedPreviewClients(in: context.modelContainer.mainContext)
        try SalesPreviewFixtures.history.seed(in: context.modelContainer.mainContext)
        return context
    }

    func body(content: Content, context: AppPreviewModifier.Context) -> some View {
        content
            .modelContainer(context.modelContainer)
            .environment(\.appDependencies, context.dependencies)
    }
}
