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

            let currentSchema = Schema(SchemaV2.models, version: SchemaV2.versionIdentifier)
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

        let environment = ProcessInfo.processInfo.environment
        let fallbackProjectPath = URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .path

        let projectPath = environment["PROJECT_DIR"]
            ?? environment["SOURCE_ROOT"]
            ?? environment["SRCROOT"]
            ?? fallbackProjectPath

        let projectURL = URL(fileURLWithPath: projectPath, isDirectory: true)
        let storeDirectory = projectURL.appendingPathComponent(".swiftdata", isDirectory: true)
        let storeURL = storeDirectory.appendingPathComponent("AutoQuizTests.store")

        try FileManager.default.createDirectory(at: storeDirectory, withIntermediateDirectories: true)
        Logger.database.notice("Using test-host SwiftData store at \(storeURL.path, privacy: .public)")

        return ModelConfiguration("AutoQuizTests", schema: schema, url: storeURL)
    }
}
