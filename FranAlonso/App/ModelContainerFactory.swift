import SwiftData

enum ModelContainerFactory {
    static func makeProduction(
        for schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil
    ) throws -> ModelContainer {
        try make(
            for: schema,
            migrationPlan: migrationPlan,
            configurationName: "FranAlonso",
            isStoredInMemoryOnly: false
        )
    }

    static func makeInMemory(
        for schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil
    ) throws -> ModelContainer {
        try make(
            for: schema,
            migrationPlan: migrationPlan,
            configurationName: "FranAlonsoInMemory",
            isStoredInMemoryOnly: true
        )
    }

    private static func make(
        for schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)?,
        configurationName: String,
        isStoredInMemoryOnly: Bool
    ) throws -> ModelContainer {
        let configuration = ModelConfiguration(
            configurationName,
            schema: schema,
            isStoredInMemoryOnly: isStoredInMemoryOnly,
            allowsSave: true,
            groupContainer: .none,
            cloudKitDatabase: .none
        )

        return try ModelContainer(
            for: schema,
            migrationPlan: migrationPlan,
            configurations: [configuration]
        )
    }
}
