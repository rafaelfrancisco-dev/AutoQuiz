//
//  AutoQuizApp.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import SwiftData
import OSLog

@main
struct AutoQuizApp: App {
    private var migrationModelContainer: ModelContainer = {
        do {
            ItemMigrationPlan.validateLatestSchemaIsCurrent()

            let currentSchema = Schema(SchemaV4.models, version: SchemaV4.versionIdentifier)
            let configuration = try makeModelConfiguration(for: currentSchema)
            return try ModelContainer(
                for: currentSchema,
                migrationPlan: ItemMigrationPlan.self,
                configurations: configuration
            )
        } catch {
            Logger.database.fault("Could not create ModelContainer: \(error.localizedDescription)")
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(migrationModelContainer)
    }

    private static func makeModelConfiguration(for schema: Schema) throws -> ModelConfiguration {
        guard ProcessInfo.processInfo.environment["XCTestConfigurationFilePath"] != nil else {
            return ModelConfiguration(isStoredInMemoryOnly: false)
        }

        // Use a per-run temporary store path to avoid sandbox write restrictions and
        // stale store metadata from previous test runs.
        let storeDirectory = FileManager.default.temporaryDirectory
            .appendingPathComponent("AutoQuizTests-\(UUID().uuidString)", isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("AutoQuizTests.store")

        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        Logger.database.notice("Using test-host SwiftData store at \(storeURL.path, privacy: .public)")

        return ModelConfiguration("AutoQuizTests", schema: schema, url: storeURL)
    }
}
