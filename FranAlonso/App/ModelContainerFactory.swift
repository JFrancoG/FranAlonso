import SwiftData

extension ModelContainer {
    /// Creates the disk-backed application container for an explicit schema.
    static func production(
        for schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil
    ) throws -> ModelContainer {
        try configured(
            for: schema,
            migrationPlan: migrationPlan,
            configurationName: "FranAlonso",
            isStoredInMemoryOnly: false
        )
    }

    /// Creates an isolated in-memory container for tests and previews.
    static func inMemory(
        for schema: Schema,
        migrationPlan: (any SchemaMigrationPlan.Type)? = nil
    ) throws -> ModelContainer {
        try configured(
            for: schema,
            migrationPlan: migrationPlan,
            configurationName: "FranAlonsoInMemory",
            isStoredInMemoryOnly: true
        )
    }

    private static func configured(
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
