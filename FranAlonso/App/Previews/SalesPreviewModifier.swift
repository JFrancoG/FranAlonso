import SwiftData
import SwiftUI

/// Reuses the shared preview container and adds only isolated operational fixtures.
struct SalesPreviewModifier: PreviewModifier {
    struct Context {
        let base: AppPreviewModifier.Context
        let detailModels: [SaleID: SaleDraftViewModel]
    }

    static func makeSharedContext() async throws -> Context {
        let context = try AppPreviewModifier.makeSharedContext()
        try SalesPreviewFixtures.seedPreviewClients(in: context.modelContainer.mainContext)
        try SalesPreviewFixtures.workday.seed(in: context.modelContainer.mainContext)
        var detailModels: [SaleID: SaleDraftViewModel] = [:]
        for (index, sale) in SalesPreviewFixtures.workday.sales.enumerated() {
            let destination = SalesPreviewFixtures.destination(
                index: index,
                mode: sale.status == .draft ? .editDraft : .inspect
            )
            let model = context.dependencies.makeSaleDraft(destination)
            _ = try await model.load()
            await model.resolveClientName()
            detailModels[sale.id] = model
        }
        return Context(base: context, detailModels: detailModels)
    }

    func body(content: Content, context: Context) -> some View {
        content
            .modelContainer(context.base.modelContainer)
            .environment(\.appDependencies, context.base.dependencies)
            .environment(\.salesPreviewModels, context.detailModels)
    }
}

extension EnvironmentValues {
    @Entry var salesPreviewModels: [SaleID: SaleDraftViewModel] = [:]
}
