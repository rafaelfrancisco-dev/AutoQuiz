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
            // For now, create a fresh container without migration to avoid conflicts
            let configuration = ModelConfiguration(isStoredInMemoryOnly: false)
            return try ModelContainer(for: Item.self, AnsweredQuestion.self, QuizSession.self, configurations: configuration)
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
        .modelContainer(migrationModelContainer)
    }
}
