import SwiftData
import SwiftUI

/// Installs deterministic in-memory persistence and non-live dependencies for previews.
struct AppPreviewModifier: PreviewModifier {
    struct Context {
        let modelContainer: ModelContainer
        let dependencies: AppDependencies
    }

    static func makeSharedContext() throws -> Context {
        let modelContainer = try ModelContainer.inMemory(
            for: Schema.franAlonso
        )
        try AppPreviewFixtures.standard.seed(in: modelContainer.mainContext)

        return Context(
            modelContainer: modelContainer,
            dependencies: .preview(clients: AppPreviewFixtures.standard.clients)
        )
    }

    func body(content: Content, context: Context) -> some View {
        content
            .modelContainer(context.modelContainer)
            .environment(\.appDependencies, context.dependencies)
    }
}
