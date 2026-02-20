import Foundation
import SwiftData
import Testing
@testable import AutoQuiz

struct PersistenceMigrationTests {
    @Test
    func modelContainerBootUsesExpectedMigrationPlanAndSchemaVersion() throws {
        ItemMigrationPlan.validateLatestSchemaIsCurrent()

        let currentSchema = Schema(SchemaV2.models, version: SchemaV2.versionIdentifier)
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("AutoQuizMigrationTest.store")

        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        defer {
            try? FileManager.default.removeItem(at: storeDirectory)
        }

        let configuration = ModelConfiguration(nil, schema: currentSchema, url: storeURL)
        let container = try ModelContainer(
            for: currentSchema,
            migrationPlan: ItemMigrationPlan.self,
            configurations: configuration
        )

        guard let migrationPlan = container.migrationPlan else {
            Issue.record("ModelContainer did not attach a migration plan.")
            return
        }

        #expect(ObjectIdentifier(migrationPlan) == ObjectIdentifier(ItemMigrationPlan.self))
        #expect(container.schema.version == SchemaV2.versionIdentifier)
    }
}
