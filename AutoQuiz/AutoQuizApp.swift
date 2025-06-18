//
//  AutoQuizApp.swift
//  AutoQuiz
//
//  Created by Rafael Francisco on 10/06/2025.
//

import SwiftUI
import SwiftData

@main
struct AutoQuizApp: App {
    private var migrationModelContainer: ModelContainer = {
        do {
            return try ModelContainer(for: Item.self, migrationPlan: ItemMigrationPlan.self)
        } catch {
            fatalError("Could not create ModelContainer with migration: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(migrationModelContainer)
    }
}
